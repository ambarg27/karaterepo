@mutating
Feature: TTP API domain writes and lifecycle

  Background:
    * def auth = callonce read('classpath:ttp/auth.feature')
    * def authHeaders = function() { return { Authorization: 'Bearer ' + auth.token } }
    * configure headers = authHeaders
    * def createdContactId = null
    * def createdItemIds = []
    * def cancellableRequestIds = []
    * configure afterScenario =
    """
    function() {
      karate.call('classpath:ttp/api/cleanup-owned.feature', {
        token: auth.token,
        contactId: createdContactId,
        itemIds: createdItemIds,
        cancellableRequestIds: cancellableRequestIds
      });
    }
    """

  @mutating @TTP-API-040
  Scenario: TTP-API-040 contact CRUD creates updates and deletes an owned contact
    * def contactPayload = { firstName: 'K2', lastName: 'Contact', phone: '515-555-2040', email: 'k2-040@example.com', status: 'Active' }
    Given url ttpBaseUrl
    And path '/api/contacts'
    And request contactPayload
    When method POST
    Then status 201
    And match response == read('classpath:ttp/shapes/contact.json')
    * def createdContactId = response.id
    Given path '/api/contacts/' + createdContactId
    When method GET
    Then status 200
    And match response.id == createdContactId
    And match response.email == contactPayload.email
    Given path '/api/contacts/' + createdContactId
    And request { phone: '515-555-2041', status: 'Pending' }
    When method PUT
    Then status 200
    And match response.phone == '515-555-2041'
    And match response.status == 'Pending'
    Given path '/api/contacts/' + createdContactId
    When method DELETE
    Then status 204
    Given path '/api/contacts/' + createdContactId
    When method GET
    Then status 404
    And match response == read('classpath:ttp/shapes/error.json')
    And match response.errorCode == 'NOT_FOUND'
    * def createdContactId = null

  @mutating @TTP-API-041
  Scenario: TTP-API-041 missing contact fields return one validation detail per field
    Given url ttpBaseUrl
    And path '/api/contacts'
    And request {}
    When method POST
    Then status 400
    And match response == read('classpath:ttp/shapes/error.json')
    And match response.errorCode == 'VALIDATION_ERROR'
    And match response.details[*].field == ['firstName', 'lastName', 'phone', 'email', 'status']

  @mutating @TTP-API-042
  Scenario: TTP-API-042 item CRUD is linked to an owned contact
    * def contactPayload = { firstName: 'K2', lastName: 'ItemOwner', phone: '515-555-2042', email: 'k2-042@example.com', status: 'Active' }
    Given url ttpBaseUrl
    And path '/api/contacts'
    And request contactPayload
    When method POST
    Then status 201
    * def createdContactId = response.id
    Given path '/api/items'
    And request { contactId: '#(createdContactId)', name: 'K2 Item', category: 'Standard', size: 'Medium', priority: 'Normal', reviewStatus: 'Approved', notes: 'owned item' }
    When method POST
    Then status 201
    And match response == read('classpath:ttp/shapes/item.json')
    And match response.contactId == createdContactId
    * eval createdItemIds.push(response.id)
    * def createdItemId = response.id
    Given path '/api/items/' + createdItemId
    And request { name: 'K2 Updated Item', notes: 'updated item' }
    When method PUT
    Then status 200
    And match response.name == 'K2 Updated Item'
    And match response.contactId == createdContactId
    Given path '/api/items/' + createdItemId
    When method DELETE
    Then status 204
    * def createdItemIds = []
    Given path '/api/items/' + createdItemId
    When method GET
    Then status 404
    And match response.errorCode == 'NOT_FOUND'

  @mutating @TTP-API-043
  Scenario: TTP-API-043 unknown item contact is rejected
    Given url ttpBaseUrl
    And path '/api/items'
    And request { contactId: 'c-k2-unknown', name: 'Invalid Item', category: 'Standard', size: 'Medium', priority: 'Normal', reviewStatus: 'Approved' }
    When method POST
    Then status 400
    And match response == read('classpath:ttp/shapes/error.json')
    And match response.errorCode == 'VALIDATION_ERROR'
    And match response.details[*].field contains 'contactId'

  @mutating @TTP-API-044
  Scenario: TTP-API-044 availability reports an owned blocked item
    * def contactPayload = { firstName: 'K2', lastName: 'Availability', phone: '515-555-2044', email: 'k2-044@example.com', status: 'Active' }
    Given url ttpBaseUrl
    And path '/api/contacts'
    And request contactPayload
    When method POST
    Then status 201
    * def createdContactId = response.id
    Given path '/api/items'
    And request { contactId: '#(createdContactId)', name: 'Available Item', category: 'Standard', size: 'Medium', priority: 'Normal', reviewStatus: 'Approved' }
    When method POST
    Then status 201
    * eval createdItemIds.push(response.id)
    * def availableItemId = response.id
    Given path '/api/items'
    And request { contactId: '#(createdContactId)', name: 'Blocked Item', category: 'Restricted', size: 'Medium', priority: 'Normal', reviewStatus: 'Approved' }
    When method POST
    Then status 201
    * eval createdItemIds.push(response.id)
    * def blockedItemId = response.id
    Given path '/api/requests/availability'
    And request { itemIds: ['#(availableItemId)', '#(blockedItemId)'], startDate: '2026-06-01', endDate: '2026-06-30' }
    When method POST
    Then status 200
    And match response.startDate == '2026-06-01'
    And match response.endDate == '2026-06-30'
    And match response.results contains deep { itemId: '#(availableItemId)', available: true }
    And match response.results contains deep { itemId: '#(blockedItemId)', available: false }
    And match response.results[1].reason contains 'category=Restricted'
    And match response.allAvailable == false

  @mutating @TTP-API-045
  Scenario: TTP-API-045 quote is deterministic and covers tier items and options
    * def tiers = call read('classpath:ttp/api/metadata.feature')
    * def selectedTier = tiers.tier
    * def selectedOption = tiers.option
    * def contactPayload = { firstName: 'K2', lastName: 'Quote', phone: '515-555-2045', email: 'k2-045@example.com', status: 'Active' }
    Given url ttpBaseUrl
    And path '/api/contacts'
    And request contactPayload
    When method POST
    Then status 201
    * def createdContactId = response.id
    Given path '/api/items'
    And request { contactId: '#(createdContactId)', name: 'Quote Item One', category: 'Standard', size: 'Medium', priority: 'Normal', reviewStatus: 'Approved' }
    When method POST
    Then status 201
    * eval createdItemIds.push(response.id)
    * def firstItemId = response.id
    Given path '/api/items'
    And request { contactId: '#(createdContactId)', name: 'Quote Item Two', category: 'Compact', size: 'Small', priority: 'Low', reviewStatus: 'Approved' }
    When method POST
    Then status 201
    * eval createdItemIds.push(response.id)
    * def secondItemId = response.id
    * def quotePayload = { tier: '#(selectedTier)', itemIds: ['#(firstItemId)', '#(secondItemId)'], options: ['#(selectedOption)'], startDate: '2026-07-01', endDate: '2026-07-10' }
    Given path '/api/requests/quote'
    And request quotePayload
    When method POST
    Then status 200
    * def firstQuote = response
    Given path '/api/requests/quote'
    And request quotePayload
    When method POST
    Then status 200
    * def secondQuote = response
    And match secondQuote.total == firstQuote.total
    And match firstQuote.lineItems[*].label contains 'Tier ' + selectedTier
    And match firstQuote.lineItems[*].label contains '2 item(s)'
    And match firstQuote.lineItems[*].label contains selectedOption
    And match firstQuote.total == '#number'

  @mutating @TTP-API-046
  Scenario: TTP-API-046 valid request starts as draft and matches its quote
    * def tiers = call read('classpath:ttp/api/metadata.feature')
    * def selectedTier = tiers.tier
    * def selectedOption = tiers.option
    * def contactPayload = { firstName: 'K2', lastName: 'Request', phone: '515-555-2046', email: 'k2-046@example.com', status: 'Active' }
    Given url ttpBaseUrl
    And path '/api/contacts'
    And request contactPayload
    When method POST
    Then status 201
    * def createdContactId = response.id
    Given path '/api/items'
    And request { contactId: '#(createdContactId)', name: 'Request Item', category: 'Standard', size: 'Medium', priority: 'Normal', reviewStatus: 'Approved' }
    When method POST
    Then status 201
    * eval createdItemIds.push(response.id)
    * def createdItemId = response.id
    * def requestPayload = { contactId: '#(createdContactId)', tier: '#(selectedTier)', itemIds: ['#(createdItemId)'], options: ['#(selectedOption)'], startDate: '2026-08-01', endDate: '2026-08-10', notes: 'K2 request' }
    Given path '/api/requests/quote'
    And request requestPayload
    When method POST
    Then status 200
    * def quoteTotal = response.total
    Given path '/api/requests'
    And request requestPayload
    When method POST
    Then status 201
    And match response == read('classpath:ttp/shapes/request.json')
    And match response.status == 'Draft'
    And match response.total == quoteTotal
    * eval cancellableRequestIds.push(response.id)

  @mutating @TTP-API-047
  Scenario: TTP-API-047 invalid tier and empty item ids are rejected
    * def tiers = call read('classpath:ttp/api/metadata.feature')
    * def selectedTier = tiers.tier
    * def contactPayload = { firstName: 'K2', lastName: 'Validation', phone: '515-555-2047', email: 'k2-047@example.com', status: 'Active' }
    Given url ttpBaseUrl
    And path '/api/contacts'
    And request contactPayload
    When method POST
    Then status 201
    * def createdContactId = response.id
    Given path '/api/items'
    And request { contactId: '#(createdContactId)', name: 'Validation Item', category: 'Standard', size: 'Medium', priority: 'Normal', reviewStatus: 'Approved' }
    When method POST
    Then status 201
    * eval createdItemIds.push(response.id)
    * def createdItemId = response.id
    Given path '/api/requests'
    And request { contactId: '#(createdContactId)', tier: 'NotARealTier', itemIds: ['#(createdItemId)'], startDate: '2026-09-01', endDate: '2026-09-10', options: [] }
    When method POST
    Then status 400
    And match response.errorCode == 'VALIDATION_ERROR'
    And match response.details[*].field contains 'tier'
    Given path '/api/requests'
    And request { contactId: '#(createdContactId)', tier: '#(selectedTier)', itemIds: [], startDate: '2026-09-01', endDate: '2026-09-10', options: [] }
    When method POST
    Then status 400
    And match response.errorCode == 'VALIDATION_ERROR'
    And match response.details[*].field contains 'itemIds'

  @mutating @TTP-API-048
  Scenario: TTP-API-048 request lifecycle reaches completed
    * def requestData = call read('classpath:ttp/api/request-fixture.feature')
    * def createdContactId = requestData.contactId
    * eval createdItemIds.push(requestData.itemId)
    Given url ttpBaseUrl
    And path '/api/requests/' + requestData.requestId + '/submit'
    When method POST
    Then status 200
    And match response.status == 'Submitted'
    Given path '/api/requests/' + requestData.requestId + '/start'
    When method POST
    Then status 200
    And match response.status == 'InProgress'
    Given path '/api/requests/' + requestData.requestId + '/complete'
    When method POST
    Then status 200
    And match response.status == 'Completed'

  @mutating @TTP-API-049
  Scenario: TTP-API-049 start cannot skip submit and preserves draft status
    * def requestData = call read('classpath:ttp/api/request-fixture.feature')
    * def createdContactId = requestData.contactId
    * eval createdItemIds.push(requestData.itemId)
    * eval cancellableRequestIds.push(requestData.requestId)
    Given url ttpBaseUrl
    And path '/api/requests/' + requestData.requestId + '/start'
    When method POST
    Then status 409
    And match response == read('classpath:ttp/shapes/error.json')
    And match response.errorCode == 'INVALID_STATE_TRANSITION'
    Given path '/api/requests/' + requestData.requestId
    When method GET
    Then status 200
    And match response.status == 'Draft'

  @mutating @TTP-API-050
  Scenario: TTP-API-050 completed request cannot be cancelled
    * def requestData = call read('classpath:ttp/api/request-fixture.feature')
    * def createdContactId = requestData.contactId
    * eval createdItemIds.push(requestData.itemId)
    Given url ttpBaseUrl
    And path '/api/requests/' + requestData.requestId + '/submit'
    When method POST
    Then status 200
    Given path '/api/requests/' + requestData.requestId + '/start'
    When method POST
    Then status 200
    Given path '/api/requests/' + requestData.requestId + '/complete'
    When method POST
    Then status 200
    Given path '/api/requests/' + requestData.requestId + '/cancel'
    When method POST
    Then status 409
    And match response.errorCode == 'INVALID_STATE_TRANSITION'
    Given path '/api/requests/' + requestData.requestId
    When method GET
    Then status 200
    And match response.status == 'Completed'

  @mutating @TTP-API-051
  Scenario: TTP-API-051 draft submitted and started requests can be cancelled
    * def tiers = call read('classpath:ttp/api/metadata.feature')
    * def selectedTier = tiers.tier
    * def contactPayload = { firstName: 'K2', lastName: 'Cancel', phone: '515-555-2051', email: 'k2-051@example.com', status: 'Active' }
    Given url ttpBaseUrl
    And path '/api/contacts'
    And request contactPayload
    When method POST
    Then status 201
    * def createdContactId = response.id
    Given path '/api/items'
    And request { contactId: '#(createdContactId)', name: 'Cancel Item', category: 'Standard', size: 'Medium', priority: 'Normal', reviewStatus: 'Approved' }
    When method POST
    Then status 201
    * eval createdItemIds.push(response.id)
    * def createdItemId = response.id
    * def requestPayload = { contactId: '#(createdContactId)', tier: '#(selectedTier)', itemIds: ['#(createdItemId)'], options: [], startDate: '2026-10-01', endDate: '2026-10-10' }
    Given path '/api/requests'
    And request requestPayload
    When method POST
    Then status 201
    * def draftRequestId = response.id
    Given path '/api/requests/' + draftRequestId + '/cancel'
    When method POST
    Then status 200
    And match response.status == 'Cancelled'
    Given path '/api/requests'
    And request requestPayload
    When method POST
    Then status 201
    * def submittedRequestId = response.id
    Given path '/api/requests/' + submittedRequestId + '/submit'
    When method POST
    Then status 200
    Given path '/api/requests/' + submittedRequestId + '/cancel'
    When method POST
    Then status 200
    And match response.status == 'Cancelled'
    Given path '/api/requests'
    And request requestPayload
    When method POST
    Then status 201
    * def startedRequestId = response.id
    Given path '/api/requests/' + startedRequestId + '/submit'
    When method POST
    Then status 200
    Given path '/api/requests/' + startedRequestId + '/start'
    When method POST
    Then status 200
    Given path '/api/requests/' + startedRequestId + '/cancel'
    When method POST
    Then status 200
    And match response.status == 'Cancelled'
