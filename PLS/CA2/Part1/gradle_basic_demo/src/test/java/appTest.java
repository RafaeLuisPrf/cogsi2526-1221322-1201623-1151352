import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
import basic_demo.App;
 
 
public class appTest{
	 
	    @Test
	    public void testApp(){
	        App app = new App();
	        String greeting = app.getGreeting();
	        assertTrue(greeting.contains("Welcome to a \"Multi-User Chat Application\""));					    
	    }	     
}
