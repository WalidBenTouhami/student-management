package tn.esprit.studentmanagement.repositories;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import tn.esprit.studentmanagement.entities.Student;

import java.util.List;
import java.util.Optional;

public interface StudentRepository extends JpaRepository<Student, Long>, JpaSpecificationExecutor<Student> {
    boolean existsByEmail(String email);
    Optional<Student> findByEmail(String email);
    List<Student> findByDepartment_IdDepartment(Long departmentId);
}
