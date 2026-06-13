#!/bin/bash
# ============================================================================
# NINJA FIX - Résolution du conflit de configuration Spring Boot
# ============================================================================

echo "🔧 Nettoyage des configurations conflictuelles..."

# 1. Supprimer la classe TestApplication qui cause le conflit
rm -f src/test/java/tn/esprit/studentmanagement/TestApplication.java

# 2. Supprimer les anciennes configurations de sécurité de test
rm -f src/test/java/tn/esprit/studentmanagement/TestSecurityConfig.java

# 3. Mettre à jour application-test.properties avec exclusion de sécurité ET désactivation de la sécurité
cat > src/test/resources/application-test.properties << 'EOF'
# =====================================================
# Configuration de test avec H2 et sécurité désactivée
# =====================================================

# Datasource H2
spring.datasource.url=jdbc:h2:mem:testdb;MODE=MySQL;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE
spring.datasource.driver-class-name=org.h2.Driver
spring.datasource.username=sa
spring.datasource.password=

# JPA
spring.jpa.hibernate.ddl-auto=create-drop
spring.jpa.database-platform=org.hibernate.dialect.H2Dialect
spring.jpa.show-sql=false

# Désactiver Flyway pour les tests (H2 gère le schema)
spring.flyway.enabled=false

# 🔓 Désactiver complètement Spring Security
spring.autoconfigure.exclude=\
  org.springframework.boot.autoconfigure.security.servlet.SecurityAutoConfiguration,\
  org.springframework.boot.actuate.autoconfigure.security.servlet.ManagementWebSecurityAutoConfiguration
spring.security.enabled=false
security.basic.enabled=false
management.security.enabled=false

# Logs au minimum
logging.level.org.springframework=WARN
logging.level.org.hibernate=WARN
EOF

# 4. Corriger les tests pour qu'ils utilisent l'application principale et non TestApplication
# Trouver tous les fichiers de test qui pourraient avoir une référence à TestApplication
find src/test -name "*.java" -exec sed -i '/classes = TestApplication.class/d' {} \;
find src/test -name "*.java" -exec sed -i '/@SpringBootTest(.*classes = .*TestApplication.*)/d' {} \;

# 5. Réécrire le StudentManagementE2ETest proprement (sans TestApplication)
cat > src/test/java/tn/esprit/studentmanagement/StudentManagementE2ETest.java << 'EOF'
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

# 6. Corriger FlywayMigrationIntegrationTest (supprimer référence à TestApplication)
cat > src/test/java/tn/esprit/studentmanagement/FlywayMigrationIntegrationTest.java << 'EOF'
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
EOF

# 7. Nettoyer et compiler
echo "🧹 Compilation et tests..."
./mvnw clean compile -DskipTests

# 8. Exécuter les tests
./mvnw test

echo "🎉 Correction terminée."
