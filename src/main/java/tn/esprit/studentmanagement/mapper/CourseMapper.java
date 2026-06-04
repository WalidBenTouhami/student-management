package tn.esprit.studentmanagement.mapper;

import tn.esprit.studentmanagement.dto.CourseDTO;
import tn.esprit.studentmanagement.entities.Course;

public class CourseMapper {
    public static CourseDTO toDto(Course c) {
        if (c == null) return null;
        CourseDTO dto = new CourseDTO();
        dto.setIdCourse(c.getIdCourse());
        dto.setName(c.getName());
        dto.setCode(c.getCode());
        dto.setCredit(c.getCredit());
        dto.setDescription(c.getDescription());
        return dto;
    }

    public static Course toEntity(CourseDTO dto) {
        if (dto == null) return null;
        Course c = new Course();
        c.setIdCourse(dto.getIdCourse());
        c.setName(dto.getName());
        c.setCode(dto.getCode());
        c.setCredit(dto.getCredit());
        c.setDescription(dto.getDescription());
        return c;
    }
}
