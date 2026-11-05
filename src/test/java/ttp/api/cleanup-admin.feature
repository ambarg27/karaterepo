Feature: TTP exclusive lane cleanup

  Background:
    * configure afterScenario = null

  Scenario: Restore the baseline dataset
    Given url ttpBaseUrl
    And path '/api/test/reset'
    And header X-Admin-Token = ttpAdminToken
    When method POST
    Then status 200
    And match response.status == 'RESET'
    And match response.dataset == 'baseline'
