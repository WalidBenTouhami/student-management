package tn.esprit.studentmanagement.mapper;

import tn.esprit.studentmanagement.dto.DepartmentDTO;
import tn.esprit.studentmanagement.entities.Department;

public class DepartmentMapper {
    public static DepartmentDTO toDto(Department d) {
        if (d == null) return null;
        DepartmentDTO dto = new DepartmentDTO();
        dto.setIdDepartment(d.getIdDepartment());
        dto.setName(d.getName());
        dto.setLocation(d.getLocation());
        dto.setPhone(d.getPhone());
        dto.setHead(d.getHead());
        return dto;
    }

    public static Department toEntity(DepartmentDTO dto) {
        if (dto == null) return null;
        Department d = new Department();
        d.setIdDepartment(dto.getIdDepartment());
        d.setName(dto.getName());
        d.setLocation(dto.getLocation());
        d.setPhone(dto.getPhone());
        d.setHead(dto.getHead());
        return d;
    }
}
