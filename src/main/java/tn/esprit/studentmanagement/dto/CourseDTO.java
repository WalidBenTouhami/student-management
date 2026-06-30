package tn.esprit.studentmanagement.dto;

import lombok.Data;

@Data
public class CourseDTO {
    private Long idCourse;
    private String name;
    private String code;
    private int credit;
    private String description;
}
