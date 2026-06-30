package tn.esprit.studentmanagement.services;

import tn.esprit.studentmanagement.dto.CourseDTO;
import java.util.List;

public interface ICourseService {
    List<CourseDTO> getAllCourses();
    CourseDTO getCourseById(Long id);
    CourseDTO saveCourse(CourseDTO courseDTO);
    void deleteCourse(Long id);
}
