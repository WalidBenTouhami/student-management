package tn.esprit.studentmanagement.services;

import tn.esprit.studentmanagement.entities.Enrollment;

import java.util.List;

public interface IEnrollmentService {

    List<Enrollment> getAllEnrollments();

    Enrollment getEnrollmentById(Long id);

    Enrollment saveEnrollment(Enrollment enrollment);

    void deleteEnrollment(Long id);

    // Named by ID (used in implementations)
    List<Enrollment> getEnrollmentsByStudentId(Long studentId);

    List<Enrollment> getEnrollmentsByCourseId(Long courseId);

    // Convenience aliases used by the controller
    default List<Enrollment> getEnrollmentsByStudent(Long studentId) {
        return getEnrollmentsByStudentId(studentId);
    }

    default List<Enrollment> getEnrollmentsByCourse(Long courseId) {
        return getEnrollmentsByCourseId(courseId);
    }
}