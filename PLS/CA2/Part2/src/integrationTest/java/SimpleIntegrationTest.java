import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertTrue;
import payroll.Employee;

public class SimpleIntegrationTest {

    @Test
    void basicIntegrationTest() {
        Employee emp = new Employee("John", "Doe", "Developer");

        String name = emp.getName();

        assert name.equals("John Doe") : "Name should be 'John Doe' but was '" + name + "'";

    }
}
