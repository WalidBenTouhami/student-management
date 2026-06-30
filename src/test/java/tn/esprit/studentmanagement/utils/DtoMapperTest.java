package tn.esprit.studentmanagement.utils;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import tn.esprit.studentmanagement.dto.*;
import tn.esprit.studentmanagement.entities.*;
import tn.esprit.studentmanagement.exceptions.ResourceNotFoundException;
import tn.esprit.studentmanagement.repositories.CourseRepository;
import tn.esprit.studentmanagement.repositories.DepartmentRepository;
import tn.esprit.studentmanagement.repositories.StudentRepository;

import java.time.LocalDate;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class DtoMapperTest {
    @Mock
    private DepartmentRepository departmentRepository;
    @Mock
    private StudentRepository studentRepository;
    @Mock
    private CourseRepository courseRepository;
    private DtoMapper mapper;

    @BeforeEach
    void setUp() {
        mapper = new DtoMapper(departmentRepository, studentRepository, courseRepository);
    }

    @Test
    void mapsStudentBothWays() {
        Department department = new Department();
        department.setIdDepartment(2L);
        Student student = new Student();
        student.setIdStudent(1L);
        student.setFirstName("Ada");
        student.setLastName("Lovelace");
        student.setEmail("ada@example.com");
        student.setPhone("123");
        student.setAddress("Tunis");
        student.setDateOfBirth(LocalDate.of(2000, 1, 1));
        student.setDepartment(department);

        StudentDTO dto = mapper.toStudentDTO(student);
        assertEquals(2L, dto.getDepartmentId());
        when(departmentRepository.findById(2L)).thenReturn(Optional.of(department));
        Student entity = mapper.toStudentEntity(dto);
        assertEquals("Ada", entity.getFirstName());
        assertSame(department, entity.getDepartment());
        assertNull(mapper.toStudentDTO(null));
        assertNull(mapper.toStudentEntity(null));
    }

    @Test
    void rejectsUnknownDepartment() {
        StudentDTO dto = new StudentDTO();
        dto.setDepartmentId(99L);
        when(departmentRepository.findById(99L)).thenReturn(Optional.empty());
        assertThrows(ResourceNotFoundException.class, () -> mapper.toStudentEntity(dto));
    }

    @Test
    void mapsDepartmentBothWays() {
        Department department = new Department();
        department.setIdDepartment(1L);
        department.setName("Engineering");
        department.setLocation("A1");
        department.setPhone("123");
        department.setHead("Grace");
        DepartmentDTO dto = mapper.toDepartmentDTO(department);
        assertEquals("Engineering", dto.getName());
        assertEquals("Grace", mapper.toDepartmentEntity(dto).getHead());
        assertNull(mapper.toDepartmentDTO(null));
        assertNull(mapper.toDepartmentEntity(null));
    }

    @Test
    void mapsEnrollmentBothWays() {
        Student student = new Student();
        student.setIdStudent(1L);
        Course course = new Course();
        course.setIdCourse(2L);
        Enrollment enrollment = new Enrollment();
        enrollment.setIdEnrollment(3L);
        enrollment.setEnrollmentDate(LocalDate.now());
        enrollment.setGrade(18.0);
        enrollment.setStatus(Status.ACTIVE);
        enrollment.setStudent(student);
        enrollment.setCourse(course);
        EnrollmentDTO dto = mapper.toEnrollmentDTO(enrollment);
        when(studentRepository.findById(1L)).thenReturn(Optional.of(student));
        when(courseRepository.findById(2L)).thenReturn(Optional.of(course));
        Enrollment entity = mapper.toEnrollmentEntity(dto);
        assertSame(student, entity.getStudent());
        assertSame(course, entity.getCourse());
        assertNull(mapper.toEnrollmentDTO(null));
        assertNull(mapper.toEnrollmentEntity(null));
    }

    @Test
    void rejectsUnknownEnrollmentRelations() {
        EnrollmentDTO missingStudent = new EnrollmentDTO();
        missingStudent.setStudentId(99L);
        when(studentRepository.findById(99L)).thenReturn(Optional.empty());
        assertThrows(ResourceNotFoundException.class, () -> mapper.toEnrollmentEntity(missingStudent));

        EnrollmentDTO missingCourse = new EnrollmentDTO();
        missingCourse.setCourseId(99L);
        when(courseRepository.findById(99L)).thenReturn(Optional.empty());
        assertThrows(ResourceNotFoundException.class, () -> mapper.toEnrollmentEntity(missingCourse));
    }

    @Test
    void mapsCourseBothWays() {
        Course course = new Course();
        course.setIdCourse(1L);
        course.setName("DevOps");
        course.setCode("DEVOPS-101");
        course.setCredit(5);
        course.setDescription("Delivery engineering");
        CourseDTO dto = mapper.toCourseDTO(course);
        assertEquals("DEVOPS-101", dto.getCode());
        assertEquals("Delivery engineering", mapper.toCourseEntity(dto).getDescription());
        assertNull(mapper.toCourseDTO(null));
        assertNull(mapper.toCourseEntity(null));
    }
}
