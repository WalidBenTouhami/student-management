package tn.esprit.studentmanagement.entities;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.scheduling.annotation.EnableScheduling;

import java.time.LocalDate;
import java.util.List;

@Entity
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@ToString
public class Student {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long idStudent;
    @jakarta.validation.constraints.NotBlank
    private String firstName;

    @jakarta.validation.constraints.NotBlank
    private String lastName;

    @jakarta.validation.constraints.Email
    @jakarta.validation.constraints.NotBlank
    private String email;

    private String phone;
    private LocalDate dateOfBirth;
    private String address;

    @ManyToOne
    private Department department;

    @OneToMany(mappedBy = "student")
    private List<Enrollment> enrollments;
}
