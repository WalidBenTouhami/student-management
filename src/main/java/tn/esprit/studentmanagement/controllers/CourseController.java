package tn.esprit.studentmanagement.controllers;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import tn.esprit.studentmanagement.dto.CourseDTO;
import tn.esprit.studentmanagement.services.ICourseService;

import java.util.List;

@RestController
@RequestMapping("/courses")
public class CourseController {
    private final ICourseService courseService;

    public CourseController(ICourseService courseService) {
        this.courseService = courseService;
    }

    @GetMapping
    public List<CourseDTO> getAllCourses() {
        return courseService.getAllCourses();
    }

    @GetMapping("/{id}")
    public CourseDTO getCourse(@PathVariable Long id) {
        return courseService.getCourseById(id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public CourseDTO createCourse(@Valid @RequestBody CourseDTO courseDTO) {
        return courseService.saveCourse(courseDTO);
    }

    @PutMapping("/{id}")
    public CourseDTO updateCourse(@PathVariable Long id, @Valid @RequestBody CourseDTO courseDTO) {
        courseDTO.setIdCourse(id);
        return courseService.saveCourse(courseDTO);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteCourse(@PathVariable Long id) {
        courseService.deleteCourse(id);
    }
}
