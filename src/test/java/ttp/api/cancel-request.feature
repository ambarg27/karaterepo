Feature: TTP request cancellation

  Scenario: Cancel one owned request
    Given url ttpBaseUrl
    And path '/api/requests/' + requestId + '/cancel'
    And header Authorization = 'Bearer ' + token
    When method POST
    Then status 200
    And match response.status == 'Cancelled'
