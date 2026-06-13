package tn.esprit.studentmanagement.services;

import tn.esprit.studentmanagement.entities.Department;
import org.springframework.data.domain.Page;

import java.util.List;

/**
 * Service interface for Department business operations.
 */
public interface IDepartmentService {
    List<Department> getAllDepartments();
    Page<Department> getAllDepartmentsPaginated(int page, int size);
    Department getDepartmentById(Long idDepartment);
    Department saveDepartment(Department department);
    void deleteDepartment(Long idDepartment);
}
