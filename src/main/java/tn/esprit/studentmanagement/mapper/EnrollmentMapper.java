package tn.esprit.studentmanagement.mapper;

import tn.esprit.studentmanagement.dto.EnrollmentDTO;
import tn.esprit.studentmanagement.entities.Enrollment;

import tn.esprit.studentmanagement.entities.Status;

public class EnrollmentMapper {
    public static EnrollmentDTO toDto(Enrollment e) {
        if (e == null) return null;
        EnrollmentDTO dto = new EnrollmentDTO();
        dto.setIdEnrollment(e.getIdEnrollment());
        dto.setEnrollmentDate(e.getEnrollmentDate());
        dto.setGrade(e.getGrade());
        dto.setStatus(e.getStatus() != null ? e.getStatus().name() : null);
        if (e.getStudent() != null) dto.setStudentId(e.getStudent().getIdStudent());
        if (e.getCourse() != null) dto.setCourseId(e.getCourse().getIdCourse());
        return dto;
    }

    public static Enrollment toEntity(EnrollmentDTO dto) {
        if (dto == null) return null;
        Enrollment e = new Enrollment();
        e.setIdEnrollment(dto.getIdEnrollment());
        e.setEnrollmentDate(dto.getEnrollmentDate());
        e.setGrade(dto.getGrade());
        if (dto.getStatus() != null) {
            try {
                e.setStatus(Status.valueOf(dto.getStatus()));
            } catch (IllegalArgumentException ex) {
                // Ignore or handle invalid status
            }
        }
        // student and course associations handled at service layer or controller
        return e;
    }
}
