package tn.esprit.studentmanagement.repositories;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import tn.esprit.studentmanagement.entities.Student;

import java.util.List;

@Repository
public interface StudentRepository extends JpaRepository<Student, Long> {
    boolean existsByEmail(String email);
    List<Student> findByDepartment_Id(Long departmentId);
}
