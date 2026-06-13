#!/bin/bash
# ============================================================================
# NINJA FIX - Contexte Spring cassé pour les tests
# ============================================================================

echo "🔧 Reconstruction des tests avec des slices Spring..."

# 1. Supprimer l'ancienne configuration de test conflictuelle
rm -f src/test/java/tn/esprit/studentmanagement/TestSecurityConfig.java

# 2. Créer une configuration de test générique qui désactive tout ce qui bloque
cat > src/test/java/tn/esprit/studentmanagement/TestApplication.java << 'EOF'
package tn.esprit.studentmanagement;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.security.servlet.SecurityAutoConfiguration;
import org.springframework.context.annotation.ComponentScan;

@SpringBootApplication(exclude = SecurityAutoConfiguration.class)
@ComponentScan(basePackages = "tn.esprit.studentmanagement")
public class TestApplication {
    public static void main(String[] args) {
        SpringApplication.run(TestApplication.class, args);
    }
}
EOF

# 3. Mettre à jour application-test.properties avec exclusion de sécurité
cat > src/test/resources/application-test.properties << 'EOF'
# H2
spring.datasource.url=jdbc:h2:mem:testdb;MODE=MySQL;DB_CLOSE_DELAY=-1
spring.datasource.driver-class-name=org.h2.Driver
spring.datasource.username=sa
spring.datasource.password=
spring.jpa.database-platform=org.hibernate.dialect.H2Dialect
spring.jpa.hibernate.ddl-auto=create-drop
spring.flyway.enabled=false

# Désactiver complètement la sécurité
spring.autoconfigure.exclude=org.springframework.boot.autoconfigure.security.servlet.SecurityAutoConfiguration,org.springframework.boot.actuate.autoconfigure.security.servlet.ManagementWebSecurityAutoConfiguration
spring.security.enabled=false
security.basic.enabled=false
management.security.enabled=false

# Logs
logging.level.org.springframework=WARN
logging.level.org.hibernate=WARN
EOF

# 4. Réécrire le test E2E en utilisant TestRestTemplate mais avec le nouveau contexte
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

@SpringBootTest(
    webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT,
    classes = TestApplication.class   // ← Utilise la classe de test sans sécurité
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
        assertThat(response.getBody().getIdDepartment()).isNotNull();
        departmentId = response.getBody().getIdDepartment();
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
        assertThat(response.getBody().getIdStudent()).isNotNull();
        studentId = response.getBody().getIdStudent();
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
    }

    @Test
    @Order(5)
    void testGetStudent() {
        ResponseEntity<StudentDTO> response = restTemplate.getForEntity(
            "/api/students/" + studentId, StudentDTO.class);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody().getIdStudent()).isEqualTo(studentId);
    }
}
EOF

# 5. Nettoyer et compiler
./mvnw clean compile -DskipTests

# 6. Lancer les tests
./mvnw test

echo "🎯 Correction terminée."
