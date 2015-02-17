angular.module('openCall.services').factory 'UsersService', 
['$q', '$http', ($q, $http) ->

  user_sessions = (id) ->
    deferred = $q.defer()

    $http.get("/users/session_proposals")
    .success((data, status) ->
      deferred.resolve data.sessions
    ).error (data, status) ->
      deferred.reject()

    deferred.promise

  user_reviews = (id) ->
    deferred = $q.defer()

    $http.get("/users/reviews")
    .success((data, status) ->
      deferred.resolve data.reviews
    ).error (data, status, header, config) ->
      switch status
        when 403 then message = "access_denied"
        else message = "generic"

      deferred.reject message

    deferred.promise

  user_sessions: user_sessions
  user_reviews: user_reviews
]