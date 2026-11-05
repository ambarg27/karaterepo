@readonly
Feature: TTP API health and harness validation

  @readonly @TTP-API-001
  Scenario: TTP-API-001 live health is available
    Given url ttpBaseUrl
    And path '/api/health/live'
    When method GET
    Then status 200
    And match response.status == 'UP'

  @readonly @TTP-API-002
  Scenario: TTP-API-002 ready health reports the baseline store
    Given url ttpBaseUrl
    And path '/api/health/ready'
    When method GET
    Then status 200
    And match response == read('classpath:ttp/shapes/health.json')
    And match response.status == 'UP'
    And match response.dataset == 'baseline'
    And match response.checks contains deep { name: 'process', status: 'UP' }
    And match response.checks contains deep { name: 'store', status: 'UP' }

  @readonly @TTP-API-003
  Scenario: TTP-API-003 headers echo authorization and correlation
    * def auth = callonce read('classpath:ttp/auth.feature')
    * def correlationId = java.util.UUID.randomUUID().toString()
    * def authHeader = 'Bearer ' + auth.token
    Given url ttpBaseUrl
    And path '/api/headers'
    And header Authorization = authHeader
    And header X-Correlation-Id = correlationId
    When method GET
    Then status 200
    And match response.authorizationPresent == true
    And match response.authorizationScheme == 'Bearer'
    And match response.correlationId == correlationId
    And match response.headers.authorization == authHeader
    And match response.headers['x-correlation-id'] == correlationId

  @readonly @TTP-API-004
  Scenario: TTP-API-004 echo preserves request details
    * def correlationId = java.util.UUID.randomUUID().toString()
    * def payload = { testId: 'TTP-API-004', readonly: true }
    Given url ttpBaseUrl
    And path '/api/echo'
    And header X-Correlation-Id = correlationId
    And request payload
    When method POST
    Then status 200
    And match response.method == 'POST'
    And match response.path == '/api/echo'
    And match response.body == payload
    And match response.correlationId == correlationId
    And match response.headers['x-correlation-id'] == correlationId

  @readonly @TTP-API-005
  Scenario: TTP-API-005 delay endpoint honors the requested delay
    * def started = java.lang.System.currentTimeMillis()
    Given url ttpBaseUrl
    And path '/api/delay/2'
    When method GET
    Then status 200
    * def elapsed = java.lang.System.currentTimeMillis() - started
    And match response.delayedSeconds == 2
    And assert elapsed >= 2000

  @readonly @TTP-API-006
  Scenario: TTP-API-006 correlation ids are echoed or generated
    * def correlationId = java.util.UUID.randomUUID().toString()
    Given url ttpBaseUrl
    And path '/api/health/live'
    And header X-Correlation-Id = correlationId
    When method GET
    Then status 200
    And match responseHeaders['X-Correlation-Id'][0] == correlationId
    Given path '/api/health/live'
    When method GET
    Then status 200
    And match responseHeaders['X-Correlation-Id'][0] == '#string'
