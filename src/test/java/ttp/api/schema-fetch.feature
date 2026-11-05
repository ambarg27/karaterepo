Feature: TTP schema fetch fixture

  Scenario: Fetch a named API schema
    Given url ttpBaseUrl
    And path '/api/schemas/' + schemaName + '.schema.json'
    When method GET
    Then status 200
    And match response == '#object'
    And match response.$schema == 'http://json-schema.org/draft-06/schema#'
