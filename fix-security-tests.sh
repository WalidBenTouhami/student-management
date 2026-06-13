#!/bin/bash
# ============================================================================
# NINJA SECURITY DISABLER - Force désactivation de Spring Security pour les tests
# ============================================================================

set -e

echo "🔧 Création de la configuration de test sans sécurité..."

# 1. Créer une configuration de test qui désactive la sécurité
cat > src/test/java/tn/esprit/studentmanagement/TestSecurityConfig.java << 'EOF'
package tn.esprit.studentmanagement;

import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;

@TestConfiguration
public class TestSecurityConfig {

    @Bean
    @Primary
    public SecurityFilterChain testSecurityFilterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable())
            .authorizeHttpRequests(auth -> auth
                .anyRequest().permitAll()
            );
        return http.build();
    }
}
EOF

echo "✅ TestSecurityConfig créé"

# 2. Modifier StudentManagementE2ETest pour utiliser cette configuration
cat > src/test/java/tn/esprit/studentmanagement/StudentManagementE2ETest.java << 'EOF'
package tn.esprit.studentmanagement;

import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.context.annotation.Import;
import org.springframework.http.*;
import org.springframework.test.context.ActiveProfiles;
import tn.esprit.studentmanagement.dto.*;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
@Import(TestSecurityConfig.class)  // ← Importe la config sans sécurité
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class StudentManagementE2ETest {

    @Autowired
    private TestRestTemplate restTemplate;

    private static Long departmentId;
    private static Long studentId;
    private static Long courseId;
    private static Long enrollmentId;

    @Test
    @Order(1)
    void testCreateDepartment() {
        DepartmentDTO department = new DepartmentDTO();
        department.setName("Computer Science");
        department.setLocation("Building A");
        department.setPhone("+123456789");
        department.setHead("Dr. Smith");

        ResponseEntity<DepartmentDTO> response = restTemplate.postForEntity(
            "/api/departments", department, DepartmentDTO.class);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(response.getBody().getIdDepartment()).isNotNull();
        departmentId = response.getBody().getIdDepartment();
    }

    @Test
    @Order(2)
    void testCreateStudent() {
        StudentDTO student = new StudentDTO();
        student.setFirstName("John");
        student.setLastName("Doe");
        student.setEmail("john.doe@example.com");
        student.setPhone("+123456789");
        student.setDepartmentId(departmentId);

        ResponseEntity<StudentDTO> response = restTemplate.postForEntity(
            "/api/students", student, StudentDTO.class);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(response.getBody().getIdStudent()).isNotNull();
        studentId = response.getBody().getIdStudent();
    }

    @Test
    @Order(3)
    void testCreateCourse() {
        CourseDTO course = new CourseDTO();
        course.setName("Spring Boot Masterclass");
        course.setCode("SB101");
        course.setCredit(5);
        course.setDescription("Learn Spring Boot");

        ResponseEntity<CourseDTO> response = restTemplate.postForEntity(
            "/api/courses", course, CourseDTO.class);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(response.getBody().getIdCourse()).isNotNull();
        courseId = response.getBody().getIdCourse();
    }

    @Test
    @Order(4)
    void testCreateEnrollment() {
        EnrollmentDTO enrollment = new EnrollmentDTO();
        enrollment.setStudentId(studentId);
        enrollment.setCourseId(courseId);
        enrollment.setStatus("ACTIVE");

        ResponseEntity<EnrollmentDTO> response = restTemplate.postForEntity(
            "/api/enrollments", enrollment, EnrollmentDTO.class);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(response.getBody().getIdEnrollment()).isNotNull();
        enrollmentId = response.getBody().getIdEnrollment();
    }

    @Test
    @Order(5)
    void testGetStudentById() {
        ResponseEntity<StudentDTO> response = restTemplate.getForEntity(
            "/api/students/" + studentId, StudentDTO.class);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody().getIdStudent()).isEqualTo(studentId);
    }

    @Test
    @Order(6)
    void testGetCourseById() {
        ResponseEntity<CourseDTO> response = restTemplate.getForEntity(
            "/api/courses/" + courseId, CourseDTO.class);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody().getIdCourse()).isEqualTo(courseId);
    }

    @Test
    @Order(7)
    void testGetDepartmentById() {
        ResponseEntity<DepartmentDTO> response = restTemplate.getForEntity(
            "/api/departments/" + departmentId, DepartmentDTO.class);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody().getIdDepartment()).isEqualTo(departmentId);
    }

    @Test
    @Order(8)
    void testUpdateStudent() {
        StudentDTO update = new StudentDTO();
        update.setFirstName("John Updated");
        update.setLastName("Doe Updated");

        HttpEntity<StudentDTO> request = new HttpEntity<>(update);
        ResponseEntity<StudentDTO> response = restTemplate.exchange(
            "/api/students/" + studentId,
            HttpMethod.PUT, request, StudentDTO.class);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody().getFirstName()).isEqualTo("John Updated");
    }

    @Test
    @Order(9)
    void completeStudentEnrollmentAndStatsFlow() {
        ResponseEntity<StudentDTO[]> studentsResponse = restTemplate.getForEntity(
            "/api/students", StudentDTO[].class);
        assertThat(studentsResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(studentsResponse.getBody()).hasSizeGreaterThanOrEqualTo(1);

        ResponseEntity<CourseDTO[]> coursesResponse = restTemplate.getForEntity(
            "/api/courses", CourseDTO[].class);
        assertThat(coursesResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(coursesResponse.getBody()).hasSizeGreaterThanOrEqualTo(1);
    }
}
EOF

echo "✅ StudentManagementE2ETest mis à jour avec @Import(TestSecurityConfig.class)"

# 3. Nettoyer et recompiler
echo "🧹 Nettoyage et recompilation..."
./mvnw clean compile -DskipTests

# 4. Exécuter les tests
echo "🚀 Exécution des tests..."
./mvnw test

echo "🎉 Terminé !"
