package tn.esprit.studentmanagement.controllers;

import jakarta.validation.Valid;
import lombok.AllArgsConstructor;
import org.springframework.web.bind.annotation.*;
import tn.esprit.studentmanagement.dto.EnrollmentDTO;
import tn.esprit.studentmanagement.entities.Enrollment;
import tn.esprit.studentmanagement.mapper.EnrollmentMapper;
import tn.esprit.studentmanagement.services.ICourseService;
import tn.esprit.studentmanagement.services.IEnrollment;
import tn.esprit.studentmanagement.services.IStudentService;

import java.util.stream.Collectors;

@RestController
@RequestMapping("/enrollments")
@CrossOrigin(origins = "http://localhost:4200")
@AllArgsConstructor
public class EnrollmentController {
    IEnrollment enrollmentService;
    IStudentService studentService;
    ICourseService courseService;

    @GetMapping
    public org.springframework.data.domain.Page<EnrollmentDTO> getAllEnrollment(@RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "10") int size) {
        var pageData = enrollmentService.getAllEnrollmentsPaginated(page, size);
        var dtoList = pageData.getContent().stream().map(EnrollmentMapper::toDto).collect(Collectors.toList());
        return new org.springframework.data.domain.PageImpl<>(dtoList, pageData.getPageable(), pageData.getTotalElements());
    }

    @GetMapping("/{id}")
    public EnrollmentDTO getEnrollment(@PathVariable Long id) { return EnrollmentMapper.toDto(enrollmentService.getEnrollmentById(id)); }

    @PostMapping
    public EnrollmentDTO createEnrollment(@Valid @RequestBody EnrollmentDTO enrollmentDto) { 
        Enrollment e = EnrollmentMapper.toEntity(enrollmentDto);
        if (enrollmentDto.getStudentId() != null) {
            e.setStudent(studentService.getStudentById(enrollmentDto.getStudentId()));
        }
        if (enrollmentDto.getCourseId() != null) {
            e.setCourse(courseService.getCourseById(enrollmentDto.getCourseId()));
        }
        Enrollment saved = enrollmentService.saveEnrollment(e);
        return EnrollmentMapper.toDto(saved);
    }

    @PutMapping
    public EnrollmentDTO updateEnrollment(@Valid @RequestBody EnrollmentDTO enrollmentDto) {
        Enrollment e = EnrollmentMapper.toEntity(enrollmentDto);
        if (enrollmentDto.getStudentId() != null) {
            e.setStudent(studentService.getStudentById(enrollmentDto.getStudentId()));
        }
        if (enrollmentDto.getCourseId() != null) {
            e.setCourse(courseService.getCourseById(enrollmentDto.getCourseId()));
        }
        Enrollment saved = enrollmentService.saveEnrollment(e);
        return EnrollmentMapper.toDto(saved);
    }

    @DeleteMapping("/{id}")
    public void deleteEnrollment(@PathVariable Long id) { enrollmentService.deleteEnrollment(id); }
}
