package tn.esprit.studentmanagement.services;

import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tn.esprit.studentmanagement.entities.Course;
import tn.esprit.studentmanagement.exception.ResourceNotFoundException;
import tn.esprit.studentmanagement.repositories.CourseRepository;

import java.util.List;

@Service
@RequiredArgsConstructor
@SuppressWarnings("null")
@Transactional
public class CourseService implements ICourseService {

    private final CourseRepository courseRepository;
    private final tn.esprit.studentmanagement.repositories.DepartmentRepository departmentRepository;

    @Override
    @Transactional(readOnly = true)
    public List<Course> getAllCourses() {
        return courseRepository.findAll(Sort.by("name"));
    }

    @Override
    @Transactional(readOnly = true)
    public Page<Course> getAllCoursesPaginated(int page, int size) {
        return courseRepository.findAll(PageRequest.of(page, size, Sort.by("name")));
    }

    @Override
    @Transactional(readOnly = true)
    public Course getCourseById(Long id) {
        return courseRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Course not found: " + id));
    }

    @Override
    public Course saveCourse(Course course) {
        return courseRepository.save(course);
    }

    @Override
    public void deleteCourse(Long id) {
        if (!courseRepository.existsById(id)) {
            throw new ResourceNotFoundException("Course not found: " + id);
        }
        courseRepository.deleteById(id);
    }

    @Override
    public Course assignDepartment(Long id, Long departmentId) {
        Course course = getCourseById(id);
        tn.esprit.studentmanagement.entities.Department department = departmentRepository.findById(departmentId)
                .orElseThrow(() -> new ResourceNotFoundException("Department not found: " + departmentId));
        course.setDepartment(department);
        return courseRepository.save(course);
    }
}
