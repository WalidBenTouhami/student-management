package tn.esprit.studentmanagement.services;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import tn.esprit.studentmanagement.dto.CourseDTO;
import tn.esprit.studentmanagement.entities.Course;
import tn.esprit.studentmanagement.exceptions.ResourceNotFoundException;
import tn.esprit.studentmanagement.repositories.CourseRepository;
import tn.esprit.studentmanagement.utils.DtoMapper;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class CourseServiceTest {
    @Mock
    private CourseRepository courseRepository;
    @Mock
    private DtoMapper dtoMapper;
    @InjectMocks
    private CourseService courseService;

    private Course course;
    private CourseDTO dto;

    @BeforeEach
    void setUp() {
        course = new Course();
        course.setIdCourse(1L);
        course.setCode("DEVOPS-101");
        dto = new CourseDTO();
        dto.setIdCourse(1L);
        dto.setCode("DEVOPS-101");
        dto.setName("DevOps");
        dto.setCredit(5);
    }

    @Test
    void getsAllCourses() {
        when(courseRepository.findAll()).thenReturn(List.of(course));
        when(dtoMapper.toCourseDTO(course)).thenReturn(dto);
        assertEquals(List.of(dto), courseService.getAllCourses());
    }

    @Test
    void getsCourseById() {
        when(courseRepository.findById(1L)).thenReturn(Optional.of(course));
        when(dtoMapper.toCourseDTO(course)).thenReturn(dto);
        assertEquals(dto, courseService.getCourseById(1L));
    }

    @Test
    void rejectsUnknownCourse() {
        when(courseRepository.findById(1L)).thenReturn(Optional.empty());
        assertThrows(ResourceNotFoundException.class, () -> courseService.getCourseById(1L));
    }

    @Test
    void createsCourse() {
        CourseDTO input = new CourseDTO();
        input.setCode("DEVOPS-101");
        input.setName("DevOps");
        input.setCredit(5);
        when(dtoMapper.toCourseEntity(input)).thenReturn(course);
        when(courseRepository.save(course)).thenReturn(course);
        when(dtoMapper.toCourseDTO(course)).thenReturn(dto);
        assertEquals(dto, courseService.saveCourse(input));
    }

    @Test
    void rejectsDuplicateCode() {
        CourseDTO input = new CourseDTO();
        input.setCode("DEVOPS-101");
        when(courseRepository.existsByCode("DEVOPS-101")).thenReturn(true);
        assertThrows(IllegalArgumentException.class, () -> courseService.saveCourse(input));
    }

    @Test
    void deletesExistingCourse() {
        when(courseRepository.existsById(1L)).thenReturn(true);
        courseService.deleteCourse(1L);
        verify(courseRepository).deleteById(1L);
    @Test
    void rejectsUpdateMissingCourse() {
        CourseDTO input = new CourseDTO();
        input.setIdCourse(999L);
        when(courseRepository.existsById(999L)).thenReturn(false);
        assertThrows(ResourceNotFoundException.class, () -> courseService.saveCourse(input));
    }

    @Test
    void rejectsDeleteMissingCourse() {
        when(courseRepository.existsById(999L)).thenReturn(false);
        assertThrows(ResourceNotFoundException.class, () -> courseService.deleteCourse(999L));
    }
}
