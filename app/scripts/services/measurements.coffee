'use strict'
###
M
.rstQ = promise to array of measurement objects (as found in csv, with all properties attached)
.byMondAndDayQ = promise to array of {month, day, rst: [{year, temp}, ... ]} objects
.byMonthQ = promise to array of {month, rst: [{year, temp}, ... ]} objects
###


angular.module 'hcApp'
.service 'Measurements', ($q) ->
  M = {}
  db = []

  getTbl = (url) ->
    throw Error "no path defined" unless url
    tbl = undefined
    filtered = db.filter (tbl) -> tbl.url is url
    if filtered.length
      tbl = filtered[0]
    else
      tbl = url: url
      db.push tbl
    tbl

  M.rstQ = (url) ->
    tbl = getTbl url
    return tbl.rstQ  if tbl.hasOwnProperty "rstQ"
    def = $q.defer()
    d3.csv url, (error, rstAll) ->
      return def.reject(error) if error
      rstAll.forEach (r) ->
        r.year = +r.year
        r.month = +r.month
        r.day = +r.day
        r.temp = +r.temp
      rstAll.sort (r1, r2) ->
        return r1.year - r2.year unless r1.year is r2.year
        return r1.month - r2.month unless r1.month is r2.month
        r1.day - r2.day
      def.resolve rstAll
      return
    tbl.rstQ = def.promise

  #Promise to array of {month, day, rst:[{year, temp}]} objects.
  M.byMonthAndDayQ = (url) ->
    tbl = getTbl url
    return tbl.byMonthAndDayQ if tbl.hasOwnProperty "byMonthAndDayQ"
    def = $q.defer()
    M.rstQ(url).then (rst) ->
      byMonthAndDay = []   #put each measurement into correct month and day group
      rst.forEach (p) ->
        filtered = byMonthAndDay.filter (md) -> p.day is md.day and p.month is md.month
        if filtered.length
          md = filtered[0]
        else
          md = month: p.month, day: p.day, rst: []
          byMonthAndDay.push md
        md.rst.push
          year: p.year
          temp: p.temp
        return
      #no sorting necessary, as rst already sorted.
      def.resolve byMonthAndDay
      return
    tbl.byMonthAndDayQ = def.promise

  #Promise to array of {month, rst:[{year, temp}]} objects.
  M.byMonthQ = (url) ->
    tbl = getTbl url
    return tbl.byMonthQ if tbl.hasOwnProperty "byMonthQ"
    def = $q.defer()
    M.rstQ(url).then (rst) ->
      #Group all measurements that must be averaged.
      byYearAndMonth = []
      rst.forEach (p) -> #put each measurement into correct year and month group
        filtered = byYearAndMonth.filter (bym) -> p.year is bym.year and p.month is bym.month
        if filtered.length
          ym = filtered[0]
        else
          ym = year: p.year, month: p.month, rst: []
          byYearAndMonth.push ym
        ym.rst.push p #p.rst contains measurements that differ only in day
        return
      #Do averaging and created wanted rst.
      byMonth = []
      byYearAndMonth.forEach (ym) ->
        filtered = byMonth.filter (m) -> ym.month is m.month
        if filtered.length
          m = filtered[0]
        else
          m = month: ym.month, rst: []
          byMonth.push m
        tempSum = ym.rst.map((p) -> p.temp).reduce (a, b) -> a + b
        tempAv = tempSum / ym.rst.length
        m.rst.push
          year: ym.year
          temp: tempAv
        return
      def.resolve byMonth
      return
    tbl.byMonthQ = def.promise
  M
