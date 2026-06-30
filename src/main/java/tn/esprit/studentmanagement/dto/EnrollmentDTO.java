package tn.esprit.studentmanagement.dto;

import lombok.Data;
import tn.esprit.studentmanagement.entities.Status;
import java.time.LocalDate;

@Data
public class EnrollmentDTO {
    private Long idEnrollment;
    private LocalDate enrollmentDate;
    private Double grade;
    private Status status;
    private Long studentId;
    private Long courseId;
}
