package ttp;
import com.intuit.karate.Runner;
import org.junit.jupiter.api.Test;
public class Big1000KarateTest {
    @Test void run(){ Runner.path("classpath:big1000").outputJunitXml(true).parallel(5); }
}
