package tn.esprit.studentmanagement.mapper;

import org.junit.jupiter.api.Test;
import tn.esprit.studentmanagement.dto.EnrollmentDTO;
import tn.esprit.studentmanagement.entities.Course;
import tn.esprit.studentmanagement.entities.Enrollment;
import tn.esprit.studentmanagement.entities.Status;
import tn.esprit.studentmanagement.entities.Student;

import java.time.LocalDate;

import static org.junit.jupiter.api.Assertions.*;

class EnrollmentMapperTest {

    @Test
    void toDto_and_toEntity_null_handling() {
        assertNull(EnrollmentMapper.toDto(null));
        assertNull(EnrollmentMapper.toEntity(null));
    }

    @Test
    void toDto_mapsRelationsAndStatus() {
        Enrollment e = new Enrollment();
        e.setIdEnrollment(7L);
        e.setEnrollmentDate(LocalDate.of(2021,9,1));
        e.setGrade(15.5);
        e.setStatus(Status.ACTIVE);
        Student s = new Student(); s.setIdStudent(2L);
        Course c = new Course(); c.setIdCourse(3L);
        e.setStudent(s);
        e.setCourse(c);

        var dto = EnrollmentMapper.toDto(e);
        assertNotNull(dto);
        assertEquals(7L, dto.getIdEnrollment());
        assertEquals(LocalDate.of(2021,9,1), dto.getEnrollmentDate());
        assertEquals(15.5, dto.getGrade());
        assertEquals("ACTIVE", dto.getStatus());
        assertEquals(2L, dto.getStudentId());
        assertEquals(3L, dto.getCourseId());
    }

    @Test
    void toEntity_parsesStatus_ignoreInvalid() {
        EnrollmentDTO dto = new EnrollmentDTO();
        dto.setIdEnrollment(8L);
        dto.setEnrollmentDate(LocalDate.of(2022,1,1));
        dto.setGrade(12.0);
        dto.setStatus("ACTIVE");

        Enrollment e = EnrollmentMapper.toEntity(dto);
        assertNotNull(e);
        assertEquals(8L, e.getIdEnrollment());
        assertEquals(Status.ACTIVE, e.getStatus());

        // invalid status should not throw
        dto.setStatus("NOT_A_STATUS");
        Enrollment e2 = EnrollmentMapper.toEntity(dto);
        assertNotNull(e2);
        // when invalid, status remains null
        assertNull(e2.getStatus());
    }
}
