import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;
import payroll.Employee;

public class SimpleIntegrationTest {

    @Test
    void basicIntegrationTest() {
        Employee emp = new Employee("John", "Doe", "Developer");

        String name = emp.getName();

        assertEquals("John Doe", name, "Name should be 'John Doe'");
    }
}
