package ttp;
import com.intuit.karate.Runner;
import org.junit.jupiter.api.Test;
public class CntTest {
    @Test void run(){ Runner.path("classpath:cnt").outputJunitXml(true).parallel(1); }
}
