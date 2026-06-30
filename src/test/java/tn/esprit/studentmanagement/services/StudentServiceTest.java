package tn.esprit.studentmanagement.services;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import tn.esprit.studentmanagement.dto.StudentDTO;
import tn.esprit.studentmanagement.entities.Student;
import tn.esprit.studentmanagement.repositories.StudentRepository;
import tn.esprit.studentmanagement.utils.DtoMapper;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class StudentServiceTest {

    @Mock
    private StudentRepository studentRepository;

    @Mock
    private DtoMapper dtoMapper;

    @InjectMocks
    private StudentService studentService;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void testGetAllStudents() {
        Student s1 = new Student();
        s1.setIdStudent(1L);
        Student s2 = new Student();
        s2.setIdStudent(2L);
        when(studentRepository.findAll()).thenReturn(Arrays.asList(s1, s2));
        
        StudentDTO dto1 = new StudentDTO();
        dto1.setIdStudent(1L);
        StudentDTO dto2 = new StudentDTO();
        dto2.setIdStudent(2L);
        when(dtoMapper.toStudentDTO(s1)).thenReturn(dto1);
        when(dtoMapper.toStudentDTO(s2)).thenReturn(dto2);

        List<StudentDTO> students = studentService.getAllStudents();
        assertEquals(2, students.size());
        verify(studentRepository, times(1)).findAll();
    }

    @Test
    void testGetStudentById() {
        Student s1 = new Student();
        s1.setIdStudent(1L);
        when(studentRepository.findById(1L)).thenReturn(Optional.of(s1));
        
        StudentDTO dto1 = new StudentDTO();
        dto1.setIdStudent(1L);
        when(dtoMapper.toStudentDTO(s1)).thenReturn(dto1);

        StudentDTO result = studentService.getStudentById(1L);
        assertNotNull(result);
        assertEquals(1L, result.getIdStudent());
        verify(studentRepository, times(1)).findById(1L);
    }

    @Test
    void testSaveStudent() {
        Student s1 = new Student();
        s1.setFirstName("John");
        StudentDTO dto1 = new StudentDTO();
        dto1.setFirstName("John");
        
        when(dtoMapper.toStudentEntity(dto1)).thenReturn(s1);
        when(studentRepository.save(s1)).thenReturn(s1);
        when(dtoMapper.toStudentDTO(s1)).thenReturn(dto1);

        StudentDTO result = studentService.saveStudent(dto1);
        assertNotNull(result);
        assertEquals("John", result.getFirstName());
        verify(studentRepository, times(1)).save(s1);
    }

    @Test
    void testDeleteStudent() {
        when(studentRepository.existsById(1L)).thenReturn(true);
        doNothing().when(studentRepository).deleteById(1L);
        studentService.deleteStudent(1L);
        verify(studentRepository, times(1)).deleteById(1L);
    @Test
    void rejectsDuplicateEmail() {
        StudentDTO input = new StudentDTO();
        input.setEmail("test@test.com");
        when(studentRepository.existsByEmail("test@test.com")).thenReturn(true);
        assertThrows(IllegalArgumentException.class, () -> studentService.saveStudent(input));
    }

    @Test
    void rejectsUpdateMissingStudent() {
        StudentDTO input = new StudentDTO();
        input.setIdStudent(999L);
        when(studentRepository.existsById(999L)).thenReturn(false);
        assertThrows(tn.esprit.studentmanagement.exceptions.ResourceNotFoundException.class, () -> studentService.saveStudent(input));
    }

    @Test
    void rejectsDeleteMissingStudent() {
        when(studentRepository.existsById(999L)).thenReturn(false);
        assertThrows(tn.esprit.studentmanagement.exceptions.ResourceNotFoundException.class, () -> studentService.deleteStudent(999L));
    }
}
