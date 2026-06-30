package tn.esprit.studentmanagement.services;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tn.esprit.studentmanagement.dto.CourseDTO;
import tn.esprit.studentmanagement.entities.Course;
import tn.esprit.studentmanagement.exceptions.ResourceNotFoundException;
import tn.esprit.studentmanagement.repositories.CourseRepository;
import tn.esprit.studentmanagement.utils.DtoMapper;

import java.util.List;

@Service
@Transactional
public class CourseService implements ICourseService {
    private static final String COURSE_NOT_FOUND_MSG = "Course not found with ID: ";
    private final CourseRepository courseRepository;
    private final DtoMapper dtoMapper;

    public CourseService(CourseRepository courseRepository, DtoMapper dtoMapper) {
        this.courseRepository = courseRepository;
        this.dtoMapper = dtoMapper;
    }

    @Override
    @Transactional(readOnly = true)
    public List<CourseDTO> getAllCourses() {
        return courseRepository.findAll().stream().map(dtoMapper::toCourseDTO).toList();
    }

    @Override
    @Transactional(readOnly = true)
    public CourseDTO getCourseById(Long id) {
        return dtoMapper.toCourseDTO(courseRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException(COURSE_NOT_FOUND_MSG + id)));
    }

    @Override
    public CourseDTO saveCourse(CourseDTO courseDTO) {
        if (courseDTO.getIdCourse() != null && !courseRepository.existsById(courseDTO.getIdCourse())) {
            throw new ResourceNotFoundException(COURSE_NOT_FOUND_MSG + courseDTO.getIdCourse());
        }
        if (courseDTO.getIdCourse() == null && courseRepository.existsByCode(courseDTO.getCode())) {
            throw new IllegalArgumentException("A course with this code already exists.");
        }
        Course saved = courseRepository.save(dtoMapper.toCourseEntity(courseDTO));
        return dtoMapper.toCourseDTO(saved);
    }

    @Override
    public void deleteCourse(Long id) {
        if (!courseRepository.existsById(id)) {
            throw new ResourceNotFoundException(COURSE_NOT_FOUND_MSG + id);
        }
        courseRepository.deleteById(id);
    }
}
