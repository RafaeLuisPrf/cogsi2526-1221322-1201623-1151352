import payroll.Employee;


public class TestMyClass {

    public static void main(String[] args) {
        Employee emp = new Employee("John", "Doe", "Developer");

        String name = emp.getName();

        assert name.equals("John Doe") : "Name should be 'John Doe' but was '" + name + "'";

    }

}


