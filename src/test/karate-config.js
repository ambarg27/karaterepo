function fn() {
  var env = karate.env; // get java system property 'karate.env'
  karate.log('karate.env system property was:', env);

  // Deployments of the TTP test app. Dev is the default; 'local' is opt-in only
  // and is never selected unless it is requested explicitly with
  // -Dkarate.env=local or -Denvironment=local.
  var ttpEnvironments = {
    dev: 'https://test-app-te01-dev.apps.lew09.ocp.nonprod.wellsfargo.net',
    uat: 'https://test-app-te01-uat.apps.lew09.ocp.nonprod.wellsfargo.net',
    local: 'http://localhost:8080'
  };
  var selectedTtpEnvironment = karate.properties['environment'] || env || 'dev';
  var ttpOverride = karate.properties['ttp.baseurl'];
  if (!ttpOverride && !ttpEnvironments[selectedTtpEnvironment]) {
    throw new Error("Unknown TTP environment '" + selectedTtpEnvironment + "'. Valid values: dev, uat, local");
  }
  var resolvedBaseUrl = ttpOverride || ttpEnvironments[selectedTtpEnvironment];
  karate.log('resolved TTP environment:', selectedTtpEnvironment, 'baseUrl:', resolvedBaseUrl);

  // Credentials are never committed. They are read from a system property first and
  // then from an environment variable, and there is no default value for any of them.
  var systemEnvironment = Java.type('java.lang.System');
  var resolveCredential = function(propertyName, variableName) {
    var value = karate.properties[propertyName];
    if (!value) {
      value = systemEnvironment.getenv(variableName);
    }
    return value ? value : null;
  };
  var requireCredential = function(propertyName, variableName) {
    var value = resolveCredential(propertyName, variableName);
    if (!value) {
      throw new Error('TTP credential is not configured: set the ' + variableName +
        ' environment variable or -D' + propertyName +
        '. See the "TTP credentials" section of README.md.');
    }
    return value;
  };

  // The ttp.* JUnit runners publish the lane they are about to execute; only the
  // exclusive (reset/seed) lane needs the admin token.
  var ttpLane = karate.properties['ttp.lane'];
  var ttpLaneIsExclusive = ttpLane != null && ttpLane.indexOf('exclusive') != -1;
  var readAdminToken = ttpLaneIsExclusive ? requireCredential : resolveCredential;

  var config = {
    ttpBaseUrl: resolvedBaseUrl,
    ttpUser: requireCredential('ttp.user', 'TTP_USER'),
    ttpPassword: requireCredential('ttp.password', 'TTP_PASSWORD'),
    ttpAdminToken: readAdminToken('ttp.admintoken', 'TTP_ADMIN_TOKEN')
  };

  // Certificate verification stays on by default. The WF inspected OCP routes can
  // present an intercepted chain that a stock JDK truststore rejects, so verification
  // can be relaxed for those test environments only, never for anything else. See the
  // "TLS" section of README.md.
  var ignoreTlsErrors = karate.properties['ttp.ignoretlserrors'] ||
    systemEnvironment.getenv('TTP_IGNORE_TLS_ERRORS');
  if (ignoreTlsErrors == 'true') {
    karate.log('TTP_IGNORE_TLS_ERRORS is set: certificate verification is disabled');
    karate.configure('ssl', true);
  }

  // don't waste time waiting for a connection or if servers don't respond within 5 seconds
  karate.configure('connectTimeout', 5000);
  karate.configure('readTimeout', 5000);
  return config;
}
