'use strict'

describe 'Service: Measurements', ->

  # load the service's module
  beforeEach module 'hcApp'

  # instantiate service
  Measurements = {}
  beforeEach inject (_Measurements_) ->
    Measurements = _Measurements_

  it 'should do something', ->
    expect(!!Measurements).toBe true
