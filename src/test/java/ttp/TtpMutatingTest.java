package ttp;

import com.intuit.karate.Results;
import com.intuit.karate.Runner;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

/**
 * Runs the TTP mutating API lane in parallel, part of the default {@code ./gradlew clean test} lane.
 *
 * <p>Karate HTML and per-feature JUnit XML are written to {@code build/karate-reports/mutating}
 * so they sit beside, and do not overwrite, the readonly lane results.</p>
 */
class TtpMutatingTest {

    /**
     * Executes mutating scenarios concurrently, writes per-feature JUnit XML to the lane
     * report directory and fails on any scenario error.
     *
     * <p>Publishes the {@code ttp.lane} system property so that {@code karate-config.js}
     * can tell which credentials the lane requires.</p>
     */
    @Test
    void mutatingApiSuite() {
        System.setProperty("ttp.lane", "mutating");
        Results results = Runner.path("classpath:ttp")
                .tags("@mutating")
                .reportDir("build/karate-reports/mutating")
                .outputJunitXml(true)
                .parallel(5);
        assertEquals(0, results.getFailCount(), results.getErrorMessages());
    }
}
