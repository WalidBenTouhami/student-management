package tn.esprit.studentmanagement.controllers;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import tn.esprit.studentmanagement.dto.EnrollmentDTO;
import tn.esprit.studentmanagement.entities.Enrollment;
import tn.esprit.studentmanagement.mapper.EnrollmentMapper;
import tn.esprit.studentmanagement.services.IEnrollmentService;

import java.util.List;

@RestController
@RequestMapping("/api/enrollments")
@RequiredArgsConstructor
public class EnrollmentController {

    private final IEnrollmentService enrollmentService;
    private final EnrollmentMapper enrollmentMapper;

    @PostMapping
    public ResponseEntity<EnrollmentDTO> create(@Valid @RequestBody EnrollmentDTO dto) {
        Enrollment entity = enrollmentMapper.toEntity(dto);
        Enrollment saved = enrollmentService.saveEnrollment(entity);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(enrollmentMapper.toDto(saved));
    }

    @GetMapping("/{id}")
    public ResponseEntity<EnrollmentDTO> getById(@PathVariable Long id) {
        Enrollment enrollment = enrollmentService.getEnrollmentById(id);
        return ResponseEntity.ok(enrollmentMapper.toDto(enrollment));
    }

    @PutMapping("/{id}")
    public ResponseEntity<EnrollmentDTO> update(@PathVariable Long id, @Valid @RequestBody EnrollmentDTO dto) {
        Enrollment existing = enrollmentService.getEnrollmentById(id);
        enrollmentMapper.updateEntity(dto, existing);
        Enrollment updated = enrollmentService.saveEnrollment(existing);
        return ResponseEntity.ok(enrollmentMapper.toDto(updated));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        enrollmentService.deleteEnrollment(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping
    public ResponseEntity<List<EnrollmentDTO>> getAll() {
        List<EnrollmentDTO> enrollments = enrollmentService.getAllEnrollments().stream()
                .map(enrollmentMapper::toDto)
                .toList();
        return ResponseEntity.ok(enrollments);
    }

    @GetMapping("/student/{studentId}")
    public ResponseEntity<List<EnrollmentDTO>> getByStudent(@PathVariable Long studentId) {
        List<EnrollmentDTO> enrollments = enrollmentService.getEnrollmentsByStudent(studentId).stream()
                .map(enrollmentMapper::toDto)
                .toList();
        return ResponseEntity.ok(enrollments);
    }

    @GetMapping("/course/{courseId}")
    public ResponseEntity<List<EnrollmentDTO>> getByCourse(@PathVariable Long courseId) {
        List<EnrollmentDTO> enrollments = enrollmentService.getEnrollmentsByCourse(courseId).stream()
                .map(enrollmentMapper::toDto)
                .toList();
        return ResponseEntity.ok(enrollments);
    }
}