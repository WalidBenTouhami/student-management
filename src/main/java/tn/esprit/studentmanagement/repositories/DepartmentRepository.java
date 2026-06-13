package tn.esprit.studentmanagement.repositories;

import org.springframework.data.jpa.repository.JpaRepository;
import tn.esprit.studentmanagement.entities.Department;

public interface DepartmentRepository extends JpaRepository<Department, Long> {}
