package tn.esprit.studentmanagement.dto;

import lombok.Data;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;

@Data
public class EnrollmentDTO {
    private Long idEnrollment;
    @NotNull(message = "Enrollment date is required")
    private LocalDate enrollmentDate;
    private Double grade;
    @NotNull(message = "Status is required")
    private String status;
    private Long studentId;
    private Long courseId;
}
