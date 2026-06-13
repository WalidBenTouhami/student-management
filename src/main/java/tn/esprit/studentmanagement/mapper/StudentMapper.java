package tn.esprit.studentmanagement.mapper;

import org.mapstruct.BeanMapping;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingTarget;
import org.mapstruct.NullValuePropertyMappingStrategy;
import tn.esprit.studentmanagement.dto.StudentDTO;
import tn.esprit.studentmanagement.entities.Student;

@Mapper(componentModel = "spring")
public interface StudentMapper {

    // MapStruct va automatiquement mapper:
    // idStudent <-> idStudent
    // firstName, lastName, email, phone, dateOfBirth, address
    // departmentId <-> department.id (si l'entité a une relation department)
    @Mapping(source = "department.idDepartment", target = "departmentId")
    StudentDTO toDto(Student entity);

    @Mapping(source = "departmentId", target = "department.idDepartment")
    Student toEntity(StudentDTO dto);

    @BeanMapping(nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
    void updateEntity(StudentDTO dto, @MappingTarget Student entity);
}