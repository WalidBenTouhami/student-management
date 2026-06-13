package tn.esprit.studentmanagement.services;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import tn.esprit.studentmanagement.entities.Student;
import tn.esprit.studentmanagement.exception.ResourceNotFoundException;
import tn.esprit.studentmanagement.repositories.StudentRepository;

import java.util.List;
import java.util.Optional;
import java.time.LocalDate;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@SuppressWarnings({"null", "unchecked"})
class StudentServiceTest {

    @Mock
    private StudentRepository studentRepository;

    @InjectMocks
    private StudentService studentService;

    private Student student;

    @BeforeEach
    void setUp() {
        student = new Student();
        // Pas de setId, l'ID sera généré automatiquement
        student.setFirstName("John");
        student.setLastName("Doe");
        student.setEmail("john.doe@example.com");
    }

    @Test
    void getAllStudents_ShouldReturnListOfStudents() {
        List<Student> students = List.of(student);
        when(studentRepository.findAll()).thenReturn(students);

        List<Student> result = studentService.getAllStudents();

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getEmail()).isEqualTo("john.doe@example.com");
        verify(studentRepository).findAll();
    }

    @Test
    void getAllStudentsPaginated_ShouldReturnPageOfStudents() {
        Page<Student> page = new PageImpl<>(List.of(student));
        int pageNumber = 0;
        int pageSize = 10;
        when(studentRepository.findAll(PageRequest.of(pageNumber, pageSize))).thenReturn(page);

        Page<Student> result = studentService.getAllStudentsPaginated(pageNumber, pageSize);

        assertThat(result.getContent()).hasSize(1);
        assertThat(result.getTotalElements()).isEqualTo(1);
        verify(studentRepository).findAll(PageRequest.of(pageNumber, pageSize));
    }

    @Test
    void getStudentById_WhenExists_ShouldReturnStudent() {
        // On simule un étudiant avec un ID (via reflection si besoin, mais on ne l'utilise pas directement)
        when(studentRepository.findById(1L)).thenReturn(Optional.of(student));

        Student found = studentService.getStudentById(1L);

        assertThat(found).isEqualTo(student);
        verify(studentRepository).findById(1L);
    }

    @Test
    void getStudentById_WhenNotFound_ShouldThrowResourceNotFoundException() {
        when(studentRepository.findById(99L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> studentService.getStudentById(99L))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Student not found: 99");
        verify(studentRepository).findById(99L);
    }

    @Test
    void saveStudent_ShouldReturnSavedStudent() {
        student.setDateOfBirth(LocalDate.of(2000, 1, 1));
        when(studentRepository.findByEmail(anyString())).thenReturn(Optional.empty());
        when(studentRepository.save(any(Student.class))).thenReturn(student);

        Student saved = studentService.saveStudent(student);

        assertThat(saved).isEqualTo(student);
        verify(studentRepository).save(student);
    }

    @Test
    void saveStudent_WhenAgeUnder18_ShouldThrowIllegalArgumentException() {
        student.setDateOfBirth(LocalDate.now().minusYears(15)); // 15 ans

        assertThatThrownBy(() -> studentService.saveStudent(student))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Student must be at least 18 years old.");
        verify(studentRepository, never()).save(any());
    }

    @Test
    void saveStudent_WhenEmailDuplicate_ShouldThrowIllegalArgumentException() {
        student.setDateOfBirth(LocalDate.of(2000, 1, 1));
        Student otherStudent = new Student();
        otherStudent.setIdStudent(2L);
        otherStudent.setEmail("john.doe@example.com");

        when(studentRepository.findByEmail("john.doe@example.com")).thenReturn(Optional.of(otherStudent));

        assertThatThrownBy(() -> studentService.saveStudent(student))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Email is already in use");
        verify(studentRepository, never()).save(any());
    }

    @Test
    void searchStudents_ShouldReturnPageOfStudents() {
        Page<Student> page = new PageImpl<>(List.of(student));
        when(studentRepository.findAll(any(org.springframework.data.jpa.domain.Specification.class), any(PageRequest.class)))
                .thenReturn(page);

        Page<Student> result = studentService.searchStudents("John", "john.doe@example.com", "IT", null, 0, 10);

        assertThat(result.getContent()).hasSize(1);
        verify(studentRepository).findAll(any(org.springframework.data.jpa.domain.Specification.class), any(PageRequest.class));
    }

    @Test
    void deleteStudent_WhenExists_ShouldDelete() {
        when(studentRepository.existsById(1L)).thenReturn(true);
        doNothing().when(studentRepository).deleteById(1L);

        studentService.deleteStudent(1L);

        verify(studentRepository).existsById(1L);
        verify(studentRepository).deleteById(1L);
    }

    @Test
    void deleteStudent_WhenNotFound_ShouldThrowResourceNotFoundException() {
        when(studentRepository.existsById(99L)).thenReturn(false);

        assertThatThrownBy(() -> studentService.deleteStudent(99L))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Student not found: 99");
        verify(studentRepository).existsById(99L);
        verify(studentRepository, never()).deleteById(anyLong());
    }
}