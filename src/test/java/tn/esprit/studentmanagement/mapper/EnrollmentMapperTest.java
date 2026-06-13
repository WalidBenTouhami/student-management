package tn.esprit.studentmanagement.mapper;

import org.junit.jupiter.api.Test;
import tn.esprit.studentmanagement.dto.EnrollmentDTO;
import tn.esprit.studentmanagement.entities.Course;
import tn.esprit.studentmanagement.entities.Enrollment;
import tn.esprit.studentmanagement.entities.Student;

import java.time.LocalDate;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Pure unit test — no Spring context needed.
 * Instantiates the MapStruct-generated impl directly.
 */
class EnrollmentMapperTest {

    private final EnrollmentMapper mapper = new EnrollmentMapperImpl();

    @Test
    void toDto_null_returnsNull() {
        assertNull(mapper.toDto(null));
    }

    @Test
    void toEntity_null_returnsNull() {
        assertNull(mapper.toEntity(null));
    }

    @Test
    void toDto_mapsRelationsAndStatus() {
        Enrollment e = new Enrollment();
        e.setIdEnrollment(7L);
        e.setEnrollmentDate(LocalDate.of(2021, 9, 1));
        e.setGrade(15.5);
        e.setStatus("ACTIVE");
        Student s = new Student();
        s.setIdStudent(2L);
        Course c = new Course();
        c.setIdCourse(3L);
        e.setStudent(s);
        e.setCourse(c);

        EnrollmentDTO dto = mapper.toDto(e);
        assertNotNull(dto);
        assertEquals(7L, dto.getIdEnrollment());
        assertEquals(LocalDate.of(2021, 9, 1), dto.getEnrollmentDate());
        assertEquals(15.5, dto.getGrade());
        assertEquals("ACTIVE", dto.getStatus());
        assertEquals(2L, dto.getStudentId());
        assertEquals(3L, dto.getCourseId());
    }

    @Test
    void toEntity_validStatus_preserved() {
        EnrollmentDTO dto = new EnrollmentDTO();
        dto.setIdEnrollment(8L);
        dto.setEnrollmentDate(LocalDate.of(2022, 1, 1));
        dto.setGrade(12.0);
        dto.setStatus("ACTIVE");

        Enrollment e = mapper.toEntity(dto);
        assertNotNull(e);
        assertEquals(8L, e.getIdEnrollment());
        assertEquals("ACTIVE", e.getStatus());
    }

    @Test
    void toEntity_invalidStatus_returnsNull() {
        EnrollmentDTO dto = new EnrollmentDTO();
        dto.setIdEnrollment(9L);
        dto.setEnrollmentDate(LocalDate.of(2022, 1, 1));
        dto.setGrade(10.0);
        dto.setStatus("NOT_A_STATUS");

        Enrollment e = mapper.toEntity(dto);
        assertNotNull(e);
        assertNull(e.getStatus());
    }
}
