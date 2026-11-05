# Static WAFW Karate

## What this suite targets

This repository contains Karate API tests for the TTP test app. The app serves the
`/playground` widget catalog UI and the demo/domain application at:

- `/dashboard`
- `/contacts`
- `/items`
- `/requests`
- `/requests/new`
- `/testing`

Its REST APIs are under `/api` and its SOAP APIs are under `/soap`. This Karate
repository covers the API side: REST, SOAP, error contracts, authentication,
health, metadata, and domain operations.

## Default command

`./gradlew clean test` runs **only the TTP API suites**:

| Runner | Lane | Scenarios executed |
| --- | --- | ---: |
| `ttp.TtpApiTest` | `@readonly` (41 canonical ids + 5 data-driven `TTP-API-023` rows) | 46 |
| `ttp.TtpMutatingTest` | `@mutating` | 12 |
| **Default total** |  | **58** |

`./gradlew ttpTest` is an alias for the same default lane. The destructive
reset/seed runner `ttp.TtpExclusiveTest` (6 scenarios) is **not** part of the
default command; run it only through the opt-in task:

```bash
./gradlew ttpExclusiveTest
```

The legacy in-repo `hello-karate` sample (Spring Boot `/api/hello` and
`/api/person` app, `karate.KarateTests`, `karate.TestParallel` and the
Spring controller/service unit tests) has been removed. Its CSV data-driven
Scenario Outline was rewritten against TTP as
`ttp/api/contacts-data-driven.feature` (see below).

## Target environments

The Dev deployment is the default:

| Environment | Base URL |
| --- | --- |
| `dev` (default) | `https://test-app-te01-dev.apps.lew09.ocp.nonprod.wellsfargo.net` |
| `uat` | `https://test-app-te01-uat.apps.lew09.ocp.nonprod.wellsfargo.net` |
| `local` (opt-in only) | `http://localhost:8080` |

Select an environment with either `-Denvironment=dev|uat|local` or
`-Dkarate.env=dev|uat|local`. A base URL override takes precedence over the
environment map:

```bash
./gradlew clean test -Denvironment=dev
./gradlew clean test -Dkarate.env=uat
./gradlew clean test -Dkarate.env=local
./gradlew clean test -Dttp.baseurl=http://127.0.0.1:9090
```

Local use is never selected implicitly. The default without any environment
flags is the Dev deployment. An unknown environment name fails the run
immediately.

## TTP credentials

No credential value is committed to this repository. `karate-config.js` reads
each one from a system property first and then from an environment variable, and
there is no default for any of them:

| Config key | System property | Environment variable | Needed by |
| --- | --- | --- | --- |
| `ttpUser` | `-Dttp.user` | `TTP_USER` | every TTP lane |
| `ttpPassword` | `-Dttp.password` | `TTP_PASSWORD` | every TTP lane |
| `ttpAdminToken` | `-Dttp.admintoken` | `TTP_ADMIN_TOKEN` | the exclusive lane only |

A run started without the login credentials, or an exclusive run without the
admin token, fails immediately with a message naming the missing variable. Export
them before running:

```bash
export TTP_USER=<TTP demo user>
export TTP_PASSWORD=<TTP demo password>
./gradlew clean test
```

In HyperExecute the credentials come from the `TTP_USER` / `TTP_PASSWORD`
secrets.

## TLS

These suites run against WF-inspected OCP routes, whose certificate chain is
re-signed by the inspecting proxy, so certificate verification may have to be
relaxed to reach Dev or UAT from a given runner. It is configurable and off by
default:

| System property | Environment variable | Default |
| --- | --- | --- |
| `-Dttp.ignoretlserrors=true` | `TTP_IGNORE_TLS_ERRORS=true` | unset (verification enabled) |

Enable it only for these TTP test environments. It must stay off for anything
else, because with it set the suite accepts any certificate and cannot detect an
interception it did not expect.

## Canonical test-plan coverage

This repository owns the complete API set from the TTP `docs/TEST-PLAN.md`.
There is exactly one lane-tagged Karate scenario for each API id:

| Group | Lane | IDs | Count |
| --- | --- | --- | ---: |
| Suite 1: health and harness | `readonly` | `TTP-API-001`, `TTP-API-002`, `TTP-API-003`, `TTP-API-004`, `TTP-API-005`, `TTP-API-006` | 6 |
| Suite 2: authentication | `readonly` | `TTP-API-010`, `TTP-API-011`, `TTP-API-012`, `TTP-API-013`, `TTP-API-014`, `TTP-API-015`, `TTP-API-016` | 7 |
| Suite 3: domain reads | `readonly` | `TTP-API-020`, `TTP-API-021`, `TTP-API-022`, `TTP-API-023`, `TTP-API-024`, `TTP-API-025`, `TTP-API-026`, `TTP-API-027`, `TTP-API-028`, `TTP-API-029`, `TTP-API-030`, `TTP-API-031`, `TTP-API-032` | 13 |
| Suite 4: domain writes and lifecycle | `mutating` | `TTP-API-040`, `TTP-API-041`, `TTP-API-042`, `TTP-API-043`, `TTP-API-044`, `TTP-API-045`, `TTP-API-046`, `TTP-API-047`, `TTP-API-048`, `TTP-API-049`, `TTP-API-050`, `TTP-API-051` | 12 |
| Suite 5: deterministic errors and SOAP | `readonly` | `TTP-API-060`, `TTP-API-061`, `TTP-API-062`, `TTP-API-063`, `TTP-API-064` | 5 |
| Suite 6: reset and seed | `exclusive` | `TTP-API-070`, `TTP-API-071`, `TTP-API-072`, `TTP-API-073`, `TTP-API-074`, `TTP-API-075` | 6 |
| Suite 7: fake CS-PingFed OIDC/PKCE | `readonly` | `TTP-OIDC-001`, `TTP-OIDC-002`, `TTP-OIDC-003`, `TTP-OIDC-004`, `TTP-OIDC-005`, `TTP-OIDC-006` | 6 |
| Suite 14: API documentation and platform | `readonly` | `TTP-API-080`, `TTP-API-081`, `TTP-API-082`, `TTP-API-083` | 4 |
| **Total API scenarios** |  |  | **59** |

The per-group count is **6 + 7 + 13 + 12 + 5 + 6 + 6 + 4 = 59**. The
default command executes the 53 readonly + mutating ids; the 6 exclusive ids
run through `./gradlew ttpExclusiveTest`.

### Data-driven sample

`ttp/api/contacts-data-driven.feature` is a Karate `Scenario Outline` whose
`Examples:` are read from `ttp/data/contacts.csv`. Each of the 5 CSV rows (the
seeded baseline contacts `c-1` through `c-5`) is an independently reported
`@readonly @TTP-API-023 @data-driven` scenario that reads the contact and
checks it against the contact schema and the row's expected values. It
replaces the legacy `hello/TestDataWithParameters.feature` (5 CSV rows against
the removed `/api/hello` sample), so row-level cardinality is unchanged (5 → 5).
Run it alone with `./gradlew test -Dttp.tag=@data-driven`.

The UI set (`TTP-UI-001` through `TTP-UI-006`, `010` through `020`,
`030` through `040`, and `050` through `053`) is **0/32** in this repository,
and the Playground set (`TTP-PG-001` through `TTP-PG-019`) is **0/19**.
Those sets are intentionally excluded because this is the API-first Karate
framework and it has no browser driver; the UI frameworks in this effort own
those scenarios.

## Prerequisites

- Java 11. `sourceCompatibility` remains 11 and HyperExecute pins Java 11.
- Gradle Wrapper 8.14.4. Use `./gradlew` rather than a system Gradle install.
- Access to POD-B2 Artifactory.
- Artifactory resolver credentials in `~/.gradle/gradle.properties`:

```properties
systemProp.gradle.wrapperUser=DEVIN_JFRG_SVC_PROD
systemProp.gradle.wrapperPassword=<POD-B2 Artifactory key>
artifactoryResolverUsername=DEVIN_JFRG_SVC_PROD
artifactoryResolverPassword=<POD-B2 Artifactory key>
```

The wrapper distribution and Maven dependencies resolve from the internal
POD-B2 repositories configured by this project. Do not add public registries.

## Readonly API suites

The `ttp` test package implements the readonly API rows from the TTP
`docs/TEST-PLAN.md` contract:

- Suite 1: `TTP-API-001` through `TTP-API-006`
- Suite 2: `TTP-API-010` through `TTP-API-016`
- Suite 3: `TTP-API-020` through `TTP-API-032`
- Suite 5: `TTP-API-060` through `TTP-API-064`

Every scenario is tagged `@readonly` and its plan id is also a scenario tag.
These scenarios perform reads only and are isolated from one another, so the
readonly lane can run concurrently against a shared baseline instance:

```bash
./gradlew test -Dttp.tag=@readonly
```

Run one plan row alone with, for example,
`./gradlew test --tests ttp.TtpApiTest -Dttp.tag=@TTP-API-020`. The `ttp.tag`
property selects the `ttp.TtpApiTest` scenarios and defaults to `@readonly`;
`@exclusive` scenarios are always excluded from it (run them with
`./gradlew ttpExclusiveTest`).

## Mutating and exclusive lanes

Suite 4 (`TTP-API-040` through `TTP-API-051`) uses the `@mutating` lane. Each
scenario owns the contacts and items it creates and deletes them during
failure-safe teardown. Created requests are driven to `Cancelled` when their
lifecycle permits cancellation; cancelled requests remain in the in-memory
store because the API intentionally exposes lifecycle operations rather than
request deletion. Requests driven to `Completed` are also terminal and remain
until reset. The mutating lane does not assert request-list totals or global
counts, and two mutating runs can share an instance concurrently:

```bash
./gradlew test --tests ttp.TtpMutatingTest
```

Suite 6 (`TTP-API-070` through `TTP-API-075`) uses the `@exclusive` lane. Reset
and seed are global and destructive, so these scenarios require an instance
dedicated to the lane or a maintenance window and run in a single-threaded
runner:

```bash
./gradlew ttpExclusiveTest
```

Every exclusive scenario restores the baseline dataset during teardown. It also
requires `TTP_ADMIN_TOKEN`, and must be pointed at an instance dedicated to the
lane with `-Dttp.baseurl`:

```bash
TTP_ADMIN_TOKEN=<token> ./gradlew ttpExclusiveTest \
  -Dttp.baseurl=https://<dedicated-ttp-instance>
```

The default `./gradlew test` task excludes `ttp.TtpExclusiveTest`, so reset and
reseed never run unless this task is requested explicitly.

## HyperExecute

`HyperExecute.yaml` discovers exactly `ttp.TtpApiTest` and
`ttp.TtpMutatingTest` and runs each with
`gradle test --tests "$test" "-Dkarate.env=${KARATE_ENV:-dev}"`. Both
arguments are quoted so `$test` and the `-D` system property each reach Gradle
as a single argument. The environment is chosen by the job through
`KARATE_ENV` (Dev when unset); no URL is baked into the YAML. Credentials are
referenced by secret name only (`TTP_USER`, `TTP_PASSWORD`, and
`TTP_ADMIN_TOKEN` for a separate exclusive job). Results are published by the
HyperExecute platform-managed result logger (`vars.platform_managed_resultlogger`),
which picks up the per-feature Karate JUnit XML files (one testcase per
scenario) under `build/karate-reports/` (the `readonly` and `mutating` lanes),
and the Karate HTML reports are uploaded as their own artefact.

The exclusive lane is only described in a comment in that file and must be
enabled only in a separate job against a dedicated instance, because reset and
seed are global and would destroy other clients' data on the shared Dev or UAT
deployment.

## Known plan deviations

Two plan rows intentionally avoid fixed baseline totals:

- `TTP-API-026` verifies that every filtered item has
  `reviewStatus=NeedsReview` and that seeded `i-3` and `i-8` are present,
  without asserting list length.
- `TTP-API-030` compares summary counts to list responses fetched in the same
  scenario and verifies that request status counts sum to the request-list total.

The SOAP service description row has an application-specific deviation:

- `TTP-API-064` validates the app's `ServiceDescription` document, which is the
  service description exposed by the TTP app rather than a real WSDL document.

The OIDC JWKS row has an application-specific deviation:

- `TTP-OIDC-006` verifies that `/pf/JWKS` returns a `keys` array, but does not
  require a key because the app signs tokens with symmetric HS256 and publishes
  no public key material.

The following plan rows are documented but not implemented in this lane:

- `TTP-API-084` requires a separately configured `CORS_ALLOWED_ORIGINS`
  instance; the shared/local baseline is not started with that configuration.
- `TTP-API-085` requires a separately configured `AUTH_REQUIRED=false` instance;
  it must not be asserted against a shared baseline instance.
- `TTP-A11Y-001` and `TTP-A11Y-002` require an accessibility scanner, which this
  API-only Karate suite does not provide.

## Reports

After a test run, reports are written to:

- `build/karate-reports/<lane>` — detailed Karate HTML and per-feature
  JUnit XML for the `readonly`, `mutating` and (opt-in) `exclusive` lanes
- `build/reports` — Gradle and test reports
- `build/test-results` — JUnit XML and other test result files

Compile without executing tests with:

```bash
./gradlew clean build -x test
```
