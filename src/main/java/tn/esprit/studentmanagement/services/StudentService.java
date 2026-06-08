package tn.esprit.studentmanagement.services;

import org.springframework.stereotype.Service;
import tn.esprit.studentmanagement.entities.Student;
import tn.esprit.studentmanagement.repositories.StudentRepository;

import java.util.List;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;

@Service
public class StudentService implements IStudentService {
    
    private StudentRepository studentRepository;
    public List<Student> getAllStudents() { return studentRepository.findAll(); }
    public Page<Student> getAllStudentsPaginated(int page, int size) { return studentRepository.findAll(PageRequest.of(page, size)); }
    public Student getStudentById(Long id) { return studentRepository.findById(id)
            .orElseThrow(() -> new tn.esprit.studentmanagement.exception.ResourceNotFoundException("Student not found: " + id)); }
    public Student saveStudent(Student student) { return studentRepository.save(student); }
    public void deleteStudent(Long id) {
        if (!studentRepository.existsById(id)) {
            throw new tn.esprit.studentmanagement.exception.ResourceNotFoundException("Student not found: " + id);
        }
        studentRepository.deleteById(id);
    }

}
