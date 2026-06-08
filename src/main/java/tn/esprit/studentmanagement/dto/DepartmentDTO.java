package tn.esprit.studentmanagement.dto;

import lombok.Data;
import jakarta.validation.constraints.NotBlank;

@Data
public class DepartmentDTO {
    private Long idDepartment;
    @NotBlank
    private String name;
    private String location;
    private String phone;
    private String head;
}
