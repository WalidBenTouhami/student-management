package tn.esprit.studentmanagement.services;

import lombok.AllArgsConstructor;

import org.springframework.stereotype.Service;
import tn.esprit.studentmanagement.entities.Student;
import tn.esprit.studentmanagement.repositories.StudentRepository;

import java.util.List;

@Service
@AllArgsConstructor
public class StudentService implements IStudentService {
    private final StudentRepository studentRepository;
    
    @Override
    public List<Student> getAllStudents() { return studentRepository.findAll(); }
    
    @Override
    public Student getStudentById(Long id) { return studentRepository.findById(java.util.Objects.requireNonNull(id)).orElse(null); }
    
    @Override
    public Student saveStudent(Student student) { return studentRepository.save(java.util.Objects.requireNonNull(student)); }
    
    @Override
    public void deleteStudent(Long id) { studentRepository.deleteById(java.util.Objects.requireNonNull(id)); }
}
