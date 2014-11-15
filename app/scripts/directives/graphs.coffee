'use strict'

angular.module 'hcApp'
.directive 'hcSimpleGraph', ->
  ####
  restrict: "E"
  scope:
    rst: "=hcRst" #= [{year: year, temp: temperature_degC}, ... ]
    title: "=hcTitle "#= descriptive text (e.g. 'jan 01').
    highDetail: "=hcHighDetail" #boolean
    hover: "=hcHover"
  ###
  restrict: "E"
  template: "<div class='simple-graph' ng-mouseenter='hover=true' ng-mouseleave='hover=false' ng-class='{hover: hover}'></div>"
  replace: true
  scope:
    rst: "=hcRst" #= [{year: year, temp: temperature_degC}, ... ]
    title: "=hcTitle "#= descriptive text (e.g. 'jan 01').
    highDetail: "=hcHighDetail" #boolean
  ###
  link: (scope, el, attrs) ->

    #Initialisation and helper functions
    #===================================
    el = el[0]
    rst = undefined
    rstRecords = undefined #rstRecords[0] = array with 10 coldest years (0 being coldest), rstRecords[1] = array with 10 hottest years (0 being hottest)
    size = [el.clientWidth, el.clientHeight]
    margin = top: 15, right: 20, bottom: 30, left: 90
    graphSize = [
      () -> size[0] - margin.left - margin.right
      () -> size[1] - margin.top - margin.bottom
    ]
    svg = d3.select(el).append("svg")
    titleText = svg.append("g").attr("class", "title").attr("transform", "translate(0, 15)").append("text")
    graph = svg.append("g").attr("transform", "translate(" + margin.left + "," + margin.top + ")")
    yAxisEl = graph.append("g").attr("class", "y axis")
    yAxisEl.append("title").text "average daily temperature [°C]"
    circles = graph.append("g").attr("id", "recordCircles").selectAll(".recordCircle")
    tempLine = graph.append("path").attr("id", "tempLine")
    diffLine = graph.append("path").attr("id", "diffLine")
    xAxisEl = graph.append("g").attr("class", "x axis")
    x = d3.scale.linear().rangeRound([0, graphSize[0]()]).nice()
    xAxis = d3.svg.axis().scale(x).orient("bottom").tickSize(6, 0).tickFormat(d3.format("0000"))
    y = d3.scale.linear().rangeRound([graphSize[1](), 0]).nice()
    yAxis = d3.svg.axis().scale(y).orient("left").ticks(5)
    lineFunc = d3.svg.line()
    .x (p) -> x p.year
    .y (p) -> y p.temp
    .interpolate "linear"
    transition =
      duration: 300
      ease: "cubic-in-out"#"cubic-in-out" or "elastic" or something like d3.ease("elastic", valA, valP)
    diffLineRst = () -> [
      $.extend {}, rstRecords[0][0], temp: y.domain()[0]
      $.extend {}, rstRecords[1][0], temp: y.domain()[0]
    ]
    sortByTempThenYear = (tempDir) -> #'des', 'desc', or 'Descending', etc. to sort by descending temp. Ascending otherwise.
      (r1, r2) ->
        d = r1.temp - r2.temp
        d = -d if /^des/i.test(tempDir) #descending
        if d isnt 0 then d else r1.year - r2.year
    tooltipText = (d) ->
      switch d.nth
        when 1 then th = ""
        when 2 then th = "second "
        when 3 then th = "3rd "
        else th = d.nth + "th "
      d.year + ": " + d3.format(".3r")(d.temp) + "°C -- " + th + coldhottest(d.coldhot) + " year on record for " + scope.title + "."
    coldhot = (isHot) -> if isHot then "hot" else "cold"
    coldhotter = (coldhot) -> if coldhot is "hot" then "hotter" else "colder"
    coldhottest = (coldhot) -> if coldhot is "hot" then "hottest" else "coldest"

    #Redraw
    #======
    redraw = () ->
      return unless rst
      yAxisEl.transition().duration(transition.duration).ease(transition.ease)
      .call yAxis
      xAxisEl.transition().duration(transition.duration).ease(transition.ease)
      .attr "transform", "translate(0," + graphSize[1]() + ")"
      .call xAxis
      tempLine.transition().duration(transition.duration).ease(transition.ease)
      .attr "d", lineFunc(rst)
      diffLine.transition().duration(transition.duration).ease(transition.ease)
      .attr "d", lineFunc(diffLineRst())
      #no circles.exit() as no circles are ever removed
      circles.transition().duration(transition.duration).ease(transition.ease)
      .attr "cx", (d) -> x d.year
      .attr "cy", (d) -> y d.temp
      .attr "r", (d) -> 11 - d.nth

    #Resize
    #======
    updateSizeAndRedraw = () ->
      #Change size.
      size = [el.clientWidth, el.clientHeight]
      if size[1] < 70
        margin.top = margin.bottom = size[1] / 2
      else
        margin.top = 25
        margin.bottom = 40
      #Show certain elements based on height of graph.
      display = if el.clientHeight > 70 then null else "none"
      [xAxisEl, yAxisEl].forEach (e) -> e.attr "display", display
      #Change elements.
      x.rangeRound [0, graphSize[0]()]
      y.rangeRound [graphSize[1](), 0]
      yAxis.tickSize -graphSize[0](), 0
      svg.transition().duration(transition.duration).ease(transition.ease)
      .attr "width", size[0]
      .attr "height", size[1]
      graph.transition().duration(transition.duration).ease(transition.ease)
      .attr "width", graphSize[0]()
      .attr "height", graphSize[1]()
      .attr "transform", "translate(" + margin.left + "," + margin.top + ")"
      redraw()

    #Update recordset
    #================
    processRstAndRedraw = (newRst) ->
      rst = newRst
      #Sort by ascending temperature, get 10 lowest/highest, add properties.
      rst.sort sortByTempThenYear "asc"
      rstRecords = [rst.slice(0, 10), rst.slice(-10).sort sortByTempThenYear "desc"]
      rstRecords.forEach (rstRecord, i) ->
        rstRecord.forEach (record, j) ->
          record.coldhot = coldhot(i)
          record.nth = j + 1
      #Sort by ascending year.
      rst.sort (r1, r2) -> r1.year - r2.year
      xDomain = [rst[0].year, rst[rst.length - 1].year]
      yDomain = [rstRecords[0][0].temp, rstRecords[1][0].temp]
      diffLine.attr "class", coldhot(rstRecords[0][0].year < rstRecords[1][0].year)
      circles = graph.select("#recordCircles").selectAll(".recordCircle")
      .data [].concat(rstRecords[0], rstRecords[1]), (d) -> d.coldhot + d.nth
      #Starting positions.
      circles.enter().append "circle"
        .attr "class", (d) -> d.coldhot + " " + d.nth + "th recordCircle"
        .attr "cx", (d) -> x d.year
        .attr "cy", (d) -> y d.temp
        .attr "r", 0
        .style "opacity", 1
      .append "svg:title"
        .attr "class", "tooltip"
      circles.selectAll ".tooltip"
      .text tooltipText
      x.domain xDomain
      y.domain yDomain
      redraw()

    #Watches
    #=======
    #Changing size (a).
    scope.$watch () ->
      el.clientWidth + el.clientHeight
    , updateSizeAndRedraw
    #Changing size (b).
    scope.$watch "hover", updateSizeAndRedraw
    #Changing title.
    scope.$watch "title", (title) ->
      return unless title
      titleText.text title
    #Changing recordset.
    scope.$watchCollection "rst", (newRst) ->
      return unless newRst
      processRstAndRedraw newRst
    #Level of detail.
    scope.$watch "highDetail", (highDetail) ->
      graph.select("#recordCircles").attr "display", () -> if (highDetail) then null else "none"
      graph.select("#diffLine").attr "display", () -> if (highDetail) then "none" else null

    return
