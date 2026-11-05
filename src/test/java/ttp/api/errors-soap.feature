@readonly
Feature: TTP API deterministic errors and SOAP

  Background:
    * def auth = callonce read('classpath:ttp/auth.feature')
    * def authHeaders = function() { return { Authorization: 'Bearer ' + auth.token } }
    * configure headers = authHeaders

  @readonly @TTP-API-060
  Scenario: TTP-API-060 deterministic errors use the standard contract
    Given url ttpBaseUrl
    And path '/api/errors/401'
    When method GET
    Then status 401
    And match response == read('classpath:ttp/shapes/error.json')
    And match response.errorCode == 'UNAUTHORIZED'
    Given path '/api/errors/404'
    When method GET
    Then status 404
    And match response == read('classpath:ttp/shapes/error.json')
    And match response.errorCode == 'NOT_FOUND'
    Given path '/api/errors/500'
    When method GET
    Then status 500
    And match response == read('classpath:ttp/shapes/error.json')
    And match response.errorCode == 'INTERNAL_ERROR'
    Given path '/api/errors/validation'
    When method GET
    Then status 400
    And match response == read('classpath:ttp/shapes/error.json')
    And match response.errorCode == 'VALIDATION_ERROR'
    And match response.details == '#[2]'

  @readonly @TTP-API-061
  Scenario: TTP-API-061 SOAP contact summary is namespace agnostic
    Given url ttpBaseUrl
    And path '/soap/contact-service'
    And header Content-Type = 'text/xml'
    And request
    """
    <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
      <soap:Body><GetContactSummary><ContactId>c-1</ContactId></GetContactSummary></soap:Body>
    </soap:Envelope>
    """
    When method POST
    Then status 200
    And match responseHeaders['Content-Type'][0] contains 'text/xml'
    * def contactId = karate.xmlPath(response, "string(//*[local-name()='ContactId'])")
    * def fullName = karate.xmlPath(response, "string(//*[local-name()='FullName'])")
    And match contactId == 'c-1'
    And match fullName == 'Ada Nolan'

  @readonly @TTP-API-062
  Scenario: TTP-API-062 SOAP item count and request status are available
    Given url ttpBaseUrl
    And path '/api/requests/r-1'
    When method GET
    Then status 200
    * def expectedStatus = response.status
    Given path '/soap/contact-service'
    And header Content-Type = 'text/xml'
    And request
    """
    <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
      <soap:Body><GetItemCount/></soap:Body>
    </soap:Envelope>
    """
    When method POST
    Then status 200
    * def itemCount = karate.xmlPath(response, "string(//*[local-name()='ItemCountResult'])")
    And match itemCount == '#string'
    Given path '/soap/contact-service'
    And header Content-Type = 'text/xml'
    And request
    """
    <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
      <soap:Body><GetRequestStatus><RequestId>r-1</RequestId></GetRequestStatus></soap:Body>
    </soap:Envelope>
    """
    When method POST
    Then status 200
    * def requestStatus = karate.xmlPath(response, "string(//*[local-name()='RequestStatusResult'])")
    And match requestStatus == expectedStatus

  @readonly @TTP-API-063
  Scenario: TTP-API-063 unknown SOAP operation returns a fault
    Given url ttpBaseUrl
    And path '/soap/contact-service'
    And header Content-Type = 'text/xml'
    And request
    """
    <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
      <soap:Body><UnknownOperation/></soap:Body>
    </soap:Envelope>
    """
    When method POST
    Then status 500
    And match responseHeaders['Content-Type'][0] contains 'text/xml'
    * def faultCode = karate.xmlPath(response, "string(//*[local-name()='faultcode'])")
    And match faultCode == 'soap:Client'

  @readonly @TTP-API-064
  Scenario: TTP-API-064 SOAP service description is available
    Given url ttpBaseUrl
    And path '/soap/contact-service'
    And param wsdl = true
    When method GET
    Then status 200
    And match responseHeaders['Content-Type'][0] contains 'text/xml'
    * def serviceName = karate.xmlPath(response, "string(//*[local-name()='Service'])")
    And match serviceName == 'ContactService'
