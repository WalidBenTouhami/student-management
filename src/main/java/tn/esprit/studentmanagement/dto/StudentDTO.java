package tn.esprit.studentmanagement.dto;

import lombok.Data;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import java.time.LocalDate;

@Data
public class StudentDTO {
    private Long idStudent;
    @NotBlank(message = "First name is required")
    private String firstName;
    @NotBlank(message = "Last name is required")
    private String lastName;
    @Email(message = "Email must be valid")
    @NotBlank(message = "Email is required")
    private String email;
    private String phone;
    private LocalDate dateOfBirth;
    private String address;
    private Long departmentId;
}
