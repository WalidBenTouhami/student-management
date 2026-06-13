package tn.esprit.studentmanagement.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class EnrollmentReportDTO {
    private String departmentName;
    private String courseName;
    private String courseCode;
    private long activeEnrollments;
    private long totalEnrollments;
    private Double averageGrade;
}
