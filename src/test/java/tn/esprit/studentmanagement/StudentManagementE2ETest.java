package tn.esprit.studentmanagement;

import io.restassured.RestAssured;
import io.restassured.http.ContentType;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.MySQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import tn.esprit.studentmanagement.dto.*;

import java.time.LocalDate;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("prod")
@Testcontainers(disabledWithoutDocker = true)
class StudentManagementE2ETest {

    @Container
    static MySQLContainer<?> mysql = new MySQLContainer<>("mysql:8.0")
            .withDatabaseName("studentdb");

    @DynamicPropertySource
    static void configure(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", mysql::getJdbcUrl);
        registry.add("spring.datasource.username", mysql::getUsername);
        registry.add("spring.datasource.password", mysql::getPassword);
        registry.add("api.security.enabled", () -> "true");
        registry.add("api.username", () -> "api-user");
        registry.add("api.password", () -> "changeme");
    }

    @LocalServerPort
    private int port;

    @BeforeEach
    void setUp() {
        RestAssured.port = port;
        RestAssured.basePath = "/student";
    }

    @Test
    void completeStudentEnrollmentAndStatsFlow() {
        // 1. Create a Department
        DepartmentDTO dept = new DepartmentDTO();
        dept.setName("Science & Technology");
        dept.setLocation("Building A");
        dept.setHead("Dr. Smith");
        dept.setPhone("+123456789");

        DepartmentDTO savedDept = given()
                .auth().basic("api-user", "changeme")
                .contentType(ContentType.JSON)
                .body(dept)
                .when()
                .post("/api/departments")
                .then()
                .statusCode(201)
                .body("name", is("Science & Technology"))
                .body("idDepartment", notNullValue())
                .extract().as(DepartmentDTO.class);

        // 2. Create a Course linked to the Department
        CourseDTO course = new CourseDTO();
        course.setName("Advanced DevOps");
        course.setCode("DEV-301");
        course.setCredit(4);
        course.setCapacity(2); // set a small capacity to test the limit business rule
        course.setDescription("Docker, Jenkins, Helm & Kubernetes");
        course.setDepartmentId(savedDept.getIdDepartment());

        CourseDTO savedCourse = given()
                .auth().basic("api-user", "changeme")
                .contentType(ContentType.JSON)
                .body(course)
                .when()
                .post("/api/courses")
                .then()
                .statusCode(201)
                .body("name", is("Advanced DevOps"))
                .body("capacity", is(2))
                .extract().as(CourseDTO.class);

        // 3. Create a valid Student (Age >= 18)
        StudentDTO student = new StudentDTO();
        student.setFirstName("Alice");
        student.setLastName("Martin");
        student.setEmail("alice.martin@student.tn");
        student.setDateOfBirth(LocalDate.now().minusYears(20)); // age 20
        student.setAddress("Tunis");
        student.setDepartmentId(savedDept.getIdDepartment());

        StudentDTO savedStudent = given()
                .auth().basic("api-user", "changeme")
                .contentType(ContentType.JSON)
                .body(student)
                .when()
                .post("/api/students")
                .then()
                .statusCode(201)
                .body("firstName", is("Alice"))
                .body("email", is("alice.martin@student.tn"))
                .extract().as(StudentDTO.class);

        // 4. Try to create an invalid Student (Age < 18) -> Expect validation error / Bad Request
        StudentDTO minorStudent = new StudentDTO();
        minorStudent.setFirstName("Bob");
        minorStudent.setLastName("Minor");
        minorStudent.setEmail("bob.minor@student.tn");
        minorStudent.setDateOfBirth(LocalDate.now().minusYears(15)); // age 15
        minorStudent.setDepartmentId(savedDept.getIdDepartment());

        given()
                .auth().basic("api-user", "changeme")
                .contentType(ContentType.JSON)
                .body(minorStudent)
                .when()
                .post("/api/students")
                .then()
                .statusCode(400);

        // 5. Try to create a student with duplicate email -> Expect 400 Bad Request
        StudentDTO dupStudent = new StudentDTO();
        dupStudent.setFirstName("AliceDup");
        dupStudent.setLastName("MartinDup");
        dupStudent.setEmail("alice.martin@student.tn"); // same email
        dupStudent.setDateOfBirth(LocalDate.now().minusYears(22));

        given()
                .auth().basic("api-user", "changeme")
                .contentType(ContentType.JSON)
                .body(dupStudent)
                .when()
                .post("/api/students")
                .then()
                .statusCode(400);

        // 6. Enroll Student in Course
        EnrollmentDTO enrollment = new EnrollmentDTO();
        enrollment.setStudentId(savedStudent.getIdStudent());
        enrollment.setCourseId(savedCourse.getIdCourse());
        enrollment.setEnrollmentDate(LocalDate.now());
        enrollment.setStatus("ACTIVE");

        EnrollmentDTO savedEnrollment = given()
                .auth().basic("api-user", "changeme")
                .contentType(ContentType.JSON)
                .body(enrollment)
                .when()
                .post("/api/enrollments")
                .then()
                .statusCode(201)
                .body("status", is("ACTIVE"))
                .extract().as(EnrollmentDTO.class);

        // 7. Try double active enrollment in same course -> Expect 409 Conflict
        given()
                .auth().basic("api-user", "changeme")
                .contentType(ContentType.JSON)
                .body(enrollment)
                .when()
                .post("/api/enrollments")
                .then()
                .statusCode(409);

        // 8. Enroll a 2nd student (to fill capacity of 2)
        StudentDTO student2 = new StudentDTO();
        student2.setFirstName("John");
        student2.setLastName("Doe");
        student2.setEmail("john.doe@student.tn");
        student2.setDateOfBirth(LocalDate.now().minusYears(25));
        student2.setDepartmentId(savedDept.getIdDepartment());

        StudentDTO savedStudent2 = given()
                .auth().basic("api-user", "changeme")
                .contentType(ContentType.JSON)
                .body(student2)
                .when()
                .post("/api/students")
                .then()
                .statusCode(201)
                .extract().as(StudentDTO.class);

        EnrollmentDTO enrollment2 = new EnrollmentDTO();
        enrollment2.setStudentId(savedStudent2.getIdStudent());
        enrollment2.setCourseId(savedCourse.getIdCourse());
        enrollment2.setEnrollmentDate(LocalDate.now());
        enrollment2.setStatus("ACTIVE");

        given()
                .auth().basic("api-user", "changeme")
                .contentType(ContentType.JSON)
                .body(enrollment2)
                .when()
                .post("/api/enrollments")
                .then()
                .statusCode(201);

        // 9. Try to enroll a 3rd student (exceeds capacity) -> Expect 409 Conflict
        StudentDTO student3 = new StudentDTO();
        student3.setFirstName("Jane");
        student3.setLastName("Doe");
        student3.setEmail("jane.doe@student.tn");
        student3.setDateOfBirth(LocalDate.now().minusYears(23));
        student3.setDepartmentId(savedDept.getIdDepartment());

        StudentDTO savedStudent3 = given()
                .auth().basic("api-user", "changeme")
                .contentType(ContentType.JSON)
                .body(student3)
                .when()
                .post("/api/students")
                .then()
                .statusCode(201)
                .extract().as(StudentDTO.class);

        EnrollmentDTO enrollment3 = new EnrollmentDTO();
        enrollment3.setStudentId(savedStudent3.getIdStudent());
        enrollment3.setCourseId(savedCourse.getIdCourse());
        enrollment3.setEnrollmentDate(LocalDate.now());
        enrollment3.setStatus("ACTIVE");

        given()
                .auth().basic("api-user", "changeme")
                .contentType(ContentType.JSON)
                .body(enrollment3)
                .when()
                .post("/api/enrollments")
                .then()
                .statusCode(409);

        // 10. Assign a grade and update status
        savedEnrollment.setGrade(18.0);
        savedEnrollment.setStatus("COMPLETED");

        given()
                .auth().basic("api-user", "changeme")
                .contentType(ContentType.JSON)
                .body(savedEnrollment)
                .when()
                .put("/api/enrollments/" + savedEnrollment.getIdEnrollment())
                .then()
                .statusCode(200)
                .body("grade", is(18.0f))
                .body("status", is("COMPLETED"));

        // 11. Test search endpoint for students
        given()
                .auth().basic("api-user", "changeme")
                .queryParam("name", "Alice")
                .when()
                .get("/api/students/search")
                .then()
                .statusCode(200)
                .body("content", hasSize(1))
                .body("content[0].firstName", is("Alice"));

        // 12. Test stats endpoints
        given()
                .auth().basic("api-user", "changeme")
                .when()
                .get("/api/stats/dashboard")
                .then()
                .statusCode(200)
                .body("totalStudents", is(3))
                .body("totalCourses", is(1))
                .body("totalEnrollments", is(2))
                .body("averageGrade", notNullValue());

        given()
                .auth().basic("api-user", "changeme")
                .when()
                .get("/api/stats/report")
                .then()
                .statusCode(200)
                .body("$", hasSize(1))
                .body("[0].courseName", is("Advanced DevOps"))
                .body("[0].totalEnrollments", is(2))
                .body("[0].activeEnrollments", is(1)); // one was completed
    }
}
