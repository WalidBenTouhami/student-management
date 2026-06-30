package tn.esprit.studentmanagement.dto;

import lombok.Data;
import tn.esprit.studentmanagement.entities.Status;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PastOrPresent;
import jakarta.validation.constraints.Positive;
import java.time.LocalDate;

@Data
public class EnrollmentDTO {
    private Long idEnrollment;
    @NotNull @PastOrPresent
    private LocalDate enrollmentDate;
    @DecimalMin("0.0") @DecimalMax("20.0")
    private Double grade;
    @NotNull
    private Status status;
    @NotNull @Positive
    private Long studentId;
    @NotNull @Positive
    private Long courseId;
}
