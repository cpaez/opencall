angular.module('openCall.controllers').controller 'SessionsController', 
['$scope', '$location', 'SessionsService', ($scope, $location, SessionsService) ->

  $scope.sessions = []
  $scope.matched_tags = []
  $scope.newSession = 
    title: ''
    description: ''
  $scope.availableVotes = 10
  $scope.searchTerms = ''

  $scope.init = () ->
    SessionsService.all().then (response) ->
      $scope.sessions = response.sessions

  $scope.createSession = () ->
    SessionsService.create($scope.newSession).then () ->
      $location.path '/sessions'

  $scope.search = (termToAdd) ->
    $scope.searchTerms = "#{$scope.searchTerms} #{termToAdd}"  if angular.isDefined(termToAdd)
    SessionsService.search($scope.searchTerms).then (response) ->
      $scope.sessions = response.sessions
      $scope.matched_tags = response.matched_tags

  $scope.vote = (index) ->
    $scope.sessions[index].voted = false  if angular.isUndefined($scope.sessions[index].voted)
    $scope.sessions[index].voted = !$scope.sessions[index].voted
    $scope.availableVotes = if $scope.sessions[index].voted then $scope.availableVotes - 1 else $scope.availableVotes + 1

  $scope.fav = (index) ->
    $scope.sessions[index].faved = false  if angular.isUndefined($scope.sessions[index].faved)
    $scope.sessions[index].faved = !$scope.sessions[index].faved
]