package tn.esprit.studentmanagement.dto;

import lombok.Data;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;

@Data
public class EnrollmentDTO {
    private Long idEnrollment;
    @NotNull
    private LocalDate enrollmentDate;
    private Double grade;
    @NotNull
    private String status;
    private Long studentId;
    private Long courseId;
}
