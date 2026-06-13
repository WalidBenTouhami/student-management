package tn.esprit.studentmanagement;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.MySQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import tn.esprit.studentmanagement.entities.Department;
import tn.esprit.studentmanagement.entities.Student;
import tn.esprit.studentmanagement.repositories.DepartmentRepository;
import tn.esprit.studentmanagement.repositories.StudentRepository;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@ActiveProfiles("prod")
@Testcontainers(disabledWithoutDocker = true)
class FlywayMigrationIntegrationTest {

    @Container
    static MySQLContainer<?> mysql = new MySQLContainer<>("mysql:8.0")
            .withDatabaseName("studentdb");

    @DynamicPropertySource
    static void configure(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url",
                () -> mysql.getJdbcUrl() + "?allowPublicKeyRetrieval=true&useSSL=false");
        registry.add("spring.datasource.username", mysql::getUsername);
        registry.add("spring.datasource.password", mysql::getPassword);
        registry.add("app.security.api-enabled", () -> "false");
    }

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private DepartmentRepository departmentRepository;

    @Autowired
    private StudentRepository studentRepository;

    @Test
    void flywayCreatesExpectedTables() {
        List<String> tables = jdbcTemplate.queryForList("SHOW TABLES", String.class);
        assertThat(tables).containsExactlyInAnyOrder(
                "departments", "students", "courses", "enrollments", "flyway_schema_history");
    }

    @Test
    void jpaCanPersistEntitiesAgainstFlywaySchema() {
        Department department = new Department();
        department.setName("Computer Science");
        department = departmentRepository.save(department);

        Student student = new Student();
        student.setFirstName("Alice");
        student.setLastName("Martin");
        student.setEmail("alice@example.com");
        student.setDepartment(department);
        student = studentRepository.save(student);

        assertThat(studentRepository.findById(student.getIdStudent()))
                .isPresent()
                .get()
                .extracting(Student::getFirstName, s -> s.getDepartment().getName())
                .containsExactly("Alice", "Computer Science");
    }
}
