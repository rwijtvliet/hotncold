'use strict'

describe 'Directive: hcSimpleGraph', ->

  # load the directive's module
  beforeEach module 'hcApp'

  scope = {}

  beforeEach inject ($controller, $rootScope) ->
    scope = $rootScope.$new()

  it 'should make hidden element visible', inject ($compile) ->
    element = angular.element '<hc-simple-graph></hc-simple-graph>'
    element = $compile(element) scope
    expect(element.text()).toBe 'this is the hcSimpleGraph directive'
