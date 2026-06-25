package tn.esprit.studentmanagement.repositories;

import org.springframework.data.jpa.repository.JpaRepository;

import tn.esprit.studentmanagement.entities.Enrollment;
public interface EnrollmentRepository extends JpaRepository<Enrollment, Long> {
}
