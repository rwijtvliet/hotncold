'use strict'

angular.module 'hcApp'
.controller 'MainCtrl', ($scope, Measurements) ->

  #Initialisation and helper functions
  #===================================
  month = (m) -> ["Jan", "Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"][m - 1]
  $scope.title = (m, d) -> if d then month(m) + " " + d else month(m)


  #Options
  #=======
  $scope.options =
    locations: [
      {id: 0, name: "Hamburg Fuhlsbuettel", descr: "Measurement station at Hamburg Airport", url: "data/hamburgFuhlsbuettel.csv", source: "Deutscher Wetterdienst", sourceUrl: "http://dwd.de/"}
      {id: 1, name: "Berlin", descr: "Capital of Germany"}
    ]
    curveCounts: [
      {id: 0, name: "one per day", descr: "366: a curve for each day", dataQ: Measurements.byMonthAndDayQ}
      {id: 1, name: "one per month", descr: "12: a curve for each month", dataQ: Measurements.byMonthQ}
    ]
    details: [
      {id: 0, name: "low", descr: "low: only show how much more recent the hottest year was, compared to the coldest (or vice versa)"}
      {id: 1, name: "high", descr: "high(er): show top 10 hottest and top 10 coldest years"}
    ]

  #Settings (what's picked from the options)
  #========
  $scope.settings =
    location: $scope.options.locations[0]
    curveCount: $scope.options.curveCounts[0]
    detail: $scope.options.details[0]
    allInOne: false
    curves: []

  #Deal with change
  #================
  redoAll = () ->
    $scope.settings.curveCount.dataQ $scope.settings.location.url
    .then (curves) ->
      curves.forEach (curve) -> curve.title = $scope.title curve.month, curve.day
      $scope.settings.curves = curves
  $scope.change =
    location: redoAll
    curveCount: redoAll
    allInOne: redoAll
    detail: redoAll
