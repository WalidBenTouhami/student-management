package tn.esprit.studentmanagement.services;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import tn.esprit.studentmanagement.entities.Course;
import tn.esprit.studentmanagement.entities.Department;
import tn.esprit.studentmanagement.exception.ResourceNotFoundException;
import tn.esprit.studentmanagement.repositories.CourseRepository;
import tn.esprit.studentmanagement.repositories.DepartmentRepository;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class CourseServiceTest {

    @Mock
    private CourseRepository courseRepository;
    @Mock
    private DepartmentRepository departmentRepository;

    @InjectMocks
    private CourseService courseService;

    private Course course;

    @BeforeEach
    void setUp() {
        course = new Course();
        course.setIdCourse(1L);
        course.setName("DevOps");
        course.setCode("DEV-101");
        course.setCredit(3);
    }

    @Test
    void getAllCourses_ShouldReturnList() {
        when(courseRepository.findAll(Sort.by("name"))).thenReturn(List.of(course));

        List<Course> result = courseService.getAllCourses();

        assertThat(result).hasSize(1);
        verify(courseRepository).findAll(Sort.by("name"));
    }

    @Test
    void getAllCoursesPaginated_ShouldReturnPage() {
        Page<Course> page = new PageImpl<>(List.of(course));
        when(courseRepository.findAll(PageRequest.of(0, 10, Sort.by("name")))).thenReturn(page);

        Page<Course> result = courseService.getAllCoursesPaginated(0, 10);

        assertThat(result.getContent()).hasSize(1);
    }

    @Test
    void getCourseById_WhenExists_ShouldReturnCourse() {
        when(courseRepository.findById(1L)).thenReturn(Optional.of(course));

        Course result = courseService.getCourseById(1L);

        assertThat(result).isEqualTo(course);
    }

    @Test
    void getCourseById_WhenNotFound_ShouldThrowException() {
        when(courseRepository.findById(99L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> courseService.getCourseById(99L))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void saveCourse_ShouldSave() {
        when(courseRepository.save(course)).thenReturn(course);

        Course saved = courseService.saveCourse(course);

        assertThat(saved).isEqualTo(course);
    }

    @Test
    void deleteCourse_WhenExists_ShouldDelete() {
        when(courseRepository.existsById(1L)).thenReturn(true);
        doNothing().when(courseRepository).deleteById(1L);

        courseService.deleteCourse(1L);

        verify(courseRepository).deleteById(1L);
    }

    @Test
    void deleteCourse_WhenNotFound_ShouldThrowException() {
        when(courseRepository.existsById(99L)).thenReturn(false);

        assertThatThrownBy(() -> courseService.deleteCourse(99L))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void assignDepartment_ShouldLinkAndSave() {
        Department department = new Department();
        department.setIdDepartment(2L);
        department.setName("IT");

        when(courseRepository.findById(1L)).thenReturn(Optional.of(course));
        when(departmentRepository.findById(2L)).thenReturn(Optional.of(department));
        when(courseRepository.save(any(Course.class))).thenReturn(course);

        Course result = courseService.assignDepartment(1L, 2L);

        assertThat(result.getDepartment()).isEqualTo(department);
        verify(courseRepository).save(course);
    }
}
