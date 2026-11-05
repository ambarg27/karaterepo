Feature: TTP request fixture

  Scenario: Create an owned draft request
    * def metadata = call read('classpath:ttp/api/metadata.feature')
    * def contactPayload = { firstName: 'K2', lastName: 'Lifecycle', phone: '515-555-2048', email: '#(java.util.UUID.randomUUID().toString() + "@example.com")', status: 'Active' }
    Given url ttpBaseUrl
    And path '/api/contacts'
    And header Authorization = 'Bearer ' + auth.token
    And request contactPayload
    When method POST
    Then status 201
    * def contactId = response.id
    Given path '/api/items'
    And request { contactId: '#(contactId)', name: 'Lifecycle Item', category: 'Standard', size: 'Medium', priority: 'Normal', reviewStatus: 'Approved' }
    When method POST
    Then status 201
    * def itemId = response.id
    * def requestPayload = { contactId: '#(contactId)', tier: '#(metadata.tier)', itemIds: ['#(itemId)'], options: [], startDate: '2026-11-01', endDate: '2026-11-10' }
    Given path '/api/requests'
    And request requestPayload
    When method POST
    Then status 201
    * def requestId = response.id
