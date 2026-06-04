package tn.esprit.studentmanagement.entities;

import jakarta.persistence.*;
import lombok.*;

import java.util.List;

@Entity
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@ToString
public class Course {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long idCourse;
    @jakarta.validation.constraints.NotBlank
    private String name;
    @jakarta.validation.constraints.NotBlank
    private String code;           // exemple : CS101
    private int credit;            // nombre de crédits
    private String description;

    @OneToMany(mappedBy = "course")
    @ToString.Exclude
    private List<Enrollment> enrollments;

}
