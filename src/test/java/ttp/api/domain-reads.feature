@readonly
Feature: TTP API domain reads

  Background:
    * def auth = callonce read('classpath:ttp/auth.feature')
    * def authHeaders = function() { return { Authorization: 'Bearer ' + auth.token } }
    * configure headers = authHeaders

  @readonly @TTP-API-020
  Scenario: TTP-API-020 contacts page has the requested shape
    Given url ttpBaseUrl
    And path '/api/contacts'
    And param page = 1
    And param pageSize = 2
    When method GET
    Then status 200
    And match response == read('classpath:ttp/shapes/contactPage.json')
    And match response.page == 1
    And match response.pageSize == 2
    And match response.items == '#[2]'
    And assert response.totalPages == Math.ceil(response.totalItems / response.pageSize)

  @readonly @TTP-API-021
  Scenario: TTP-API-021 contact sort order reverses exactly
    Given url ttpBaseUrl
    And path '/api/contacts'
    And param sort = '-lastName'
    When method GET
    Then status 200
    * def descending = response.items
    Given path '/api/contacts'
    And param sort = 'lastName'
    When method GET
    Then status 200
    * def ascending = response.items
    And match descending == ascending.reverse()

  @readonly @TTP-API-022
  Scenario: TTP-API-022 contact search uses the seeded surname
    Given url ttpBaseUrl
    And path '/api/contacts/c-1'
    When method GET
    Then status 200
    * def surname = response.lastName
    Given path '/api/contacts'
    And param q = surname
    When method GET
    Then status 200
    And match response.items[*].id contains 'c-1'
    And match each response.items[*].lastName == surname

  @readonly @TTP-API-023
  Scenario: TTP-API-023 contact detail matches its schema
    Given url ttpBaseUrl
    And path '/api/contacts/c-1'
    When method GET
    Then status 200
    And match response == read('classpath:ttp/shapes/contact.json')
    And match response.id == 'c-1'

  @readonly @TTP-API-024
  Scenario: TTP-API-024 unknown contact uses the standard error contract
    Given url ttpBaseUrl
    And path '/api/contacts/c-999'
    When method GET
    Then status 404
    And match response == read('classpath:ttp/shapes/error.json')
    And match response.errorCode == 'NOT_FOUND'

  @readonly @TTP-API-025
  Scenario: TTP-API-025 contact items belong to the requested contact
    Given url ttpBaseUrl
    And path '/api/contacts/c-1/items'
    When method GET
    Then status 200
    And match each response.items contains { contactId: 'c-1' }
    * def itemIds = karate.jsonPath(response, '$.items[*].id')
    * eval itemIds.sort()
    And match itemIds == ['i-1', 'i-2', 'i-3']

  @readonly @TTP-API-026
  Scenario: TTP-API-026 review filter returns flagged seeded items
    Given url ttpBaseUrl
    And path '/api/items'
    And param reviewStatus = 'NeedsReview'
    When method GET
    Then status 200
    And match each response.items[*].reviewStatus == 'NeedsReview'
    And match response.items[*].id contains 'i-3'
    And match response.items[*].id contains 'i-8'

  @readonly @TTP-API-027
  Scenario: TTP-API-027 item detail and unknown item are covered
    Given url ttpBaseUrl
    And path '/api/items/i-1'
    When method GET
    Then status 200
    And match response == read('classpath:ttp/shapes/item.json')
    And match response.id == 'i-1'
    Given path '/api/items/i-999'
    When method GET
    Then status 404
    And match response == read('classpath:ttp/shapes/error.json')
    And match response.errorCode == 'NOT_FOUND'

  @readonly @TTP-API-028
  Scenario: TTP-API-028 request statuses span the seeded lifecycle
    Given url ttpBaseUrl
    And path '/api/requests'
    When method GET
    Then status 200
    And match response.items[*].status contains ['Draft', 'Submitted', 'InProgress', 'Completed']

  @readonly @TTP-API-029
  Scenario: TTP-API-029 request detail and unknown request are covered
    Given url ttpBaseUrl
    And path '/api/requests/r-1'
    When method GET
    Then status 200
    And match response == read('classpath:ttp/shapes/request.json')
    * assert response.options.every(function(option) { return typeof option == 'string'; })
    And match response.id == 'r-1'
    Given path '/api/requests/r-999'
    When method GET
    Then status 404
    And match response == read('classpath:ttp/shapes/error.json')
    And match response.errorCode == 'NOT_FOUND'

  @readonly @TTP-API-030
  Scenario: TTP-API-030 summary agrees with the list endpoints
    Given url ttpBaseUrl
    And path '/api/contacts'
    When method GET
    Then status 200
    * def contacts = response
    Given path '/api/items'
    When method GET
    Then status 200
    * def items = response
    Given path '/api/requests'
    When method GET
    Then status 200
    * def requests = response
    Given path '/api/summary'
    When method GET
    Then status 200
    And match response == read('classpath:ttp/shapes/summary.json')
    And match response.contacts == contacts.totalItems
    And match response.items == items.totalItems
    And match response.requests == requests.totalItems
    * def statusTotal = response.requestsByStatus[0].count + response.requestsByStatus[1].count + response.requestsByStatus[2].count + response.requestsByStatus[3].count + response.requestsByStatus[4].count
    And match statusTotal == requests.totalItems

  @readonly @TTP-API-031
  Scenario: TTP-API-031 metadata endpoints return values
    Given url ttpBaseUrl
    And path '/api/metadata/categories'
    When method GET
    Then status 200
    And match response.items == ['Standard', 'Compact', 'Oversized', 'Fragile', 'Restricted']
    Given path '/api/metadata/tiers'
    When method GET
    Then status 200
    And match response.items == [{ name: 'Basic', rate: 100 }, { name: 'Plus', rate: 175 }, { name: 'Premium', rate: 260 }]
    Given path '/api/metadata/statuses'
    When method GET
    Then status 200
    And match response.items == ['Draft', 'Submitted', 'InProgress', 'Completed', 'Cancelled']
    Given path '/api/metadata/options'
    When method GET
    Then status 200
    And match response.items == [{ name: 'Insurance', rate: 25 }, { name: 'Priority Handling', rate: 40 }, { name: 'Weekend Pickup', rate: 30 }, { name: 'Assembly', rate: 55 }, { name: 'Extended Hold', rate: 20 }]
    Given path '/api/metadata/review-statuses'
    When method GET
    Then status 200
    And match response.items == ['Approved', 'NeedsReview', 'Rejected']

  @readonly @TTP-API-032
  Scenario: TTP-API-032 CSV downloads contain headers and data
    Given url ttpBaseUrl
    And path '/api/download/contacts.csv'
    When method GET
    Then status 200
    And match responseHeaders['Content-Type'][0] contains 'text/csv'
    And match responseHeaders['Content-Disposition'][0] contains 'attachment'
    And match response contains '"id","firstName","lastName"'
    And match response contains '"c-1","Ada","Nolan","515-555-0101","ada.nolan@example.com","Active"'
    Given path '/api/download/items.csv'
    When method GET
    Then status 200
    And match responseHeaders['Content-Type'][0] contains 'text/csv'
    And match responseHeaders['Content-Disposition'][0] contains 'attachment'
    And match response contains '"id","contactId","name"'
    And match response contains '"i-1","c-1","Blue Crate","Standard","Medium","Normal","Approved"'
