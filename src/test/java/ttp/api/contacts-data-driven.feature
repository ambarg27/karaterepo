@readonly
Feature: TTP API data-driven contact lookup

  # Karate data-driven sample: every row of ttp/data/contacts.csv becomes an
  # independently reported scenario that reads a seeded baseline contact.
  Background:
    * def auth = callonce read('classpath:ttp/auth.feature')

  @readonly @TTP-API-023 @data-driven
  Scenario Outline: TTP-API-023 data-driven GET /api/contacts/<contactId> returns <firstName> <lastName>
    Given url ttpBaseUrl
    And path '/api/contacts', '<contactId>'
    And header Authorization = 'Bearer ' + auth.token
    When method GET
    Then status 200
    And match response == read('classpath:ttp/shapes/contact.json')
    And match response contains { id: '<contactId>', firstName: '<firstName>', lastName: '<lastName>', status: '<status>' }

    Examples:
      | read('classpath:ttp/data/contacts.csv') |
