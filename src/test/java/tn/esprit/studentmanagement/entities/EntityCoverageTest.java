package tn.esprit.studentmanagement.entities;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class EntityCoverageTest {

    @Test
    void testCourse() {
        Course course = new Course();
        course.setIdCourse(1L);
        course.setName("DevOps");
        
        assertEquals(1L, course.getIdCourse());
        assertEquals("DevOps", course.getName());
    }

    @Test
    void testDepartment() {
        Department dept = new Department();
        dept.setIdDepart(1);
        dept.setNameDepart("IT");
        
        assertEquals(1, dept.getIdDepart());
        assertEquals("IT", dept.getNameDepart());
    }

    @Test
    void testEnrollment() {
        Enrollment enrollment = new Enrollment();
        enrollment.setIdEnrollment(1L);
        enrollment.setStatus(Status.ACTIVE);
        
        assertEquals(1L, enrollment.getIdEnrollment());
        assertEquals(Status.ACTIVE, enrollment.getStatus());
    }

    @Test
    void testStatusEnum() {
        Status active = Status.valueOf("ACTIVE");
        Status inactive = Status.valueOf("INACTIVE");
        
        assertEquals(Status.ACTIVE, active);
        assertEquals(Status.INACTIVE, inactive);
        
        Status[] values = Status.values();
        assertTrue(values.length > 0);
    }

    @Test
    void testStudent() {
        Student student = new Student();
        student.setIdStudent(1L);
        student.setFirstName("John");
        student.setLastName("Doe");
        
        assertEquals(1L, student.getIdStudent());
        assertEquals("John", student.getFirstName());
        assertEquals("Doe", student.getLastName());
    }
}
