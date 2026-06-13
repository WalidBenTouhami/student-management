package tn.esprit.studentmanagement.dto;

import lombok.Data;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Max;

@Data
public class CourseDTO {
    private Long idCourse;
    @NotBlank(message = "Course name is required")
    private String name;
    @NotBlank(message = "Course code is required")
    private String code;
    @Min(value = 1, message = "Credits must be at least 1")
    @Max(value = 10, message = "Credits cannot exceed 10")
    private int credit;
    private String description;
    @Min(value = 1, message = "Capacity must be at least 1")
    private Integer capacity;
    private Long departmentId;
}
