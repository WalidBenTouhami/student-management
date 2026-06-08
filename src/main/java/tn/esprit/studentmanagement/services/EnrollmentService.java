package tn.esprit.studentmanagement.services;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import tn.esprit.studentmanagement.repositories.EnrollmentRepository;
import tn.esprit.studentmanagement.entities.Enrollment;
import java.util.List;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;

@Service
public class EnrollmentService implements IEnrollment {
    @Autowired
    EnrollmentRepository enrollmentRepository;

    @Override
    public List<Enrollment> getAllEnrollments() {
        return enrollmentRepository.findAll();
    }

    @Override
    public Page<Enrollment> getAllEnrollmentsPaginated(int page, int size) {
        return enrollmentRepository.findAll(PageRequest.of(page, size));
    }

    @Override
    public Enrollment getEnrollmentById(Long idEnrollment) {
        return enrollmentRepository.findById(idEnrollment)
                .orElseThrow(() -> new tn.esprit.studentmanagement.exception.ResourceNotFoundException("Enrollment not found: " + idEnrollment));
    }

    @Override
    public Enrollment saveEnrollment(Enrollment enrollment) {
        return enrollmentRepository.save(enrollment);
    }

    @Override
    public void deleteEnrollment(Long idEnrollment) {
        if (!enrollmentRepository.existsById(idEnrollment)) {
            throw new tn.esprit.studentmanagement.exception.ResourceNotFoundException("Enrollment not found: " + idEnrollment);
        }
        enrollmentRepository.deleteById(idEnrollment);
    }
}
