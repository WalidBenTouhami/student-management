package tn.esprit.studentmanagement.mapper;

import org.junit.jupiter.api.Test;
import tn.esprit.studentmanagement.dto.CourseDTO;
import tn.esprit.studentmanagement.entities.Course;

import static org.junit.jupiter.api.Assertions.*;

import org.mapstruct.factory.Mappers;

/**
 * Pure unit test — no Spring context needed.
 */
class CourseMapperTest {

    private final CourseMapper mapper = Mappers.getMapper(CourseMapper.class);

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
        Course c = new Course();
        c.setIdCourse(10L);
        c.setName("Algebra");
        c.setCode("MATH101");
        c.setCredit(3);
        c.setDescription("Basic algebra");

        CourseDTO dto = mapper.toDto(c);
        assertNotNull(dto);
        assertEquals(10L, dto.getIdCourse());
        assertEquals("Algebra", dto.getName());
        assertEquals("MATH101", dto.getCode());
        assertEquals(3, dto.getCredit());
        assertEquals("Basic algebra", dto.getDescription());
    }

    @Test
    void toEntity_mapsAllFields() {
        CourseDTO dto = new CourseDTO();
        dto.setIdCourse(10L);
        dto.setName("Algebra");
        dto.setCode("MATH101");
        dto.setCredit(3);
        dto.setDescription("Basic algebra");

        Course c = mapper.toEntity(dto);
        assertNotNull(c);
        assertEquals(10L, c.getIdCourse());
        assertEquals("Algebra", c.getName());
        assertEquals("MATH101", c.getCode());
        assertEquals(3, c.getCredit());
        assertEquals("Basic algebra", c.getDescription());
    }
}
