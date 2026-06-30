package tn.esprit.studentmanagement.entities;

import jakarta.persistence.*;
import lombok.*;

import java.util.List;

@Entity
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class Course {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long idCourse;
    @Column(nullable = false, length = 150)
    private String name;
    @Column(nullable = false, unique = true, length = 30)
    private String code;           // exemple : CS101
    private int credit;            // nombre de crédits
    @Column(length = 1000)
    private String description;

    @OneToMany(mappedBy = "course")
    private List<Enrollment> enrollments;

}
