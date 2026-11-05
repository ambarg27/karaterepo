Feature: TTP authentication helper

  Scenario: Obtain a demo user token
    Given url ttpBaseUrl
    And path '/api/auth/login'
    And request { username: '#(ttpUser)', password: '#(ttpPassword)' }
    When method POST
    Then status 200
    And match response == read('classpath:ttp/shapes/token.json')
    * def token = response.token
