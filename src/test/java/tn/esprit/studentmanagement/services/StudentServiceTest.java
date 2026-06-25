package tn.esprit.studentmanagement.services;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import tn.esprit.studentmanagement.entities.Student;
import tn.esprit.studentmanagement.repositories.StudentRepository;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class StudentServiceTest {

    @Mock
    private StudentRepository studentRepository;

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

        List<Student> students = studentService.getAllStudents();
        assertEquals(2, students.size());
        verify(studentRepository, times(1)).findAll();
    }

    @Test
    void testGetStudentById() {
        Student s1 = new Student();
        s1.setIdStudent(1L);
        when(studentRepository.findById(1L)).thenReturn(Optional.of(s1));

        Student result = studentService.getStudentById(1L);
        assertNotNull(result);
        assertEquals(1L, result.getIdStudent());
        verify(studentRepository, times(1)).findById(1L);
    }

    @Test
    void testSaveStudent() {
        Student s1 = new Student();
        s1.setFirstName("John");
        when(studentRepository.save(s1)).thenReturn(s1);

        Student result = studentService.saveStudent(s1);
        assertNotNull(result);
        assertEquals("John", result.getFirstName());
        verify(studentRepository, times(1)).save(s1);
    }

    @Test
    void testDeleteStudent() {
        doNothing().when(studentRepository).deleteById(1L);
        studentService.deleteStudent(1L);
        verify(studentRepository, times(1)).deleteById(1L);
    }
}
