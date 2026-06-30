package tn.esprit.studentmanagement.services;

import tn.esprit.studentmanagement.dto.DepartmentDTO;

import java.util.List;

public interface IDepartmentService {
    public List<DepartmentDTO> getAllDepartments();
    public DepartmentDTO getDepartmentById(Long idDepartment);
    public DepartmentDTO saveDepartment(DepartmentDTO departmentDTO);
    public void deleteDepartment(Long idDepartment);
}
