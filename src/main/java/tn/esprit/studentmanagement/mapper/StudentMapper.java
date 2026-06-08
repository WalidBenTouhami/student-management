package tn.esprit.studentmanagement.mapper;

import tn.esprit.studentmanagement.dto.StudentDTO;
import tn.esprit.studentmanagement.entities.Student;

public class StudentMapper {
    public static StudentDTO toDto(Student s) {
        if (s == null) return null;
        StudentDTO d = new StudentDTO();
        d.setIdStudent(s.getIdStudent());
        d.setFirstName(s.getFirstName());
        d.setLastName(s.getLastName());
        d.setEmail(s.getEmail());
        d.setPhone(s.getPhone());
        d.setDateOfBirth(s.getDateOfBirth());
        d.setAddress(s.getAddress());
        if (s.getDepartment() != null) d.setDepartmentId(s.getDepartment().getIdDepartment());
        return d;
    }

    public static Student toEntity(StudentDTO d) {
        if (d == null) return null;
        Student s = new Student();
        s.setIdStudent(d.getIdStudent());
        s.setFirstName(d.getFirstName());
        s.setLastName(d.getLastName());
        s.setEmail(d.getEmail());
        s.setPhone(d.getPhone());
        s.setDateOfBirth(d.getDateOfBirth());
        s.setAddress(d.getAddress());
        // department association handled by service/controller
        return s;
    }
}
