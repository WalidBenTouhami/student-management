package tn.esprit.studentmanagement.services;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import tn.esprit.studentmanagement.dto.DashboardStatsDTO;
import tn.esprit.studentmanagement.dto.EnrollmentReportDTO;
import tn.esprit.studentmanagement.entities.Course;
import tn.esprit.studentmanagement.entities.Enrollment;
import tn.esprit.studentmanagement.repositories.StudentRepository;
import tn.esprit.studentmanagement.repositories.CourseRepository;
import tn.esprit.studentmanagement.repositories.DepartmentRepository;
import tn.esprit.studentmanagement.repositories.EnrollmentRepository;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class StatsService implements IStatsService {

    private final StudentRepository studentRepository;
    private final CourseRepository courseRepository;
    private final DepartmentRepository departmentRepository;
    private final EnrollmentRepository enrollmentRepository;

    @Override
    public DashboardStatsDTO getDashboardStats() {
        long totalStudents = studentRepository.count();
        long totalCourses = courseRepository.count();
        long totalDepartments = departmentRepository.count();
        long totalEnrollments = enrollmentRepository.count();

        List<Enrollment> enrollments = enrollmentRepository.findAll();

        double averageGrade = enrollments.stream()
                .filter(e -> e.getGrade() != null)
                .mapToDouble(Enrollment::getGrade)
                .average()
                .orElse(0.0);

        Map<String, Long> statusBreakdown = enrollments.stream()
                .collect(Collectors.groupingBy(
                        e -> e.getStatus() != null ? e.getStatus().toUpperCase() : "UNKNOWN",
                        Collectors.counting()
                ));

        Map<String, Long> enrollmentsByCourse = enrollments.stream()
                .filter(e -> e.getCourse() != null)
                .collect(Collectors.groupingBy(
                        e -> e.getCourse().getName(),
                        Collectors.counting()
                ));

        Map<String, Long> enrollmentsByDepartment = enrollments.stream()
                .filter(e -> e.getStudent() != null && e.getStudent().getDepartment() != null)
                .collect(Collectors.groupingBy(
                        e -> e.getStudent().getDepartment().getName(),
                        Collectors.counting()
                ));

        return DashboardStatsDTO.builder()
                .totalStudents(totalStudents)
                .totalCourses(totalCourses)
                .totalDepartments(totalDepartments)
                .totalEnrollments(totalEnrollments)
                .averageGrade(averageGrade)
                .statusBreakdown(statusBreakdown)
                .enrollmentsByCourse(enrollmentsByCourse)
                .enrollmentsByDepartment(enrollmentsByDepartment)
                .build();
    }

    @Override
    public List<EnrollmentReportDTO> getEnrollmentReport() {
        List<Enrollment> enrollments = enrollmentRepository.findAll();

        Map<Course, List<Enrollment>> byCourse = enrollments.stream()
                .filter(e -> e.getCourse() != null)
                .collect(Collectors.groupingBy(Enrollment::getCourse));

        return byCourse.entrySet().stream().map(entry -> {
            Course course = entry.getKey();
            List<Enrollment> courseEnrollments = entry.getValue();

            String deptName = course.getDepartment() != null ? course.getDepartment().getName() : "No Department";
            long active = courseEnrollments.stream()
                    .filter(e -> "ACTIVE".equalsIgnoreCase(e.getStatus()))
                    .count();
            long total = courseEnrollments.size();
            double avgGrade = courseEnrollments.stream()
                    .filter(e -> e.getGrade() != null)
                    .mapToDouble(Enrollment::getGrade)
                    .average()
                    .orElse(0.0);

            return new EnrollmentReportDTO(deptName, course.getName(), course.getCode(), active, total, avgGrade);
        }).collect(Collectors.toList());
    }
}
