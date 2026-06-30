package tn.esprit.studentmanagement.dto;

import lombok.Data;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

@Data
public class DepartmentDTO {
    private Long idDepartment;
    @NotBlank @Size(max = 150)
    private String name;
    @Size(max = 255)
    private String location;
    @Size(max = 30)
    private String phone;
    @Size(max = 150)
    private String head;
}
