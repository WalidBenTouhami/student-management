package tn.esprit.studentmanagement.repositories;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import tn.esprit.studentmanagement.entities.Enrollment;

import java.util.List;

@Repository
public interface EnrollmentRepository extends JpaRepository<Enrollment, Long> {

    List<Enrollment> findByStudent_IdStudent(Long studentId);

    List<Enrollment> findByCourse_IdCourse(Long courseId);

    boolean existsByStudent_IdStudentAndCourse_IdCourseAndStatus(Long studentId, Long courseId, String status);

    long countByCourse_IdCourseAndStatus(Long courseId, String status);

    java.util.Optional<Enrollment> findByStudent_IdStudentAndCourse_IdCourseAndStatus(Long studentId, Long courseId, String status);
}
