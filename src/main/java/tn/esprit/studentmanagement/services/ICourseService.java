package tn.esprit.studentmanagement.services;

import org.springframework.data.domain.Page;
import tn.esprit.studentmanagement.entities.Course;
import java.util.List;

public interface ICourseService {
    List<Course> getAllCourses();
    Page<Course> getAllCoursesPaginated(int page, int size);
    Course getCourseById(Long id);
    Course saveCourse(Course course);
    void deleteCourse(Long id);
    Course assignDepartment(Long id, Long departmentId);
}
