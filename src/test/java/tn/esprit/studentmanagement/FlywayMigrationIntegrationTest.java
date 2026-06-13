package tn.esprit.studentmanagement;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import tn.esprit.studentmanagement.entities.Student;
import tn.esprit.studentmanagement.repositories.StudentRepository;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@ActiveProfiles("test")
class FlywayMigrationIntegrationTest {

    @Autowired
    private StudentRepository studentRepository;

    @Test
    void contextLoads() {
        assertThat(studentRepository).isNotNull();
    }

    @Test
    void jpaCanPersistEntities() {
        Student student = new Student();
        student.setFirstName("Test");
        student.setLastName("User");
        student.setEmail("test@example.com");

        Student saved = studentRepository.save(student);
        assertThat(saved.getIdStudent()).isNotNull();
    }
}
