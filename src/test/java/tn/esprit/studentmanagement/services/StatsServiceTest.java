package tn.esprit.studentmanagement.services;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import tn.esprit.studentmanagement.dto.DashboardStatsDTO;
import tn.esprit.studentmanagement.dto.EnrollmentReportDTO;
import tn.esprit.studentmanagement.entities.Course;
import tn.esprit.studentmanagement.entities.Department;
import tn.esprit.studentmanagement.entities.Enrollment;
import tn.esprit.studentmanagement.entities.Student;
import tn.esprit.studentmanagement.repositories.CourseRepository;
import tn.esprit.studentmanagement.repositories.DepartmentRepository;
import tn.esprit.studentmanagement.repositories.EnrollmentRepository;
import tn.esprit.studentmanagement.repositories.StudentRepository;

import java.util.ArrayList;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class StatsServiceTest {

    @Mock
    private StudentRepository studentRepository;
    @Mock
    private CourseRepository courseRepository;
    @Mock
    private DepartmentRepository departmentRepository;
    @Mock
    private EnrollmentRepository enrollmentRepository;

    @InjectMocks
    private StatsService statsService;

    private List<Enrollment> enrollments;

    @BeforeEach
    void setUp() {
        enrollments = new ArrayList<>();

        Department dept = new Department();
        dept.setName("IT");

        Student s1 = new Student();
        s1.setIdStudent(1L);
        s1.setDepartment(dept);

        Course c1 = new Course();
        c1.setIdCourse(1L);
        c1.setName("Java");
        c1.setCode("JA-101");
        c1.setDepartment(dept);

        Enrollment e1 = new Enrollment();
        e1.setIdEnrollment(1L);
        e1.setStudent(s1);
        e1.setCourse(c1);
        e1.setStatus("ACTIVE");
        e1.setGrade(16.0);

        enrollments.add(e1);
    }

    @Test
    void getDashboardStats_shouldReturnMetrics() {
        when(studentRepository.count()).thenReturn(5L);
        when(courseRepository.count()).thenReturn(2L);
        when(departmentRepository.count()).thenReturn(1L);
        when(enrollmentRepository.count()).thenReturn(3L);
        when(enrollmentRepository.findAll()).thenReturn(enrollments);

        DashboardStatsDTO stats = statsService.getDashboardStats();

        assertThat(stats.getTotalStudents()).isEqualTo(5L);
        assertThat(stats.getTotalCourses()).isEqualTo(2L);
        assertThat(stats.getTotalDepartments()).isEqualTo(1L);
        assertThat(stats.getTotalEnrollments()).isEqualTo(3L);
        assertThat(stats.getAverageGrade()).isEqualTo(16.0);
        assertThat(stats.getStatusBreakdown()).containsEntry("ACTIVE", 1L);
    }

    @Test
    void getEnrollmentReport_shouldReturnGroupedData() {
        when(enrollmentRepository.findAll()).thenReturn(enrollments);

        List<EnrollmentReportDTO> report = statsService.getEnrollmentReport();

        assertThat(report).hasSize(1);
        assertThat(report.get(0).getDepartmentName()).isEqualTo("IT");
        assertThat(report.get(0).getCourseName()).isEqualTo("Java");
        assertThat(report.get(0).getActiveEnrollments()).isEqualTo(1L);
        assertThat(report.get(0).getTotalEnrollments()).isEqualTo(1L);
        assertThat(report.get(0).getAverageGrade()).isEqualTo(16.0);
    }
}
