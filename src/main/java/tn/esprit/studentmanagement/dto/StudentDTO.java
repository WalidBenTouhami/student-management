package tn.esprit.studentmanagement.dto;

import lombok.Data;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Past;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;

@Data
public class StudentDTO {
    private Long idStudent;
    @NotBlank @Size(max = 100)
    private String firstName;
    @NotBlank @Size(max = 100)
    private String lastName;
    @NotBlank @Email @Size(max = 255)
    private String email;
    @Size(max = 30)
    private String phone;
    @Past
    private LocalDate dateOfBirth;
    @Size(max = 255)
    private String address;
    @Positive
    private Long departmentId;
}
