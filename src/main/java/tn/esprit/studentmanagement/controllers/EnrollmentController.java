package tn.esprit.studentmanagement.controllers;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import tn.esprit.studentmanagement.dto.EnrollmentDTO;
import tn.esprit.studentmanagement.services.IEnrollment;

import java.util.List;
import jakarta.validation.Valid;

@RestController
@RequestMapping("/enrollments")
public class EnrollmentController {
    private IEnrollment enrollmentService;

    public EnrollmentController(IEnrollment enrollmentService) {
        this.enrollmentService = enrollmentService;
    }

    @GetMapping
    public List<EnrollmentDTO> getAllEnrollment() {
        return enrollmentService.getAllEnrollments();
    }

    @GetMapping("/{id}")
    public EnrollmentDTO getEnrollment(@PathVariable Long id) {
        return enrollmentService.getEnrollmentById(id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public EnrollmentDTO createEnrollment(@Valid @RequestBody EnrollmentDTO enrollment) {
        return enrollmentService.saveEnrollment(enrollment);
    }

    @PutMapping("/{id}")
    public EnrollmentDTO updateEnrollment(@PathVariable Long id, @Valid @RequestBody EnrollmentDTO enrollment) {
        enrollment.setIdEnrollment(id);
        return enrollmentService.saveEnrollment(enrollment);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteEnrollment(@PathVariable Long id) {
        enrollmentService.deleteEnrollment(id);
    }
}
