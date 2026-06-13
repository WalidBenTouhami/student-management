package tn.esprit.studentmanagement.mapper;

import org.mapstruct.BeanMapping;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingTarget;
import org.mapstruct.NullValuePropertyMappingStrategy;
import tn.esprit.studentmanagement.dto.CourseDTO;
import tn.esprit.studentmanagement.entities.Course;

@Mapper(componentModel = "spring", unmappedTargetPolicy = org.mapstruct.ReportingPolicy.IGNORE)
public interface CourseMapper {

    @Mapping(source = "department.idDepartment", target = "departmentId")
    CourseDTO toDto(Course entity);

    @Mapping(source = "departmentId", target = "department")
    Course toEntity(CourseDTO dto);

    @BeanMapping(nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
    void updateEntity(CourseDTO dto, @MappingTarget Course entity);

    default tn.esprit.studentmanagement.entities.Department mapDepartment(Long id) {
        if (id == null) return null;
        tn.esprit.studentmanagement.entities.Department d = new tn.esprit.studentmanagement.entities.Department();
        d.setIdDepartment(id);
        return d;
    }
}