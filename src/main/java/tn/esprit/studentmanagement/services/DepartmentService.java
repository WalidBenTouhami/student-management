package tn.esprit.studentmanagement.services;

import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tn.esprit.studentmanagement.entities.Department;
import tn.esprit.studentmanagement.exception.ResourceNotFoundException;
import tn.esprit.studentmanagement.repositories.DepartmentRepository;

import java.util.List;

@Service
@RequiredArgsConstructor
@SuppressWarnings("null")
@Transactional
public class DepartmentService implements IDepartmentService {

    private final DepartmentRepository departmentRepository;

    @Override
    @Transactional(readOnly = true)
    public List<Department> getAllDepartments() {
        return departmentRepository.findAll(Sort.by("name"));
    }

    @Override
    @Transactional(readOnly = true)
    public Page<Department> getAllDepartmentsPaginated(int page, int size) {
        return departmentRepository.findAll(PageRequest.of(page, size, Sort.by("name")));
    }

    @Override
    @Transactional(readOnly = true)
    public Department getDepartmentById(Long idDepartment) {
        return departmentRepository.findById(idDepartment)
                .orElseThrow(() -> new ResourceNotFoundException("Department not found: " + idDepartment));
    }

    @Override
    public Department saveDepartment(Department department) {
        return departmentRepository.save(department);
    }

    @Override
    public void deleteDepartment(Long idDepartment) {
        if (!departmentRepository.existsById(idDepartment)) {
            throw new ResourceNotFoundException("Department not found: " + idDepartment);
        }
        departmentRepository.deleteById(idDepartment);
    }
}
