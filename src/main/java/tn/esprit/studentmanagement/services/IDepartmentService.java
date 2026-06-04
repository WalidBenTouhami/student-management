package tn.esprit.studentmanagement.services;

import tn.esprit.studentmanagement.entities.Department;
import org.springframework.data.domain.Page;

import java.util.List;

public interface IDepartmentService {
    public List<Department> getAllDepartments();
    public Page<Department> getAllDepartmentsPaginated(int page, int size);
    public Department getDepartmentById(Long idDepartment);
    public Department saveDepartment(Department department);
    public void deleteDepartment(Long idDepartment);
}
