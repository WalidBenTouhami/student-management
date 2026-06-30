package tn.esprit.studentmanagement.services;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tn.esprit.studentmanagement.dto.StudentDTO;
import tn.esprit.studentmanagement.entities.Student;
import tn.esprit.studentmanagement.exceptions.ResourceNotFoundException;
import tn.esprit.studentmanagement.repositories.StudentRepository;
import tn.esprit.studentmanagement.utils.DtoMapper;

import java.util.List;
import java.util.stream.Collectors;

@Service
@Transactional
public class StudentService implements IStudentService {
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
                .collect(Collectors.toList());
    }
    
    @Override
    public StudentDTO getStudentById(Long id) {
        Student student = studentRepository.findById(java.util.Objects.requireNonNull(id))
                .orElseThrow(() -> new ResourceNotFoundException("Student not found with ID: " + id));
        return dtoMapper.toStudentDTO(student);
    }
    
    @Override
    public StudentDTO saveStudent(StudentDTO studentDTO) {
        if (studentDTO.getIdStudent() != null && !studentRepository.existsById(studentDTO.getIdStudent())) {
            throw new ResourceNotFoundException("Student not found with ID: " + studentDTO.getIdStudent());
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
            throw new ResourceNotFoundException("Student not found with ID: " + id);
        }
        studentRepository.deleteById(id);
    }
}
