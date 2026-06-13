package tn.esprit.studentmanagement;

import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.*;
import org.springframework.test.context.ActiveProfiles;
import tn.esprit.studentmanagement.dto.*;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(
    webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT
)
@ActiveProfiles("test")
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class StudentManagementE2ETest {

    @Autowired
    private TestRestTemplate restTemplate;

    private static Long departmentId;
    private static Long studentId;
    private static Long courseId;

    @Test
    @Order(1)
    void testCreateDepartment() {
        DepartmentDTO department = new DepartmentDTO();
        department.setName("Computer Science");
        department.setLocation("Building A");

        ResponseEntity<DepartmentDTO> response = restTemplate.postForEntity(
            "/api/departments", department, DepartmentDTO.class);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(java.util.Objects.requireNonNull(response.getBody()).getIdDepartment()).isNotNull();
        departmentId = java.util.Objects.requireNonNull(response.getBody()).getIdDepartment();
    }

    @Test
    @Order(2)
    void testCreateStudent() {
        StudentDTO student = new StudentDTO();
        student.setFirstName("John");
        student.setLastName("Doe");
        student.setEmail("john@test.com");
        student.setDepartmentId(departmentId);

        ResponseEntity<StudentDTO> response = restTemplate.postForEntity(
            "/api/students", student, StudentDTO.class);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(java.util.Objects.requireNonNull(response.getBody()).getIdStudent()).isNotNull();
        studentId = java.util.Objects.requireNonNull(response.getBody()).getIdStudent();
    }

    @Test
    @Order(3)
    void testCreateCourse() {
        CourseDTO course = new CourseDTO();
        course.setName("Spring Boot");
        course.setCode("SB101");
        course.setCredit(5);

        ResponseEntity<CourseDTO> response = restTemplate.postForEntity(
            "/api/courses", course, CourseDTO.class);

        if (response.getStatusCode() != HttpStatus.CREATED) {
            System.err.println("Response body: " + restTemplate.postForEntity("/api/courses", course, String.class).getBody());
        }

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(java.util.Objects.requireNonNull(response.getBody()).getIdCourse()).isNotNull();
        courseId = java.util.Objects.requireNonNull(response.getBody()).getIdCourse();
    }

    @Test
    @Order(4)
    void testCreateEnrollment() {
        EnrollmentDTO enrollment = new EnrollmentDTO();
        enrollment.setStudentId(studentId);
        enrollment.setCourseId(courseId);
        enrollment.setStatus("ACTIVE");
        enrollment.setEnrollmentDate(java.time.LocalDate.now());

        ResponseEntity<EnrollmentDTO> response = restTemplate.postForEntity(
            "/api/enrollments", enrollment, EnrollmentDTO.class);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(java.util.Objects.requireNonNull(response.getBody()).getIdEnrollment()).isNotNull();
    }

    @Test
    @Order(5)
    void testGetStudent() {
        ResponseEntity<StudentDTO> response = restTemplate.getForEntity(
            "/api/students/" + studentId, StudentDTO.class);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(java.util.Objects.requireNonNull(response.getBody()).getIdStudent()).isEqualTo(studentId);
    }
}
