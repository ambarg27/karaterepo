@readonly
Feature: TTP API authentication

  @readonly @TTP-API-010
  Scenario: TTP-API-010 valid login returns a user token
    Given url ttpBaseUrl
    And path '/api/auth/login'
    And request { username: '#(ttpUser)', password: '#(ttpPassword)' }
    When method POST
    Then status 200
    And match response == read('classpath:ttp/shapes/token.json')
    * def Base64 = Java.type('java.util.Base64')
    * def JString = Java.type('java.lang.String')
    * def payload = new JString(Base64.getUrlDecoder().decode(response.token.split('.')[1]), 'UTF-8')
    * json claims = payload
    And match claims.sub == ttpUser

  @readonly @TTP-API-011
  Scenario: TTP-API-011 wrong password is rejected
    Given url ttpBaseUrl
    And path '/api/auth/login'
    And request { username: '#(ttpUser)', password: '#(ttpPassword + "-wrong")' }
    When method POST
    Then status 401
    And match response == read('classpath:ttp/shapes/error.json')
    And match response.errorCode == 'UNAUTHORIZED'

  @readonly @TTP-API-012
  Scenario: TTP-API-012 missing login body fields are reported
    Given url ttpBaseUrl
    And path '/api/auth/login'
    When method POST
    Then status 400
    And match response == read('classpath:ttp/shapes/error.json')
    And match response.errorCode == 'VALIDATION_ERROR'
    And match response.details[*].field contains ['username', 'password']

  @readonly @TTP-API-013
  Scenario: TTP-API-013 service token has no subject claim
    Given url ttpBaseUrl
    And path '/api/auth/issue-token'
    When method POST
    Then status 200
    And match response == { token: '#string' }
    * def Base64 = Java.type('java.util.Base64')
    * def JString = Java.type('java.lang.String')
    * def payload = new JString(Base64.getUrlDecoder().decode(response.token.split('.')[1]), 'UTF-8')
    * json claims = payload
    And match claims.scope == 'ttp.service'
    And match claims.sub == '#notpresent'

  @readonly @TTP-API-014
  Scenario: TTP-API-014 ping without a token is rejected
    Given url ttpBaseUrl
    And path '/api/ping'
    When method GET
    Then status 401
    And match response == read('classpath:ttp/shapes/error.json')
    And match response.errorCode == 'UNAUTHORIZED'

  @readonly @TTP-API-015
  Scenario: TTP-API-015 garbage bearer token is rejected
    Given url ttpBaseUrl
    And path '/api/ping'
    And header Authorization = 'Bearer not-a-real-token'
    When method GET
    Then status 401
    And match response == read('classpath:ttp/shapes/error.json')
    And match response.errorCode == 'UNAUTHORIZED'

  @readonly @TTP-API-016
  Scenario: TTP-API-016 valid bearer token reaches ping
    * def auth = callonce read('classpath:ttp/auth.feature')
    Given url ttpBaseUrl
    And path '/api/ping'
    And header Authorization = 'Bearer ' + auth.token
    When method GET
    Then status 200
    And match response.status == 'OK'
    And match response.userId == ttpUser
    And match response.correlationId == '#string'
