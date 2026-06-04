package tn.esprit.studentmanagement.mapper;

import tn.esprit.studentmanagement.dto.StudentDTO;
import tn.esprit.studentmanagement.entities.Student;

public class StudentMapper {
    public static StudentDTO toDto(Student s) {
        if (s == null) return null;
        StudentDTO d = new StudentDTO();
        d.idStudent = s.getIdStudent();
        d.firstName = s.getFirstName();
        d.lastName = s.getLastName();
        d.email = s.getEmail();
        d.phone = s.getPhone();
        d.dateOfBirth = s.getDateOfBirth();
        d.address = s.getAddress();
        if (s.getDepartment() != null) d.departmentId = s.getDepartment().getIdDepartment();
        return d;
    }

    public static Student toEntity(StudentDTO d) {
        if (d == null) return null;
        Student s = new Student();
        s.setIdStudent(d.idStudent);
        s.setFirstName(d.firstName);
        s.setLastName(d.lastName);
        s.setEmail(d.email);
        s.setPhone(d.phone);
        s.setDateOfBirth(d.dateOfBirth);
        s.setAddress(d.address);
        // department association handled by service/controller
        return s;
    }
}
