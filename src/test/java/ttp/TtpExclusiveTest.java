package ttp;

import com.intuit.karate.Results;
import com.intuit.karate.Runner;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

/**
 * Runs the destructive TTP exclusive (reset/seed) API lane in a single thread.
 *
 * <p>Excluded from the default {@code test} task; run it only through the opt-in
 * {@code ./gradlew ttpExclusiveTest} task on a dedicated instance. Reports go to
 * {@code build/karate-reports/exclusive}.</p>
 */
class TtpExclusiveTest {

    /**
     * Executes destructive reset and seed scenarios serially and writes per-feature
     * JUnit XML to the lane report directory.
     *
     * <p>Publishes the {@code ttp.lane} system property so that {@code karate-config.js}
     * requires the TTP login credentials and the admin token from the environment; this
     * lane cannot run against a shared instance without an explicitly supplied token.</p>
     */
    @Test
    void exclusiveApiSuite() {
        System.setProperty("ttp.lane", "exclusive");
        Results results = Runner.path("classpath:ttp")
                .tags("@exclusive")
                .reportDir("build/karate-reports/exclusive")
                .outputJunitXml(true)
                .parallel(1);
        assertEquals(0, results.getFailCount(), results.getErrorMessages());
    }
}
