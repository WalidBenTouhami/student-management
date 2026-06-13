package tn.esprit.studentmanagement.mapper;

import org.mapstruct.BeanMapping;
import org.mapstruct.Mapper;
import org.mapstruct.MappingTarget;
import org.mapstruct.NullValuePropertyMappingStrategy;
import tn.esprit.studentmanagement.dto.EnrollmentDTO;
import tn.esprit.studentmanagement.entities.Enrollment;

@Mapper(componentModel = "spring")
public interface EnrollmentMapper {

    // Conversion Entity -> DTO
    default EnrollmentDTO toDto(Enrollment entity) {
        if (entity == null)
            return null;

        EnrollmentDTO dto = new EnrollmentDTO();
        dto.setIdEnrollment(entity.getIdEnrollment());
        dto.setEnrollmentDate(entity.getEnrollmentDate());
        dto.setGrade(entity.getGrade());
        dto.setStatus(entity.getStatus());

        // Extraire les IDs des relations
        if (entity.getStudent() != null) {
            dto.setStudentId(entity.getStudent().getIdStudent());
        }
        if (entity.getCourse() != null) {
            dto.setCourseId(entity.getCourse().getIdCourse());
        }

        return dto;
    }

    // Conversion DTO -> Entity
    default Enrollment toEntity(EnrollmentDTO dto) {
        if (dto == null)
            return null;

        Enrollment entity = new Enrollment();
        entity.setIdEnrollment(dto.getIdEnrollment());
        entity.setEnrollmentDate(dto.getEnrollmentDate());
        entity.setGrade(dto.getGrade());
        entity.setStatus(dto.getStatus());

        // Les relations student et course doivent être définies par le service
        // Ne pas les mapper directement depuis le DTO

        return entity;
    }

    // Mise à jour de l'entité
    @BeanMapping(nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
    default void updateEntity(EnrollmentDTO dto, @MappingTarget Enrollment entity) {
        if (dto == null)
            return;

        if (dto.getEnrollmentDate() != null) {
            entity.setEnrollmentDate(dto.getEnrollmentDate());
        }
        if (dto.getGrade() != null) {
            entity.setGrade(dto.getGrade());
        }
        if (dto.getStatus() != null) {
            entity.setStatus(dto.getStatus());
        }

        // Note: student et course ne sont pas mis à jour via le DTO
        // Ils doivent être gérés séparément dans les services
    }
}