package tn.esprit.studentmanagement.services;

import tn.esprit.studentmanagement.entities.Student;
import org.springframework.data.domain.Page;

import java.util.List;

/**
 * Service interface for Student business operations.
 */
public interface IStudentService {
    List<Student> getAllStudents();
    Page<Student> getAllStudentsPaginated(int page, int size);
    Student getStudentById(Long id);
    Student saveStudent(Student student);
    void deleteStudent(Long id);
    List<Student> getStudentsByDepartment(Long departmentId);
    Page<Student> searchStudents(String name, String email, String departmentName, Long departmentId, int page, int size);
}

