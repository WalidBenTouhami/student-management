package tn.esprit.studentmanagement.mapper;

import tn.esprit.studentmanagement.dto.EnrollmentDTO;
import tn.esprit.studentmanagement.entities.Enrollment;

public class EnrollmentMapper {
    public static EnrollmentDTO toDto(Enrollment e) {
        if (e == null) return null;
        EnrollmentDTO dto = new EnrollmentDTO();
        dto.idEnrollment = e.getIdEnrollment();
        dto.enrollmentDate = e.getEnrollmentDate();
        dto.grade = e.getGrade();
        dto.status = e.getStatus() != null ? e.getStatus().name() : null;
        if (e.getStudent() != null) dto.studentId = e.getStudent().getIdStudent();
        if (e.getCourse() != null) dto.courseId = e.getCourse().getIdCourse();
        return dto;
    }

    public static Enrollment toEntity(EnrollmentDTO dto) {
        if (dto == null) return null;
        Enrollment e = new Enrollment();
        e.setIdEnrollment(dto.idEnrollment);
        e.setEnrollmentDate(dto.enrollmentDate);
        e.setGrade(dto.grade);
        // status, student and course associations handled at service layer
        return e;
    }
}
