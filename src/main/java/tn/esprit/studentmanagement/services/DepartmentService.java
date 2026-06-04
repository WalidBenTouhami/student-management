package tn.esprit.studentmanagement.services;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import tn.esprit.studentmanagement.entities.Department;
import tn.esprit.studentmanagement.repositories.DepartmentRepository;

import java.util.List;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;

@Service

public class DepartmentService implements IDepartmentService {
    @Autowired
    DepartmentRepository departmentRepository;

    @Override
    public List<Department> getAllDepartments() {
        return departmentRepository.findAll();
    }

    @Override
    public Page<Department> getAllDepartmentsPaginated(int page, int size) {
        return departmentRepository.findAll(PageRequest.of(page, size));
    }

    @Override
    public Department getDepartmentById(Long idDepartment) {
        return departmentRepository.findById(idDepartment)
                .orElseThrow(() -> new tn.esprit.studentmanagement.exception.ResourceNotFoundException("Department not found: " + idDepartment));
    }

    @Override
    public Department saveDepartment(Department department) {
        return departmentRepository.save(department);
    }

    @Override
    public void deleteDepartment(Long idDepartment) {
departmentRepository.deleteById(idDepartment);
    }
}
