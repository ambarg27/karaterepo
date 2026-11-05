Feature: TTP owned entity cleanup

  Scenario: Delete one owned entity when present
    Given url ttpBaseUrl
    And path resourcePath
    And header Authorization = 'Bearer ' + token
    When method DELETE
    Then status 204
