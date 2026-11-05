@readonly
Feature: TTP API documentation and platform behavior

  @readonly @TTP-API-080
  Scenario: TTP-API-080 OpenAPI describes the exercised API surfaces
    Given url ttpBaseUrl
    And path '/api/openapi.json'
    When method GET
    Then status 200
    And match response.openapi == '#regex ^3\\.0\\.[0-9]+$'
    * def exercisedPaths =
      """
      [
        { path: '/api/health/live', method: 'get' },
        { path: '/api/health/ready', method: 'get' },
        { path: '/api/auth/login', method: 'post' },
        { path: '/api/auth/issue-token', method: 'post' },
        { path: '/api/ping', method: 'get' },
        { path: '/api/summary', method: 'get' },
        { path: '/api/metadata/categories', method: 'get' },
        { path: '/api/metadata/tiers', method: 'get' },
        { path: '/api/metadata/statuses', method: 'get' },
        { path: '/api/metadata/options', method: 'get' },
        { path: '/api/metadata/review-statuses', method: 'get' },
        { path: '/api/contacts', method: 'get' },
        { path: '/api/contacts', method: 'post' },
        { path: '/api/contacts/{id}', method: 'get' },
        { path: '/api/contacts/{id}', method: 'put' },
        { path: '/api/contacts/{id}', method: 'delete' },
        { path: '/api/contacts/{id}/items', method: 'get' },
        { path: '/api/items', method: 'get' },
        { path: '/api/items', method: 'post' },
        { path: '/api/items/{id}', method: 'get' },
        { path: '/api/items/{id}', method: 'put' },
        { path: '/api/items/{id}', method: 'delete' },
        { path: '/api/requests', method: 'get' },
        { path: '/api/requests', method: 'post' },
        { path: '/api/requests/availability', method: 'post' },
        { path: '/api/requests/quote', method: 'post' },
        { path: '/api/requests/{id}', method: 'get' },
        { path: '/api/requests/{id}/submit', method: 'post' },
        { path: '/api/requests/{id}/start', method: 'post' },
        { path: '/api/requests/{id}/complete', method: 'post' },
        { path: '/api/requests/{id}/cancel', method: 'post' },
        { path: '/api/test/reset', method: 'post' },
        { path: '/api/test/seed', method: 'post' },
        { path: '/api/errors/401', method: 'get' },
        { path: '/api/errors/404', method: 'get' },
        { path: '/api/errors/500', method: 'get' },
        { path: '/api/errors/validation', method: 'get' },
        { path: '/api/echo', method: 'post' },
        { path: '/api/headers', method: 'get' },
        { path: '/api/delay/{seconds}', method: 'get' },
        { path: '/api/download/contacts.csv', method: 'get' },
        { path: '/api/download/items.csv', method: 'get' },
        { path: '/soap/contact-service', method: 'get' },
        { path: '/soap/contact-service', method: 'post' },
        { path: '/.well-known/openid-configuration', method: 'get' },
        { path: '/as/authorization.oauth2', method: 'get' },
        { path: '/pf/login', method: 'post' },
        { path: '/as/token.oauth2', method: 'post' },
        { path: '/idp/userinfo.openid', method: 'get' },
        { path: '/pf/JWKS', method: 'get' },
        { path: '/api/openapi.json', method: 'get' }
      ]
      """
    * eval exercisedPaths.forEach(function(entry) { if (!response.paths[entry.path] || !response.paths[entry.path][entry.method]) karate.fail('Missing OpenAPI operation: ' + entry.method + ' ' + entry.path); })

  @readonly @TTP-API-081
  Scenario: TTP-API-081 Swagger UI exposes the API tag groups
    Given url ttpBaseUrl
    And path '/api/docs'
    When method GET
    Then status 200
    And match responseHeaders['Content-Type'][0] contains 'text/html'
    And match response contains 'swagger-ui'
    Given path '/api/openapi.json'
    When method GET
    Then status 200
    And match response.tags[*].name contains ['auth', 'contacts', 'errors', 'health', 'items', 'metadata', 'oidc', 'requests', 'soap', 'test-control', 'utilities']

  @readonly @TTP-API-082
  Scenario: TTP-API-082 every suite schema is served as draft six JSON
    * def schemaNames = ['error', 'contact', 'contactPage', 'health', 'item', 'request', 'summary', 'token']
    * eval schemaNames.forEach(function(schemaName) { karate.call('classpath:ttp/api/schema-fetch.feature', { schemaName: schemaName }); })

  @readonly @TTP-API-083
  Scenario: TTP-API-083 unknown API routes return JSON not SPA HTML
    Given url ttpBaseUrl
    And path '/api/does-not-exist'
    When method GET
    Then status 404
    And match responseHeaders['Content-Type'][0] contains 'application/json'
    And match response == read('classpath:ttp/shapes/error.json')
    And match response.errorCode == 'NOT_FOUND'
