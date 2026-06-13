package tn.esprit.studentmanagement.repositories;

import org.springframework.data.jpa.repository.JpaRepository;
import tn.esprit.studentmanagement.entities.Enrollment;

import java.util.List;

public interface EnrollmentRepository extends JpaRepository<Enrollment, Long> {

    List<Enrollment> findByStudent_IdStudent(Long studentId);

    List<Enrollment> findByCourse_IdCourse(Long courseId);
}
