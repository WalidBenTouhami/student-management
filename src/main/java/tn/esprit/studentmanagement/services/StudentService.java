package tn.esprit.studentmanagement.services;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import tn.esprit.studentmanagement.entities.Student;
import tn.esprit.studentmanagement.exception.ResourceNotFoundException;
import tn.esprit.studentmanagement.repositories.StudentRepository;

import java.util.List;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;

@Service
@RequiredArgsConstructor
@SuppressWarnings("null")
public class StudentService implements IStudentService {

    private final StudentRepository studentRepository;

    @Override
    public List<Student> getAllStudents() {
        return studentRepository.findAll();
    }

    @Override
    public Page<Student> getAllStudentsPaginated(int page, int size) {
        return studentRepository.findAll(PageRequest.of(page, size));
    }

    @Override
    public Student getStudentById(Long id) {
        return studentRepository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Student not found: " + id));
    }

    @Override
    public Student saveStudent(Student student) {
        // 1. Enforce minimum age (18 years)
        if (student.getDateOfBirth() != null) {
            if (student.getDateOfBirth().isAfter(java.time.LocalDate.now().minusYears(18))) {
                throw new IllegalArgumentException("Student must be at least 18 years old.");
            }
        }

        // 2. Enforce email uniqueness
        if (student.getEmail() != null) {
            java.util.Optional<Student> existing = studentRepository.findByEmail(student.getEmail());
            if (existing.isPresent()) {
                if (student.getIdStudent() == null || !existing.get().getIdStudent().equals(student.getIdStudent())) {
                    throw new IllegalArgumentException("Email is already in use: " + student.getEmail());
                }
            }
        }
        return studentRepository.save(student);
    }

    @Override
    public void deleteStudent(Long id) {
        if (!studentRepository.existsById(id)) {
            throw new ResourceNotFoundException("Student not found: " + id);
        }
        studentRepository.deleteById(id);
    }

    @Override
    public List<Student> getStudentsByDepartment(Long departmentId) {
        return studentRepository.findByDepartment_IdDepartment(departmentId);
    }

    @Override
    public Page<Student> searchStudents(String name, String email, String departmentName, Long departmentId, int page, int size) {
        return studentRepository.findAll(
                tn.esprit.studentmanagement.repositories.StudentSpecification.search(name, email, departmentName, departmentId),
                PageRequest.of(page, size)
        );
    }
}