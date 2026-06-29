package tn.esprit.studentmanagement.services;



import org.springframework.stereotype.Service;
import tn.esprit.studentmanagement.entities.Department;
import tn.esprit.studentmanagement.repositories.DepartmentRepository;

import java.util.List;

@Service
public class DepartmentService implements IDepartmentService {
    private final DepartmentRepository departmentRepository;

    public DepartmentService(DepartmentRepository departmentRepository) {
        this.departmentRepository = departmentRepository;
    }

    @Override
    public List<Department> getAllDepartments() {
        return departmentRepository.findAll();
    }

    @Override
    public Department getDepartmentById(Long idDepartment) {
        return departmentRepository.findById(java.util.Objects.requireNonNull(idDepartment)).orElse(null);
    }

    @Override
    public Department saveDepartment(Department department) {
        return departmentRepository.save(java.util.Objects.requireNonNull(department));
    }

    @Override
    public void deleteDepartment(Long idDepartment) {
        departmentRepository.deleteById(java.util.Objects.requireNonNull(idDepartment));
    }
}
