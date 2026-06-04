package tn.esprit.studentmanagement.dto;

import lombok.Data;
import jakarta.validation.constraints.NotBlank;

@Data
public class CourseDTO {
    private Long idCourse;
    @NotBlank
    private String name;
    @NotBlank
    private String code;
    private int credit;
    private String description;
}
