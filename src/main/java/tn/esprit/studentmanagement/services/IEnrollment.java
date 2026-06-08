package tn.esprit.studentmanagement.services;

import tn.esprit.studentmanagement.entities.Enrollment;
import org.springframework.data.domain.Page;

import java.util.List;

public interface IEnrollment {
    public List<Enrollment> getAllEnrollments();
    public Page<Enrollment> getAllEnrollmentsPaginated(int page, int size);
    public Enrollment getEnrollmentById(Long idEnrollment);
    public Enrollment saveEnrollment(Enrollment enrollment);
    public void deleteEnrollment(Long idEnrollment);

}
