package tn.esprit.studentmanagement.controllers;

import lombok.AllArgsConstructor;
import org.springframework.web.bind.annotation.*;
import tn.esprit.studentmanagement.dto.EnrollmentDTO;
import tn.esprit.studentmanagement.entities.Enrollment;
import tn.esprit.studentmanagement.mapper.EnrollmentMapper;
import tn.esprit.studentmanagement.services.IEnrollment;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/Enrollment")
@CrossOrigin(origins = "http://localhost:4200")
@AllArgsConstructor
public class EnrollmentController {
    IEnrollment enrollmentService;
    @GetMapping("/getAllEnrollment")
    public org.springframework.data.domain.Page<EnrollmentDTO> getAllEnrollment(@RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "10") int size) {
        var pageData = enrollmentService.getAllEnrollmentsPaginated(page, size);
        var dtoList = pageData.getContent().stream().map(EnrollmentMapper::toDto).collect(Collectors.toList());
        return new org.springframework.data.domain.PageImpl<>(dtoList, pageData.getPageable(), pageData.getTotalElements());
    }

    @GetMapping("/getEnrollment/{id}")
    public EnrollmentDTO getEnrollment(@PathVariable Long id) { return EnrollmentMapper.toDto(enrollmentService.getEnrollmentById(id)); }

    @PostMapping("/createEnrollment")
    public EnrollmentDTO createEnrollment(@RequestBody EnrollmentDTO enrollmentDto) { 
        Enrollment e = EnrollmentMapper.toEntity(enrollmentDto);
        Enrollment saved = enrollmentService.saveEnrollment(e);
        return EnrollmentMapper.toDto(saved);
    }

    @PutMapping("/updateEnrollment")
    public EnrollmentDTO updateEnrollment(@RequestBody EnrollmentDTO enrollmentDto) {
        Enrollment e = EnrollmentMapper.toEntity(enrollmentDto);
        Enrollment saved = enrollmentService.saveEnrollment(e);
        return EnrollmentMapper.toDto(saved);
    }

    @DeleteMapping("/deleteEnrollment/{id}")
    public void deleteEnrollment(@PathVariable Long id) { enrollmentService.deleteEnrollment(id); }
}
