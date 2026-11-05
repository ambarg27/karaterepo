package ttp;

import com.intuit.karate.Results;
import com.intuit.karate.Runner;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

/**
 * Runs the TTP readonly API lane, part of the default {@code ./gradlew clean test} lane.
 *
 * <p>Includes every {@code @readonly} scenario under {@code classpath:ttp}, including the
 * CSV data-driven {@code TTP-API-023} rows. Karate HTML and per-feature JUnit XML are written
 * to {@code build/karate-reports/readonly} so they are not overwritten by the mutating runner
 * and can be published by HyperExecute.</p>
 */
class TtpApiTest {

    /**
     * Executes the requested TTP lane (default tag {@code @readonly}, override with
     * {@code -Dttp.tag}) in parallel, writes per-feature JUnit XML to the lane report
     * directory and fails on any scenario error. {@code ~@exclusive} is always ANDed with the
     * requested tag so a {@code -Dttp.tag} override can never pull the destructive reset/seed
     * scenarios into the default lane.
     *
     * <p>The selected lane is published as the {@code ttp.lane} system property so that
     * {@code karate-config.js} can tell which credentials the lane requires.</p>
     */
    @Test
    void readonlyApiSuite() {
        String tag = System.getProperty("ttp.tag", "@readonly");
        System.setProperty("ttp.lane", tag.replace("@", ""));
        Results results = Runner.path("classpath:ttp")
                .tags(tag, "~@exclusive")
                .reportDir("build/karate-reports/readonly")
                .outputJunitXml(true)
                .parallel(5);
        assertEquals(0, results.getFailCount(), results.getErrorMessages());
    }
}
