package ttp;
import com.intuit.karate.Runner;
import org.junit.jupiter.api.Test;
public class Cnt7Test {
    @Test void run(){ Runner.path("classpath:cnt7").outputJunitXml(true).parallel(1); }
}
