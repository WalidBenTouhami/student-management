package tn.esprit.studentmanagement.services;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tn.esprit.studentmanagement.dto.StudentDTO;
import tn.esprit.studentmanagement.entities.Student;
import tn.esprit.studentmanagement.exceptions.ResourceNotFoundException;
import tn.esprit.studentmanagement.repositories.StudentRepository;
import tn.esprit.studentmanagement.utils.DtoMapper;

import java.util.List;

@Service
@Transactional
public class StudentService implements IStudentService {
    private static final String STUDENT_NOT_FOUND_MSG = "Student not found with ID: ";
    private final StudentRepository studentRepository;
    private final DtoMapper dtoMapper;

    public StudentService(StudentRepository studentRepository, DtoMapper dtoMapper) {
        this.studentRepository = studentRepository;
        this.dtoMapper = dtoMapper;
    }
    
    @Override
    public List<StudentDTO> getAllStudents() {
        return studentRepository.findAll().stream()
                .map(dtoMapper::toStudentDTO)
                .toList();
    }
    
    @Override
    public StudentDTO getStudentById(Long id) {
        Student student = studentRepository.findById(java.util.Objects.requireNonNull(id))
                .orElseThrow(() -> new ResourceNotFoundException(STUDENT_NOT_FOUND_MSG + id));
        return dtoMapper.toStudentDTO(student);
    }
    
    @Override
    public StudentDTO saveStudent(StudentDTO studentDTO) {
        if (studentDTO.getIdStudent() != null && !studentRepository.existsById(studentDTO.getIdStudent())) {
            throw new ResourceNotFoundException(STUDENT_NOT_FOUND_MSG + studentDTO.getIdStudent());
        }
        if (studentDTO.getIdStudent() == null && studentRepository.existsByEmail(studentDTO.getEmail())) {
            throw new IllegalArgumentException("A student with this email already exists.");
        }
        Student student = dtoMapper.toStudentEntity(java.util.Objects.requireNonNull(studentDTO));
        student = studentRepository.save(student);
        return dtoMapper.toStudentDTO(student);
    }
    
    @Override
    public void deleteStudent(Long id) {
        if (!studentRepository.existsById(id)) {
            throw new ResourceNotFoundException(STUDENT_NOT_FOUND_MSG + id);
        }
        studentRepository.deleteById(id);
    }
}
