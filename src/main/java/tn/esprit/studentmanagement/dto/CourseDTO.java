package tn.esprit.studentmanagement.dto;

import lombok.Data;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

@Data
public class CourseDTO {
    private Long idCourse;
    @NotBlank @Size(max = 150)
    private String name;
    @NotBlank @Size(max = 30)
    private String code;
    @Min(1) @Max(60)
    private int credit;
    @Size(max = 1000)
    private String description;
}
