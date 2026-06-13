package tn.esprit.studentmanagement.dto;

import lombok.Builder;
import lombok.Data;
import java.util.Map;

@Data
@Builder
public class DashboardStatsDTO {
    private long totalStudents;
    private long totalCourses;
    private long totalDepartments;
    private long totalEnrollments;
    private double averageGrade;
    private Map<String, Long> statusBreakdown;
    private Map<String, Long> enrollmentsByCourse;
    private Map<String, Long> enrollmentsByDepartment;
}
