package tn.esprit.studentmanagement.mapper;

import org.junit.jupiter.api.Test;
import tn.esprit.studentmanagement.dto.StudentDTO;
import tn.esprit.studentmanagement.entities.Department;
import tn.esprit.studentmanagement.entities.Student;

import java.time.LocalDate;

import static org.junit.jupiter.api.Assertions.*;

import org.mapstruct.factory.Mappers;

/**
 * Pure unit test — no Spring context needed.
 */
class StudentMapperTest {

    private final StudentMapper mapper = Mappers.getMapper(StudentMapper.class);

    @Test
    void toDto_null_returnsNull() {
        assertNull(mapper.toDto(null));
    }

    @Test
    void toEntity_null_returnsNull() {
        assertNull(mapper.toEntity(null));
    }

    @Test
    void toDto_mapsAllFields() {
        Student s = new Student();
        s.setIdStudent(1L);
        s.setFirstName("John");
        s.setLastName("Doe");
        s.setEmail("john.doe@example.com");
        s.setPhone("12345");
        s.setDateOfBirth(LocalDate.of(2000, 1, 1));
        s.setAddress("123 Main St");
        Department dept = new Department();
        dept.setIdDepartment(99L);
        s.setDepartment(dept);

        StudentDTO dto = mapper.toDto(s);

        assertNotNull(dto);
        assertEquals(1L, dto.getIdStudent());
        assertEquals("John", dto.getFirstName());
        assertEquals("Doe", dto.getLastName());
        assertEquals("john.doe@example.com", dto.getEmail());
        assertEquals("12345", dto.getPhone());
        assertEquals(LocalDate.of(2000, 1, 1), dto.getDateOfBirth());
        assertEquals("123 Main St", dto.getAddress());
        assertEquals(99L, dto.getDepartmentId());
    }

    @Test
    void toEntity_mapsFields() {
        StudentDTO dto = new StudentDTO();
        dto.setIdStudent(2L);
        dto.setFirstName("Jane");
        dto.setLastName("Smith");
        dto.setEmail("jane.smith@example.com");
        dto.setPhone("67890");
        dto.setDateOfBirth(LocalDate.of(1995, 5, 5));
        dto.setAddress("456 Side St");

        Student s = mapper.toEntity(dto);

        assertNotNull(s);
        assertEquals(2L, s.getIdStudent());
        assertEquals("Jane", s.getFirstName());
        assertEquals("Smith", s.getLastName());
        assertEquals("jane.smith@example.com", s.getEmail());
        assertEquals("67890", s.getPhone());
        assertEquals(LocalDate.of(1995, 5, 5), s.getDateOfBirth());
        assertEquals("456 Side St", s.getAddress());
    }
}
