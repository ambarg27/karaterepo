@exclusive
Feature: TTP API reset and seed harness

  Background:
    * def auth = callonce read('classpath:ttp/auth.feature')
    * def authHeaders = function() { return { Authorization: 'Bearer ' + auth.token } }
    * configure headers = authHeaders
    * configure afterScenario =
    """
    function() {
      karate.call('classpath:ttp/api/cleanup-admin.feature');
    }
    """

  @exclusive @TTP-API-070
  Scenario: TTP-API-070 reset restores the baseline after a mutation
    * def contactPayload = { firstName: 'K2', lastName: 'Reset', phone: '515-555-2070', email: 'k2-070@example.com', status: 'Active' }
    Given url ttpBaseUrl
    And path '/api/contacts'
    And request contactPayload
    When method POST
    Then status 201
    * def createdContactId = response.id
    Given path '/api/test/reset'
    And header X-Admin-Token = ttpAdminToken
    When method POST
    Then status 200
    And match response.status == 'RESET'
    And match response.dataset == 'baseline'
    And match response.counts == { contacts: 5, items: 8, requests: 5, needsReview: 2 }
    Given path '/api/contacts/' + createdContactId
    When method GET
    Then status 404
    And match response.errorCode == 'NOT_FOUND'

  @exclusive @TTP-API-071
  Scenario: TTP-API-071 invalid admin headers cannot reset mutated data
    * def contactPayload = { firstName: 'K2', lastName: 'Forbidden', phone: '515-555-2071', email: 'k2-071@example.com', status: 'Active' }
    Given url ttpBaseUrl
    And path '/api/contacts'
    And request contactPayload
    When method POST
    Then status 201
    * def createdContactId = response.id
    Given path '/api/test/reset'
    When method POST
    Then status 403
    And match response == read('classpath:ttp/shapes/error.json')
    And match response.errorCode == 'FORBIDDEN'
    Given path '/api/test/reset'
    And header X-Admin-Token = 'wrong-admin-token'
    When method POST
    Then status 403
    And match response.errorCode == 'FORBIDDEN'
    Given path '/api/contacts/' + createdContactId
    When method GET
    Then status 200
    And match response.id == createdContactId

  @exclusive @TTP-API-072
  Scenario: TTP-API-072 empty seed removes all domain entities
    Given url ttpBaseUrl
    And path '/api/test/seed'
    And header X-Admin-Token = ttpAdminToken
    And request { dataset: 'empty' }
    When method POST
    Then status 200
    And match response.status == 'SEEDED'
    And match response.dataset == 'empty'
    Given path '/api/contacts'
    When method GET
    Then status 200
    And match response.items == '#[]'
    Given path '/api/items'
    When method GET
    Then status 200
    And match response.items == '#[]'
    Given path '/api/requests'
    When method GET
    Then status 200
    And match response.items == '#[]'

  @exclusive @TTP-API-073
  Scenario: TTP-API-073 busy seed exposes the larger dataset summary
    Given url ttpBaseUrl
    And path '/api/test/seed'
    And header X-Admin-Token = ttpAdminToken
    And request { dataset: 'busy' }
    When method POST
    Then status 200
    And match response.dataset == 'busy'
    Given path '/api/summary'
    When method GET
    Then status 200
    And match response == read('classpath:ttp/shapes/summary.json')
    And match response.dataset == 'busy'
    And match response.contacts == 30
    And match response.items == 33
    And match response.requests == 5
    And match response.itemsNeedingReview == 7

  @exclusive @TTP-API-074
  Scenario: TTP-API-074 reset returns seeded datasets to baseline
    Given url ttpBaseUrl
    And path '/api/test/seed'
    And header X-Admin-Token = ttpAdminToken
    And request { dataset: 'empty' }
    When method POST
    Then status 200
    Given path '/api/test/reset'
    And header X-Admin-Token = ttpAdminToken
    When method POST
    Then status 200
    And match response.status == 'RESET'
    And match response.dataset == 'baseline'
    And match response.counts == { contacts: 5, items: 8, requests: 5, needsReview: 2 }

  @exclusive @TTP-API-075
  Scenario: TTP-API-075 unknown seed dataset is rejected
    Given url ttpBaseUrl
    And path '/api/test/seed'
    And header X-Admin-Token = ttpAdminToken
    And request { dataset: 'nope' }
    When method POST
    Then status 400
    And match response == read('classpath:ttp/shapes/error.json')
    And match response.errorCode == 'VALIDATION_ERROR'
    And match response.details[*].field contains 'dataset'
