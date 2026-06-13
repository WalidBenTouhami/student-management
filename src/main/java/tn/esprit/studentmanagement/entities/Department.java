package tn.esprit.studentmanagement.entities;

import jakarta.persistence.*;
import lombok.Data;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "departments")
@Data
public class Department {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long idDepartment;

    private String name;
    private String location;
    private String phone;
    private String head;

    @OneToMany(mappedBy = "department")
    private List<Student> students = new ArrayList<>();
}