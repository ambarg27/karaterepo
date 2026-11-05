@readonly
Feature: TTP API fake CS-PingFed OIDC and PKCE

  @readonly @TTP-OIDC-001
  Scenario: TTP-OIDC-001 discovery document advertises the PKCE endpoints
    * def flow = call read('classpath:ttp/oidc-flow.feature')
    * match flow.discovery.issuer == '#regex ^https?://.+'
    * match flow.discovery.authorization_endpoint == '#regex ^https?://.+/as/authorization\\.oauth2$'
    * match flow.discovery.token_endpoint == '#regex ^https?://.+/as/token\\.oauth2$'
    * match flow.discovery.userinfo_endpoint == '#regex ^https?://.+/idp/userinfo\\.openid$'
    * match flow.discovery.jwks_uri == '#regex ^https?://.+/pf/JWKS$'

  @readonly @TTP-OIDC-002
  Scenario: TTP-OIDC-002 authorize renders the sorted PKCE sign-on form
    * def flow = call read('classpath:ttp/oidc-flow.feature')
    * match flow.authorizeStatus == 200
    * match flow.authorizeContentType contains 'text/html'
    * match flow.authorizeParams.code_challenge_method == 'S256'
    * match flow.authorizeParams.response_mode == 'query'
    * match flow.authorizeParams.acr_values == 'form'
    * match flow.authorizeHtml contains 'name="pf.username"'
    * match flow.authorizeHtml contains 'name="pf.pass"'
    * match flow.formAction == '#regex ^/pf/login\\?rid=[0-9a-f-]+$'
    * assert !flow.formAction.contains('&amp;')

  @readonly @TTP-OIDC-003
  Scenario: TTP-OIDC-003 login redirects with a code and echoed state
    * def flow = call read('classpath:ttp/oidc-flow.feature')
    * match flow.loginStatus == 302
    * assert flow.loginLocation.startsWith(flow.redirectUri)
    * assert flow.loginLocation.contains('code=')
    * assert flow.loginLocation.contains('state=')
    * match flow.returnedState == flow.state

  @readonly @TTP-OIDC-004
  Scenario: TTP-OIDC-004 token exchange accepts the matching PKCE verifier
    * def flow = call read('classpath:ttp/oidc-flow.feature')
    Given url ttpBaseUrl
    And path flow.tokenEndpointPath
    And header Content-Type = 'application/x-www-form-urlencoded'
    And form field grant_type = 'authorization_code'
    And form field code = flow.code
    And form field code_verifier = flow.codeVerifier
    And form field client_id = flow.clientId
    And form field redirect_uri = flow.redirectUri
    When method POST
    Then status 200
    And match responseHeaders['Content-Type'][0] contains 'application/json'
    And match response.access_token == '#string'
    And match response.token_type == 'Bearer'
    And match response.expires_in == '#number'
    And match response.scope == '#string'
    And match response.id_token == '#string'

  @readonly @TTP-OIDC-005
  Scenario: TTP-OIDC-005 rejects replayed codes and mismatched PKCE verifiers
    * def flow = call read('classpath:ttp/oidc-flow.feature')
    Given url ttpBaseUrl
    And path flow.tokenEndpointPath
    And header Content-Type = 'application/x-www-form-urlencoded'
    And form field grant_type = 'authorization_code'
    And form field code = flow.code
    And form field code_verifier = flow.codeVerifier
    And form field client_id = flow.clientId
    And form field redirect_uri = flow.redirectUri
    When method POST
    Then status 200
    Given url ttpBaseUrl
    And path flow.tokenEndpointPath
    And header Content-Type = 'application/x-www-form-urlencoded'
    And form field grant_type = 'authorization_code'
    And form field code = flow.code
    And form field code_verifier = flow.codeVerifier
    And form field client_id = flow.clientId
    And form field redirect_uri = flow.redirectUri
    When method POST
    Then status 400
    And match response.errorCode == 'VALIDATION_ERROR'
    And match response.details[*].field contains 'code'

    * def freshFlow = call read('classpath:ttp/oidc-flow.feature')
    Given url ttpBaseUrl
    And path freshFlow.tokenEndpointPath
    And header Content-Type = 'application/x-www-form-urlencoded'
    And form field grant_type = 'authorization_code'
    And form field code = freshFlow.code
    And form field code_verifier = 'incorrect-verifier'
    And form field client_id = freshFlow.clientId
    And form field redirect_uri = freshFlow.redirectUri
    When method POST
    Then status 400
    And match response.errorCode == 'VALIDATION_ERROR'
    And match response.details[*].field contains 'code_verifier'

  @readonly @TTP-OIDC-006
  Scenario: TTP-OIDC-006 userinfo returns the subject and JWKS exposes an empty key set
    * def flow = call read('classpath:ttp/oidc-flow.feature')
    Given url ttpBaseUrl
    And path flow.tokenEndpointPath
    And header Content-Type = 'application/x-www-form-urlencoded'
    And form field grant_type = 'authorization_code'
    And form field code = flow.code
    And form field code_verifier = flow.codeVerifier
    And form field client_id = flow.clientId
    And form field redirect_uri = flow.redirectUri
    When method POST
    Then status 200
    * def accessToken = response.access_token
    Given url ttpBaseUrl
    And path flow.userinfoEndpointPath
    And header Authorization = 'Bearer ' + accessToken
    When method GET
    Then status 200
    And match response.sub == ttpUser
    And match response.groups == '#array'
    And assert response.groups.length > 0
    And match each response.groups == '#string'
    Given url ttpBaseUrl
    And path flow.jwksPath
    When method GET
    Then status 200
    # HS256 tokens have no public key material to publish, so the JWKS keys array is empty.
    And match response.keys == '#array'
