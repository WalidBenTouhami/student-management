package tn.esprit.studentmanagement.entities;

import jakarta.persistence.*;
import lombok.*;


import java.time.LocalDate;
import java.util.List;

@Entity
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class Student {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long idStudent;
    @Column(nullable = false, length = 100)
    private String firstName;
    @Column(nullable = false, length = 100)
    private String lastName;
    @Column(nullable = false, unique = true)
    private String email;
    @Column(length = 30)
    private String phone;
    private LocalDate dateOfBirth;
    @Column(length = 255)
    private String address;

    @ManyToOne
    private Department department;

    @OneToMany(mappedBy = "student")
    private List<Enrollment> enrollments;
}
