package tn.esprit.studentmanagement.controllers;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;
import tn.esprit.studentmanagement.dto.CourseDTO;
import tn.esprit.studentmanagement.entities.Course;
import tn.esprit.studentmanagement.mapper.CourseMapper;
import tn.esprit.studentmanagement.services.ICourseService;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(CourseController.class)
@WithMockUser(roles = "API")
@SuppressWarnings("null")
class CourseControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private ICourseService courseService;

    @MockitoBean
    private CourseMapper courseMapper;

    private Course course;
    private CourseDTO courseDTO;

    @BeforeEach
    void setUp() {
        course = new Course();
        course.setIdCourse(1L);
        course.setName("DevOps");

        courseDTO = new CourseDTO();
        courseDTO.setIdCourse(1L);
        courseDTO.setName("DevOps");
        courseDTO.setCode("DEV-101");
        courseDTO.setCredit(3);
    }

    @Test
    void create_ShouldReturnCreated() throws Exception {
        when(courseMapper.toEntity(any(CourseDTO.class))).thenReturn(course);
        when(courseService.saveCourse(any(Course.class))).thenReturn(course);
        when(courseMapper.toDto(any(Course.class))).thenReturn(courseDTO);

        mockMvc.perform(post("/api/courses")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"DevOps\",\"code\":\"DEV-101\",\"credit\":3}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.name").value("DevOps"));
    }

    @Test
    void assignDepartment_ShouldReturnOk() throws Exception {
        when(courseService.assignDepartment(1L, 2L)).thenReturn(course);
        when(courseMapper.toDto(course)).thenReturn(courseDTO);

        mockMvc.perform(put("/api/courses/1/assign/2").with(csrf()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("DevOps"));
    }
}
