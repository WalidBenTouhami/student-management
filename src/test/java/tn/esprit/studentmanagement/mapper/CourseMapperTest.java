package tn.esprit.studentmanagement.mapper;

import org.junit.jupiter.api.Test;
import tn.esprit.studentmanagement.dto.CourseDTO;
import tn.esprit.studentmanagement.entities.Course;

import static org.junit.jupiter.api.Assertions.*;

class CourseMapperTest {

    // MapStruct with componentModel=spring generates Spring beans,
    // but Mappers.getMapper() still works for unit tests (no Spring context needed).
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
    void toDto_and_toEntity_mapsFields() {
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

        Course c2 = mapper.toEntity(dto);
        assertNotNull(c2);
        assertEquals(10L, c2.getIdCourse());
        assertEquals("Algebra", c2.getName());
        assertEquals("MATH101", c2.getCode());
        assertEquals(3, c2.getCredit());
        assertEquals("Basic algebra", c2.getDescription());
    }
}
