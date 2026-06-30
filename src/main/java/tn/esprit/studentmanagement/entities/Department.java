package tn.esprit.studentmanagement.entities;

import jakarta.persistence.*;
import lombok.*;

import java.util.List;

@Entity
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class Department {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long idDepartment;
    @Column(nullable = false, length = 150)
    private String name;
    private String location;
    @Column(length = 30)
    private String phone;
    @Column(length = 150)
    private String head; // chef de département

    @OneToMany(mappedBy = "department")
    private List<Student> students;
}
