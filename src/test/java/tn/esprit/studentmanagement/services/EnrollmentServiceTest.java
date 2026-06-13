package tn.esprit.studentmanagement.services;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import tn.esprit.studentmanagement.entities.Course;
import tn.esprit.studentmanagement.entities.Enrollment;
import tn.esprit.studentmanagement.entities.Student;
import tn.esprit.studentmanagement.repositories.CourseRepository;
import tn.esprit.studentmanagement.repositories.EnrollmentRepository;
import tn.esprit.studentmanagement.repositories.StudentRepository;
import tn.esprit.studentmanagement.exception.ResourceNotFoundException;

import java.time.LocalDate;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@SuppressWarnings("null")
class EnrollmentServiceTest {

    @Mock
    private EnrollmentRepository enrollmentRepository;
    @Mock
    private StudentRepository studentRepository;
    @Mock
    private CourseRepository courseRepository;

    @InjectMocks
    private EnrollmentService enrollmentService;

    private Student student;
    private Course course;
    private Enrollment enrollment;

    @BeforeEach
    void setUp() {
        student = new Student();
        student.setIdStudent(1L);
        student.setFirstName("Alice");

        course = new Course();
        course.setIdCourse(1L);
        course.setName("DevOps");
        course.setCapacity(2);

        enrollment = new Enrollment();
        enrollment.setStudent(student);
        enrollment.setCourse(course);
        enrollment.setStatus("ACTIVE");
        enrollment.setEnrollmentDate(LocalDate.now());
    }

    @Test
    void getAllEnrollments_shouldReturnList() {
        when(enrollmentRepository.findAll()).thenReturn(java.util.List.of(enrollment));
        assertThat(enrollmentService.getAllEnrollments()).hasSize(1);
    }

    @Test
    void getEnrollmentById_whenExists_shouldReturnEnrollment() {
        when(enrollmentRepository.findById(1L)).thenReturn(Optional.of(enrollment));
        assertThat(enrollmentService.getEnrollmentById(1L)).isEqualTo(enrollment);
    }

    @Test
    void getEnrollmentById_whenNotFound_shouldThrowResourceNotFoundException() {
        when(enrollmentRepository.findById(99L)).thenReturn(Optional.empty());
        assertThatThrownBy(() -> enrollmentService.getEnrollmentById(99L))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Enrollment not found: 99");
    }

    @Test
    void deleteEnrollment_whenExists_shouldDelete() {
        when(enrollmentRepository.existsById(1L)).thenReturn(true);
        doNothing().when(enrollmentRepository).deleteById(1L);

        enrollmentService.deleteEnrollment(1L);

        verify(enrollmentRepository).deleteById(1L);
    }

    @Test
    void deleteEnrollment_whenNotFound_shouldThrowResourceNotFoundException() {
        when(enrollmentRepository.existsById(99L)).thenReturn(false);
        assertThatThrownBy(() -> enrollmentService.deleteEnrollment(99L))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Enrollment not found: 99");
    }

    @Test
    void getEnrollmentsByStudentId_shouldReturnList() {
        when(enrollmentRepository.findByStudent_IdStudent(1L)).thenReturn(java.util.List.of(enrollment));
        assertThat(enrollmentService.getEnrollmentsByStudentId(1L)).hasSize(1);
    }

    @Test
    void getEnrollmentsByCourseId_shouldReturnList() {
        when(enrollmentRepository.findByCourse_IdCourse(1L)).thenReturn(java.util.List.of(enrollment));
        assertThat(enrollmentService.getEnrollmentsByCourseId(1L)).hasSize(1);
    }

    @Test
    void saveEnrollment_shouldSaveSuccessfully() {
        when(studentRepository.findById(1L)).thenReturn(Optional.of(student));
        when(courseRepository.findById(1L)).thenReturn(Optional.of(course));
        when(enrollmentRepository.findByStudent_IdStudentAndCourse_IdCourseAndStatus(1L, 1L, "ACTIVE"))
                .thenReturn(Optional.empty());
        when(enrollmentRepository.countByCourse_IdCourseAndStatus(1L, "ACTIVE")).thenReturn(0L);
        when(enrollmentRepository.save(any(Enrollment.class))).thenReturn(enrollment);

        Enrollment saved = enrollmentService.saveEnrollment(enrollment);

        assertThat(saved).isNotNull();
        verify(enrollmentRepository).save(enrollment);
    }

    @Test
    void saveEnrollment_whenStudentNull_shouldThrowIllegalArgumentException() {
        enrollment.setStudent(null);
        assertThatThrownBy(() -> enrollmentService.saveEnrollment(enrollment))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Student ID is required");
    }

    @Test
    void saveEnrollment_whenStudentIdNull_shouldThrowIllegalArgumentException() {
        student.setIdStudent(null);
        assertThatThrownBy(() -> enrollmentService.saveEnrollment(enrollment))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Student ID is required");
    }

    @Test
    void saveEnrollment_whenCourseNull_shouldThrowIllegalArgumentException() {
        enrollment.setCourse(null);
        assertThatThrownBy(() -> enrollmentService.saveEnrollment(enrollment))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Course ID is required");
    }

    @Test
    void saveEnrollment_whenCourseIdNull_shouldThrowIllegalArgumentException() {
        course.setIdCourse(null);
        assertThatThrownBy(() -> enrollmentService.saveEnrollment(enrollment))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Course ID is required");
    }

    @Test
    void saveEnrollment_whenStudentNotFound_shouldThrowResourceNotFoundException() {
        when(studentRepository.findById(1L)).thenReturn(Optional.empty());
        assertThatThrownBy(() -> enrollmentService.saveEnrollment(enrollment))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Student not found with ID: 1");
    }

    @Test
    void saveEnrollment_whenCourseNotFound_shouldThrowResourceNotFoundException() {
        when(studentRepository.findById(1L)).thenReturn(Optional.of(student));
        when(courseRepository.findById(1L)).thenReturn(Optional.empty());
        assertThatThrownBy(() -> enrollmentService.saveEnrollment(enrollment))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Course not found with ID: 1");
    }

    @Test
    void saveEnrollment_whenStatusNull_shouldDefaultToActiveAndSaveSuccessfully() {
        enrollment.setStatus(null);
        when(studentRepository.findById(1L)).thenReturn(Optional.of(student));
        when(courseRepository.findById(1L)).thenReturn(Optional.of(course));
        when(enrollmentRepository.findByStudent_IdStudentAndCourse_IdCourseAndStatus(1L, 1L, "ACTIVE"))
                .thenReturn(Optional.empty());
        when(enrollmentRepository.countByCourse_IdCourseAndStatus(1L, "ACTIVE")).thenReturn(0L);
        when(enrollmentRepository.save(any(Enrollment.class))).thenAnswer(invocation -> invocation.getArgument(0));

        Enrollment saved = enrollmentService.saveEnrollment(enrollment);

        assertThat(saved.getStatus()).isEqualTo("ACTIVE");
    }

    @Test
    void saveEnrollment_doubleEnrollment_shouldThrowIllegalStateException() {
        when(studentRepository.findById(1L)).thenReturn(Optional.of(student));
        when(courseRepository.findById(1L)).thenReturn(Optional.of(course));
        when(enrollmentRepository.findByStudent_IdStudentAndCourse_IdCourseAndStatus(1L, 1L, "ACTIVE"))
                .thenReturn(Optional.of(new Enrollment()));

        assertThatThrownBy(() -> enrollmentService.saveEnrollment(enrollment))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("already actively enrolled");
    }

    @Test
    void saveEnrollment_capacityExceeded_shouldThrowIllegalStateException() {
        when(studentRepository.findById(1L)).thenReturn(Optional.of(student));
        when(courseRepository.findById(1L)).thenReturn(Optional.of(course));
        when(enrollmentRepository.findByStudent_IdStudentAndCourse_IdCourseAndStatus(1L, 1L, "ACTIVE"))
                .thenReturn(Optional.empty());
        when(enrollmentRepository.countByCourse_IdCourseAndStatus(1L, "ACTIVE")).thenReturn(2L);

        assertThatThrownBy(() -> enrollmentService.saveEnrollment(enrollment))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("is full");
    }

    @Test
    void saveEnrollment_whenUpdateAndAlreadyActive_shouldAllowWithinCapacity() {
        enrollment.setIdEnrollment(10L);
        Enrollment oldEnrollment = new Enrollment();
        oldEnrollment.setIdEnrollment(10L);
        oldEnrollment.setStatus("ACTIVE");

        when(studentRepository.findById(1L)).thenReturn(Optional.of(student));
        when(courseRepository.findById(1L)).thenReturn(Optional.of(course));
        when(enrollmentRepository.findByStudent_IdStudentAndCourse_IdCourseAndStatus(1L, 1L, "ACTIVE"))
                .thenReturn(Optional.empty());
        when(enrollmentRepository.findById(10L)).thenReturn(Optional.of(oldEnrollment));
        when(enrollmentRepository.countByCourse_IdCourseAndStatus(1L, "ACTIVE")).thenReturn(2L);
        when(enrollmentRepository.save(any(Enrollment.class))).thenReturn(enrollment);

        Enrollment saved = enrollmentService.saveEnrollment(enrollment);

        assertThat(saved).isNotNull();
    }

    @Test
    void saveEnrollment_whenCourseCapacityNull_shouldDefaultTo30AndSaveSuccessfully() {
        course.setCapacity(null);
        when(studentRepository.findById(1L)).thenReturn(Optional.of(student));
        when(courseRepository.findById(1L)).thenReturn(Optional.of(course));
        when(enrollmentRepository.findByStudent_IdStudentAndCourse_IdCourseAndStatus(1L, 1L, "ACTIVE"))
                .thenReturn(Optional.empty());
        when(enrollmentRepository.countByCourse_IdCourseAndStatus(1L, "ACTIVE")).thenReturn(29L);
        when(enrollmentRepository.save(any(Enrollment.class))).thenReturn(enrollment);

        Enrollment saved = enrollmentService.saveEnrollment(enrollment);

        assertThat(saved).isNotNull();
    }
}
