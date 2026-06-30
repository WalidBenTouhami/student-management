package tn.esprit.studentmanagement.dto;

import lombok.Data;

@Data
public class DepartmentDTO {
    private Long idDepartment;
    private String name;
    private String location;
    private String phone;
    private String head;
}
