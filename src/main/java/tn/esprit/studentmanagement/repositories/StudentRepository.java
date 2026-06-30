package tn.esprit.studentmanagement.repositories;

import org.springframework.data.jpa.repository.JpaRepository;

import tn.esprit.studentmanagement.entities.Student;
public interface StudentRepository extends JpaRepository<Student, Long> {
    boolean existsByEmail(String email);
}
