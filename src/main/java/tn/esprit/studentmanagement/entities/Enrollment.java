package tn.esprit.studentmanagement.entities;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;

@Entity
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class Enrollment {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long idEnrollment;
    @Column(nullable = false)
    private LocalDate enrollmentDate;
    private Double grade;
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private Status status;

    @ManyToOne(optional = false)
    private Student student;

    @ManyToOne(optional = false)
    private Course course;





}
