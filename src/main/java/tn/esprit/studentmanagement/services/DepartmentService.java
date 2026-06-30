package tn.esprit.studentmanagement.services;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tn.esprit.studentmanagement.dto.DepartmentDTO;
import tn.esprit.studentmanagement.entities.Department;
import tn.esprit.studentmanagement.exceptions.ResourceNotFoundException;
import tn.esprit.studentmanagement.repositories.DepartmentRepository;
import tn.esprit.studentmanagement.utils.DtoMapper;

import java.util.List;

@Service
@Transactional
public class DepartmentService implements IDepartmentService {
    private static final String DEPT_NOT_FOUND_MSG = "Department not found with ID: ";
    private final DepartmentRepository departmentRepository;
    private final DtoMapper dtoMapper;

    public DepartmentService(DepartmentRepository departmentRepository, DtoMapper dtoMapper) {
        this.departmentRepository = departmentRepository;
        this.dtoMapper = dtoMapper;
    }

    @Override
    public List<DepartmentDTO> getAllDepartments() {
        return departmentRepository.findAll().stream()
                .map(dtoMapper::toDepartmentDTO)
                .toList();
    }

    @Override
    public DepartmentDTO getDepartmentById(Long idDepartment) {
        Department department = departmentRepository.findById(java.util.Objects.requireNonNull(idDepartment))
                .orElseThrow(() -> new ResourceNotFoundException(DEPT_NOT_FOUND_MSG + idDepartment));
        return dtoMapper.toDepartmentDTO(department);
    }

    @Override
    public DepartmentDTO saveDepartment(DepartmentDTO departmentDTO) {
        if (departmentDTO.getIdDepartment() != null
                && !departmentRepository.existsById(departmentDTO.getIdDepartment())) {
            throw new ResourceNotFoundException(DEPT_NOT_FOUND_MSG + departmentDTO.getIdDepartment());
        }
        Department department = dtoMapper.toDepartmentEntity(java.util.Objects.requireNonNull(departmentDTO));
        department = departmentRepository.save(department);
        return dtoMapper.toDepartmentDTO(department);
    }

    @Override
    public void deleteDepartment(Long idDepartment) {
        if (!departmentRepository.existsById(idDepartment)) {
            throw new ResourceNotFoundException(DEPT_NOT_FOUND_MSG + idDepartment);
        }
        departmentRepository.deleteById(idDepartment);
    }
}
