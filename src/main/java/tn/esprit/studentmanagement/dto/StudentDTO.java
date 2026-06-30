package tn.esprit.studentmanagement.dto;

import lombok.Data;
import java.time.LocalDate;

@Data
public class StudentDTO {
    private Long idStudent;
    private String firstName;
    private String lastName;
    private String email;
    private String phone;
    private LocalDate dateOfBirth;
    private String address;
    private Long departmentId;
}
