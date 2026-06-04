package tn.esprit.studentmanagement.controllers;

import jakarta.validation.Valid;
import lombok.AllArgsConstructor;
import org.springframework.web.bind.annotation.*;
import tn.esprit.studentmanagement.dto.CourseDTO;
import tn.esprit.studentmanagement.entities.Course;
import tn.esprit.studentmanagement.mapper.CourseMapper;
import tn.esprit.studentmanagement.services.ICourseService;

import java.util.stream.Collectors;

@RestController
@RequestMapping("/courses")
@CrossOrigin(origins = "http://localhost:4200")
@AllArgsConstructor
public class CourseController {
    private ICourseService courseService;

    @GetMapping
    public org.springframework.data.domain.Page<CourseDTO> getAllCourses(@RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "10") int size) {
        var pageData = courseService.getAllCoursesPaginated(page, size);
        var dtoList = pageData.getContent().stream().map(CourseMapper::toDto).collect(Collectors.toList());
        return new org.springframework.data.domain.PageImpl<>(dtoList, pageData.getPageable(), pageData.getTotalElements());
    }

    @GetMapping("/{id}")
    public CourseDTO getCourse(@PathVariable Long id) {
        return CourseMapper.toDto(courseService.getCourseById(id));
    }

    @PostMapping
    public CourseDTO createCourse(@Valid @RequestBody CourseDTO courseDto) {
        Course c = CourseMapper.toEntity(courseDto);
        Course saved = courseService.saveCourse(c);
        return CourseMapper.toDto(saved);
    }

    @PutMapping
    public CourseDTO updateCourse(@Valid @RequestBody CourseDTO courseDto) {
        Course c = CourseMapper.toEntity(courseDto);
        Course saved = courseService.saveCourse(c);
        return CourseMapper.toDto(saved);
    }

    @DeleteMapping("/{id}")
    public void deleteCourse(@PathVariable Long id) {
        courseService.deleteCourse(id);
    }
}
