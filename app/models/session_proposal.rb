require 'elasticsearch/model'

class SessionProposal < ActiveRecord::Base
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks
  include Workflow
  index_name [self.base_class.to_s.pluralize.underscore, Rails.env].join('_')

  belongs_to :user
  has_many :comments
  has_and_belongs_to_many :tags, autosave: true
  accepts_nested_attributes_for :tags, allow_destroy: true
  belongs_to :track
  belongs_to :audience
  belongs_to :theme
  has_many :reviews

  validates :title, :summary, :description, :user_id, :track_id, :audience_id, :video_link, presence: true

  workflow do
    state :new do
      event :accept, :transitions_to => :accepted
      event :decline, :transitions_to => :declined
    end
    state :accepted
    state :declined
  end

  def autosave_associated_records_for_tags
    session_tags = []
    self.tags.each { |tag| session_tags << Tag.find_or_create_by(name: tag.name) unless tag.marked_for_destruction? }
    self.tags = session_tags
  end

  def as_indexed_json options={}
    JSON.parse(Jbuilder.encode do |json|
      json.id           self.id
      json.title        self.title
      json.theme        self.theme.name
      json.track        self.track.name
      json.summary      self.summary
      json.author       self.user.full_name
      json.tags         self.tags.map(&:name)
    end)
  end

  def self.custom_search terms='', page_number=1
    query = terms.blank? ? self.match_all_query : self.aggregated_query(terms)
    search(query).page(page_number)
  end

  def self.aggregated_query terms
    Jbuilder.encode do |json|
      json.query do
        json.multi_match do
          json.fields ["tags^10", "theme^10", "track^10", "title^5", "summary", "author"]
          json.query terms
        end
      end
      json.highlight do
        json.fields do
          json.title "{}"
          json.summary "{}"
        end
      end
      json.aggregations do
        json.matched_tags do
          json.terms do
            json.field "tags"
          end
        end
      end
    end
  end

  def self.match_all_query
    Jbuilder.encode do |json|
      json.query do
        json.match_all Hash.new
      end
    end
  end

  after_commit on: [:update] do
    __elasticsearch__.index_document
  end

  def reviewer_comments
    comments.where(user_id: Role.admins_and_reviewers.map(&:id))
  end

  private
  def accept
    self.notified_on = DateTime.now
    save!
  end  
  def decline
    self.notified_on = DateTime.now
    save!
  end  
end
