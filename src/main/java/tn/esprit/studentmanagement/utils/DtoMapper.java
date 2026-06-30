package tn.esprit.studentmanagement.utils;

import tn.esprit.studentmanagement.dto.*;
import tn.esprit.studentmanagement.entities.*;
import tn.esprit.studentmanagement.repositories.*;
import org.springframework.stereotype.Component;

@Component
public class DtoMapper {

    private final DepartmentRepository departmentRepository;
    private final StudentRepository studentRepository;
    private final CourseRepository courseRepository;

    public DtoMapper(DepartmentRepository departmentRepository, StudentRepository studentRepository, CourseRepository courseRepository) {
        this.departmentRepository = departmentRepository;
        this.studentRepository = studentRepository;
        this.courseRepository = courseRepository;
    }

    public StudentDTO toStudentDTO(Student student) {
        if (student == null) return null;
        StudentDTO dto = new StudentDTO();
        dto.setIdStudent(student.getIdStudent());
        dto.setFirstName(student.getFirstName());
        dto.setLastName(student.getLastName());
        dto.setEmail(student.getEmail());
        dto.setPhone(student.getPhone());
        dto.setDateOfBirth(student.getDateOfBirth());
        dto.setAddress(student.getAddress());
        if (student.getDepartment() != null) {
            dto.setDepartmentId(student.getDepartment().getIdDepartment());
        }
        return dto;
    }

    public Student toStudentEntity(StudentDTO dto) {
        if (dto == null) return null;
        Student student = new Student();
        student.setIdStudent(dto.getIdStudent());
        student.setFirstName(dto.getFirstName());
        student.setLastName(dto.getLastName());
        student.setEmail(dto.getEmail());
        student.setPhone(dto.getPhone());
        student.setDateOfBirth(dto.getDateOfBirth());
        student.setAddress(dto.getAddress());
        if (dto.getDepartmentId() != null) {
            student.setDepartment(departmentRepository.findById(dto.getDepartmentId()).orElse(null));
        }
        return student;
    }

    public DepartmentDTO toDepartmentDTO(Department department) {
        if (department == null) return null;
        DepartmentDTO dto = new DepartmentDTO();
        dto.setIdDepartment(department.getIdDepartment());
        dto.setName(department.getName());
        dto.setLocation(department.getLocation());
        dto.setPhone(department.getPhone());
        dto.setHead(department.getHead());
        return dto;
    }

    public Department toDepartmentEntity(DepartmentDTO dto) {
        if (dto == null) return null;
        Department department = new Department();
        department.setIdDepartment(dto.getIdDepartment());
        department.setName(dto.getName());
        department.setLocation(dto.getLocation());
        department.setPhone(dto.getPhone());
        department.setHead(dto.getHead());
        return department;
    }

    public EnrollmentDTO toEnrollmentDTO(Enrollment enrollment) {
        if (enrollment == null) return null;
        EnrollmentDTO dto = new EnrollmentDTO();
        dto.setIdEnrollment(enrollment.getIdEnrollment());
        dto.setEnrollmentDate(enrollment.getEnrollmentDate());
        dto.setGrade(enrollment.getGrade());
        dto.setStatus(enrollment.getStatus());
        if (enrollment.getStudent() != null) {
            dto.setStudentId(enrollment.getStudent().getIdStudent());
        }
        if (enrollment.getCourse() != null) {
            dto.setCourseId(enrollment.getCourse().getIdCourse());
        }
        return dto;
    }

    public Enrollment toEnrollmentEntity(EnrollmentDTO dto) {
        if (dto == null) return null;
        Enrollment enrollment = new Enrollment();
        enrollment.setIdEnrollment(dto.getIdEnrollment());
        enrollment.setEnrollmentDate(dto.getEnrollmentDate());
        enrollment.setGrade(dto.getGrade());
        enrollment.setStatus(dto.getStatus());
        if (dto.getStudentId() != null) {
            enrollment.setStudent(studentRepository.findById(dto.getStudentId()).orElse(null));
        }
        if (dto.getCourseId() != null) {
            enrollment.setCourse(courseRepository.findById(dto.getCourseId()).orElse(null));
        }
        return enrollment;
    }
}
