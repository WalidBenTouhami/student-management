package tn.esprit.studentmanagement.mapper;

import org.junit.jupiter.api.Test;
import tn.esprit.studentmanagement.dto.DepartmentDTO;
import tn.esprit.studentmanagement.entities.Department;

import static org.junit.jupiter.api.Assertions.*;

class DepartmentMapperTest {

    @Test
    void null_inputs_returnNull() {
        assertNull(DepartmentMapper.toDto(null));
        assertNull(DepartmentMapper.toEntity(null));
    }

    @Test
    void mapsFields() {
        Department d = new Department();
        d.setIdDepartment(5L);
        d.setName("Computer Science");
        d.setLocation("Building A");
        d.setPhone("555-000");
        d.setHead("Dr. X");

        DepartmentDTO dto = DepartmentMapper.toDto(d);
        assertNotNull(dto);
        assertEquals(5L, dto.getIdDepartment());
        assertEquals("Computer Science", dto.getName());
        assertEquals("Building A", dto.getLocation());
        assertEquals("555-000", dto.getPhone());
        assertEquals("Dr. X", dto.getHead());

        Department d2 = DepartmentMapper.toEntity(dto);
        assertNotNull(d2);
        assertEquals(5L, d2.getIdDepartment());
        assertEquals("Computer Science", d2.getName());
    }
}
