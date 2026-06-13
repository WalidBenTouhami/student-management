package tn.esprit.studentmanagement.services;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import tn.esprit.studentmanagement.entities.Enrollment;
import tn.esprit.studentmanagement.exception.ResourceNotFoundException;
import tn.esprit.studentmanagement.repositories.EnrollmentRepository;

import java.util.List;

@Service
@RequiredArgsConstructor
public class EnrollmentService implements IEnrollmentService {

    private final EnrollmentRepository enrollmentRepository;
    private final tn.esprit.studentmanagement.repositories.StudentRepository studentRepository;
    private final tn.esprit.studentmanagement.repositories.CourseRepository courseRepository;

    @Override
    public List<Enrollment> getAllEnrollments() {
        return enrollmentRepository.findAll();
    }

    @Override
    public Enrollment getEnrollmentById(Long id) {
        return enrollmentRepository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Enrollment not found: " + id));
    }

    @Override
    public Enrollment saveEnrollment(Enrollment enrollment) {
        if (enrollment.getStudent() == null || enrollment.getStudent().getIdStudent() == null) {
            throw new IllegalArgumentException("Student ID is required.");
        }
        if (enrollment.getCourse() == null || enrollment.getCourse().getIdCourse() == null) {
            throw new IllegalArgumentException("Course ID is required.");
        }

        tn.esprit.studentmanagement.entities.Student student = studentRepository.findById(enrollment.getStudent().getIdStudent())
                .orElseThrow(() -> new ResourceNotFoundException("Student not found with ID: " + enrollment.getStudent().getIdStudent()));

        tn.esprit.studentmanagement.entities.Course course = courseRepository.findById(enrollment.getCourse().getIdCourse())
                .orElseThrow(() -> new ResourceNotFoundException("Course not found with ID: " + enrollment.getCourse().getIdCourse()));

        enrollment.setStudent(student);
        enrollment.setCourse(course);

        // Normalize status default to ACTIVE if null
        if (enrollment.getStatus() == null) {
            enrollment.setStatus("ACTIVE");
        }

        // 1. Enforce no double active enrollment for the same course
        if ("ACTIVE".equalsIgnoreCase(enrollment.getStatus())) {
            java.util.Optional<Enrollment> existingActive = enrollmentRepository
                    .findByStudent_IdStudentAndCourse_IdCourseAndStatus(student.getIdStudent(), course.getIdCourse(), "ACTIVE");
            if (existingActive.isPresent()) {
                if (enrollment.getIdEnrollment() == null || !existingActive.get().getIdEnrollment().equals(enrollment.getIdEnrollment())) {
                    throw new IllegalStateException("Student " + student.getFirstName() + " is already actively enrolled in course: " + course.getName());
                }
            }
        }

        // 2. Enforce course capacity check
        if ("ACTIVE".equalsIgnoreCase(enrollment.getStatus())) {
            long activeCount = enrollmentRepository.countByCourse_IdCourseAndStatus(course.getIdCourse(), "ACTIVE");
            
            // If it is an update and the status is changing to ACTIVE (or it was already active, we don't count itself)
            boolean isAlreadyActive = false;
            if (enrollment.getIdEnrollment() != null) {
                Enrollment old = enrollmentRepository.findById(enrollment.getIdEnrollment()).orElse(null);
                if (old != null && "ACTIVE".equalsIgnoreCase(old.getStatus())) {
                    isAlreadyActive = true;
                }
            }

            long expectedCount = isAlreadyActive ? activeCount : activeCount + 1;
            int maxCapacity = (course.getCapacity() != null) ? course.getCapacity() : 30;

            if (expectedCount > maxCapacity) {
                throw new IllegalStateException("Course " + course.getName() + " is full (Capacity: " + maxCapacity + ").");
            }
        }

        return enrollmentRepository.save(enrollment);
    }

    @Override
    public void deleteEnrollment(Long id) {
        if (!enrollmentRepository.existsById(id)) {
            throw new ResourceNotFoundException("Enrollment not found: " + id);
        }
        enrollmentRepository.deleteById(id);
    }

    @Override
    public List<Enrollment> getEnrollmentsByStudentId(Long studentId) {
        return enrollmentRepository.findByStudent_IdStudent(studentId);
    }

    @Override
    public List<Enrollment> getEnrollmentsByCourseId(Long courseId) {
        return enrollmentRepository.findByCourse_IdCourse(courseId);
    }
}