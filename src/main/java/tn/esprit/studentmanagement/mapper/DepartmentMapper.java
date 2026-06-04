package tn.esprit.studentmanagement.mapper;

import tn.esprit.studentmanagement.dto.DepartmentDTO;
import tn.esprit.studentmanagement.entities.Department;

public class DepartmentMapper {
    public static DepartmentDTO toDto(Department d) {
        if (d == null) return null;
        DepartmentDTO dto = new DepartmentDTO();
        dto.idDepartment = d.getIdDepartment();
        dto.name = d.getName();
        dto.location = d.getLocation();
        dto.phone = d.getPhone();
        dto.head = d.getHead();
        return dto;
    }

    public static Department toEntity(DepartmentDTO dto) {
        if (dto == null) return null;
        Department d = new Department();
        d.setIdDepartment(dto.idDepartment);
        d.setName(dto.name);
        d.setLocation(dto.location);
        d.setPhone(dto.phone);
        d.setHead(dto.head);
        return d;
    }
}
