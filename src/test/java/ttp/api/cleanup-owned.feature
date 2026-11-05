Feature: TTP owned entity cleanup

  Background:
    * configure afterScenario = null

  Scenario: Clean all entities owned by a mutating scenario
    * eval cancellableRequestIds.forEach(function(id) { karate.call('classpath:ttp/api/cancel-request.feature', { token: token, requestId: id }) })
    * eval itemIds.forEach(function(id) { karate.call('classpath:ttp/api/delete-resource.feature', { token: token, resourcePath: '/api/items/' + id }) })
    * if (contactId != null) karate.call('classpath:ttp/api/delete-resource.feature', { token: token, resourcePath: '/api/contacts/' + contactId })
