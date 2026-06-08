package tn.esprit.studentmanagement.entities;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;

@Entity
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@ToString
public class Enrollment {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long idEnrollment;
    @jakarta.validation.constraints.NotNull
    private LocalDate enrollmentDate;
    private Double grade;
    @Enumerated(EnumType.STRING)
    @jakarta.validation.constraints.NotNull
    private Status status;

    @ManyToOne
    @ToString.Exclude
    private Student student;

    @ManyToOne
    @ToString.Exclude
    private Course course;





}
