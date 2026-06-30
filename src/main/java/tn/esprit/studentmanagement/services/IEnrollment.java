package tn.esprit.studentmanagement.services;

import tn.esprit.studentmanagement.dto.EnrollmentDTO;

import java.util.List;

public interface IEnrollment {
    public List<EnrollmentDTO> getAllEnrollments();
    public EnrollmentDTO getEnrollmentById(Long idEnrollment);
    public EnrollmentDTO saveEnrollment(EnrollmentDTO enrollmentDTO);
    public void deleteEnrollment(Long idEnrollment);
}
