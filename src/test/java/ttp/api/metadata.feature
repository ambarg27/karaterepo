Feature: TTP metadata fixture

  Scenario: Select valid request metadata
    Given url ttpBaseUrl
    And path '/api/metadata/tiers'
    When method GET
    Then status 200
    * def tier = response.items[0].name
    Given path '/api/metadata/options'
    When method GET
    Then status 200
    * def option = response.items[0].name
