package tn.esprit.studentmanagement.mapper;

import org.mapstruct.BeanMapping;
import org.mapstruct.Mapper;
import org.mapstruct.MappingTarget;
import org.mapstruct.NullValuePropertyMappingStrategy;
import tn.esprit.studentmanagement.dto.EnrollmentDTO;
import tn.esprit.studentmanagement.entities.Enrollment;
import tn.esprit.studentmanagement.entities.Status;
import tn.esprit.studentmanagement.entities.Student;
import tn.esprit.studentmanagement.entities.Course;

@Mapper(componentModel = "spring")
public interface EnrollmentMapper {

    // Conversion Entity → DTO
    // entity.status is String, dto.status is String — direct mapping
    default EnrollmentDTO toDto(Enrollment entity) {
        if (entity == null) return null;

        EnrollmentDTO dto = new EnrollmentDTO();
        dto.setIdEnrollment(entity.getIdEnrollment());
        dto.setEnrollmentDate(entity.getEnrollmentDate());
        dto.setGrade(entity.getGrade());
        dto.setStatus(entity.getStatus());   // String → String

        if (entity.getStudent() != null) {
            dto.setStudentId(entity.getStudent().getIdStudent());
        }
        if (entity.getCourse() != null) {
            dto.setCourseId(entity.getCourse().getIdCourse());
        }
        return dto;
    }

    // Conversion DTO → Entity
    default Enrollment toEntity(EnrollmentDTO dto) {
        if (dto == null) return null;

        Enrollment entity = new Enrollment();
        entity.setIdEnrollment(dto.getIdEnrollment());
        entity.setEnrollmentDate(dto.getEnrollmentDate());
        entity.setGrade(dto.getGrade());
        // Validate that the status string is a known Status value, set null if invalid
        entity.setStatus(normalizeStatus(dto.getStatus()));

        if (dto.getStudentId() != null) {
            Student student = new Student();
            student.setIdStudent(dto.getStudentId());
            entity.setStudent(student);
        } else {
            entity.setStudent(null);
        }
        if (dto.getCourseId() != null) {
            Course course = new Course();
            course.setIdCourse(dto.getCourseId());
            entity.setCourse(course);
        } else {
            entity.setCourse(null);
        }
        return entity;
    }

    // Partial update — ignore null values
    @BeanMapping(nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
    default void updateEntity(EnrollmentDTO dto, @MappingTarget Enrollment entity) {
        if (dto == null) return;

        if (dto.getEnrollmentDate() != null) {
            entity.setEnrollmentDate(dto.getEnrollmentDate());
        }
        if (dto.getGrade() != null) {
            entity.setGrade(dto.getGrade());
        }
        if (dto.getStatus() != null) {
            entity.setStatus(normalizeStatus(dto.getStatus()));
        }
        if (dto.getStudentId() != null) {
            Student student = new Student();
            student.setIdStudent(dto.getStudentId());
            entity.setStudent(student);
        } else {
            entity.setStudent(null);
        }
        if (dto.getCourseId() != null) {
            Course course = new Course();
            course.setIdCourse(dto.getCourseId());
            entity.setCourse(course);
        } else {
            entity.setCourse(null);
        }
    }

    /**
     * Normalize a status string: returns uppercase name if it matches a known Status enum,
     * otherwise returns null. This prevents storing garbage values in the DB.
     */
    default String normalizeStatus(String statusStr) {
        if (statusStr == null) return null;
        try {
            return Status.valueOf(statusStr.toUpperCase()).name();
        } catch (IllegalArgumentException e) {
            return null;
        }
    }
}