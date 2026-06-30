package tn.esprit.studentmanagement.services;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tn.esprit.studentmanagement.dto.EnrollmentDTO;
import tn.esprit.studentmanagement.entities.Enrollment;
import tn.esprit.studentmanagement.exceptions.ResourceNotFoundException;
import tn.esprit.studentmanagement.repositories.EnrollmentRepository;
import tn.esprit.studentmanagement.utils.DtoMapper;

import java.util.List;
import java.util.stream.Collectors;

@Service
@Transactional
public class EnrollmentService implements IEnrollment {
    private final EnrollmentRepository enrollmentRepository;
    private final DtoMapper dtoMapper;

    public EnrollmentService(EnrollmentRepository enrollmentRepository, DtoMapper dtoMapper) {
        this.enrollmentRepository = enrollmentRepository;
        this.dtoMapper = dtoMapper;
    }

    @Override
    public List<EnrollmentDTO> getAllEnrollments() {
        return enrollmentRepository.findAll().stream()
                .map(dtoMapper::toEnrollmentDTO)
                .collect(Collectors.toList());
    }

    @Override
    public EnrollmentDTO getEnrollmentById(Long idEnrollment) {
        Enrollment enrollment = enrollmentRepository.findById(java.util.Objects.requireNonNull(idEnrollment))
                .orElseThrow(() -> new ResourceNotFoundException("Enrollment not found with ID: " + idEnrollment));
        return dtoMapper.toEnrollmentDTO(enrollment);
    }

    @Override
    public EnrollmentDTO saveEnrollment(EnrollmentDTO enrollmentDTO) {
        if (enrollmentDTO.getIdEnrollment() != null
                && !enrollmentRepository.existsById(enrollmentDTO.getIdEnrollment())) {
            throw new ResourceNotFoundException("Enrollment not found with ID: " + enrollmentDTO.getIdEnrollment());
        }
        Enrollment enrollment = dtoMapper.toEnrollmentEntity(java.util.Objects.requireNonNull(enrollmentDTO));
        enrollment = enrollmentRepository.save(enrollment);
        return dtoMapper.toEnrollmentDTO(enrollment);
    }

    @Override
    public void deleteEnrollment(Long idEnrollment) {
        if (!enrollmentRepository.existsById(idEnrollment)) {
            throw new ResourceNotFoundException("Enrollment not found with ID: " + idEnrollment);
        }
        enrollmentRepository.deleteById(idEnrollment);
    }
}
