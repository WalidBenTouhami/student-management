package tn.esprit.studentmanagement.services;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tn.esprit.studentmanagement.dto.DepartmentDTO;
import tn.esprit.studentmanagement.entities.Department;
import tn.esprit.studentmanagement.exceptions.ResourceNotFoundException;
import tn.esprit.studentmanagement.repositories.DepartmentRepository;
import tn.esprit.studentmanagement.utils.DtoMapper;

import java.util.List;
import java.util.stream.Collectors;

@Service
@Transactional
public class DepartmentService implements IDepartmentService {
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
                .collect(Collectors.toList());
    }

    @Override
    public DepartmentDTO getDepartmentById(Long idDepartment) {
        Department department = departmentRepository.findById(java.util.Objects.requireNonNull(idDepartment))
                .orElseThrow(() -> new ResourceNotFoundException("Department not found with ID: " + idDepartment));
        return dtoMapper.toDepartmentDTO(department);
    }

    @Override
    public DepartmentDTO saveDepartment(DepartmentDTO departmentDTO) {
        if (departmentDTO.getIdDepartment() != null
                && !departmentRepository.existsById(departmentDTO.getIdDepartment())) {
            throw new ResourceNotFoundException("Department not found with ID: " + departmentDTO.getIdDepartment());
        }
        Department department = dtoMapper.toDepartmentEntity(java.util.Objects.requireNonNull(departmentDTO));
        department = departmentRepository.save(department);
        return dtoMapper.toDepartmentDTO(department);
    }

    @Override
    public void deleteDepartment(Long idDepartment) {
        if (!departmentRepository.existsById(idDepartment)) {
            throw new ResourceNotFoundException("Department not found with ID: " + idDepartment);
        }
        departmentRepository.deleteById(idDepartment);
    }
}
