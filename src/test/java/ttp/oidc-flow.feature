Feature: TTP OIDC PKCE flow fixture

  Scenario: Create a fresh authorization code flow
    * configure followRedirects = false
    * def clientId = 'karate-ttp-client'
    * def redirectUri = ttpBaseUrl + '/oidc/callback'
    * def state = java.util.UUID.randomUUID().toString()
    * def codeVerifier = java.util.UUID.randomUUID().toString().replace(/-/g, '')
    * def MessageDigest = Java.type('java.security.MessageDigest')
    * def Base64 = Java.type('java.util.Base64')
    * def digest = MessageDigest.getInstance('SHA-256').digest(codeVerifier.getBytes('US-ASCII'))
    * def codeChallenge = Base64.getUrlEncoder().withoutPadding().encodeToString(digest)
    * def authorizeParams =
      """
      {
        acr_values: 'form',
        client_id: '#(clientId)',
        code_challenge: '#(codeChallenge)',
        code_challenge_method: 'S256',
        redirect_uri: '#(redirectUri)',
        response_mode: 'query',
        response_type: 'code',
        scope: 'openid profile email',
        state: '#(state)'
      }
      """

    Given url ttpBaseUrl
    And path '/.well-known/openid-configuration'
    When method GET
    Then status 200
    * def discovery = response
    * def authorizationEndpoint = discovery.authorization_endpoint
    * def tokenEndpoint = discovery.token_endpoint
    * def userinfoEndpoint = discovery.userinfo_endpoint
    * def jwksUri = discovery.jwks_uri

    Given url ttpBaseUrl
    And path '/as/authorization.oauth2'
    And params authorizeParams
    When method GET
    Then status 200
    * def authorizeStatus = responseStatus
    * def authorizeContentType = responseHeaders['Content-Type'][0]
    * def authorizeHtml = response
    * def formAction = karate.extract(authorizeHtml, 'action="([^"]+)"', 1)
    * match formAction == '#string'
    * def formActionUrl = ttpBaseUrl + formAction

    Given url formActionUrl
    And form field pf.username = ttpUser
    And form field pf.pass = ttpPassword
    When method POST
    Then status 302
    * def loginStatus = responseStatus
    * def locationHeaders = responseHeaders['Location'] || responseHeaders['location']
    * def loginLocation = locationHeaders[0]
    * def rawCode = karate.extract(loginLocation, '[?&]code=([^&]+)', 1)
    * def rawState = karate.extract(loginLocation, '[?&]state=([^&]+)', 1)
    * def code = decodeURIComponent(rawCode)
    * def returnedState = decodeURIComponent(rawState)
    * def tokenEndpointPath = '/as/token.oauth2'
    * def userinfoEndpointPath = '/idp/userinfo.openid'
    * def jwksPath = '/pf/JWKS'
