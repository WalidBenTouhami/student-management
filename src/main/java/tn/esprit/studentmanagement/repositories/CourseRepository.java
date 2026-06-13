package tn.esprit.studentmanagement.repositories;

import org.springframework.data.jpa.repository.JpaRepository;
import tn.esprit.studentmanagement.entities.Course;

public interface CourseRepository extends JpaRepository<Course, Long> {}
