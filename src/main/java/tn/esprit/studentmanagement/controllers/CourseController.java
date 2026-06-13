package tn.esprit.studentmanagement.controllers;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import tn.esprit.studentmanagement.dto.CourseDTO;
import tn.esprit.studentmanagement.entities.Course;
import tn.esprit.studentmanagement.mapper.CourseMapper;
import tn.esprit.studentmanagement.services.ICourseService;

import java.util.List;

@RestController
@RequestMapping("/api/courses")
@RequiredArgsConstructor
public class CourseController {

    private final ICourseService courseService;
    private final CourseMapper courseMapper;

    @PostMapping
    public ResponseEntity<CourseDTO> create(@Valid @RequestBody CourseDTO dto) {
        Course entity = courseMapper.toEntity(dto);
        Course saved = courseService.saveCourse(entity);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(courseMapper.toDto(saved));
    }

    @GetMapping("/{id}")
    public ResponseEntity<CourseDTO> getById(@PathVariable Long id) {
        Course course = courseService.getCourseById(id);
        return ResponseEntity.ok(courseMapper.toDto(course));
    }

    @PutMapping("/{id}")
    public ResponseEntity<CourseDTO> update(@PathVariable Long id, @Valid @RequestBody CourseDTO dto) {
        Course existing = courseService.getCourseById(id);
        courseMapper.updateEntity(dto, existing);
        Course updated = courseService.saveCourse(existing);
        return ResponseEntity.ok(courseMapper.toDto(updated));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        courseService.deleteCourse(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping
    public ResponseEntity<List<CourseDTO>> getAll() {
        List<CourseDTO> courses = courseService.getAllCourses().stream()
                .map(courseMapper::toDto)
                .toList();
        return ResponseEntity.ok(courses);
    }

    @PutMapping("/{id}/assign/{departmentId}")
    public ResponseEntity<CourseDTO> assignDepartment(@PathVariable Long id, @PathVariable Long departmentId) {
        Course updated = courseService.assignDepartment(id, departmentId);
        return ResponseEntity.ok(courseMapper.toDto(updated));
    }
}