package tn.esprit.studentmanagement.controllers;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import tn.esprit.studentmanagement.dto.CourseDTO;
import tn.esprit.studentmanagement.services.ICourseService;

import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class CourseControllerTest {
    private MockMvc mockMvc;
    private final ObjectMapper objectMapper = new ObjectMapper();
    @Mock
    private ICourseService courseService;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        mockMvc = MockMvcBuilders.standaloneSetup(new CourseController(courseService)).build();
    }

    private CourseDTO course() {
        CourseDTO dto = new CourseDTO();
        dto.setIdCourse(1L);
        dto.setName("DevOps");
        dto.setCode("DEVOPS-101");
        dto.setCredit(5);
        return dto;
    }

    @Test
    void getsAllCourses() throws Exception {
        when(courseService.getAllCourses()).thenReturn(List.of(course()));
        mockMvc.perform(get("/courses"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].code").value("DEVOPS-101"));
    }

    @Test
    void getsCourse() throws Exception {
        when(courseService.getCourseById(1L)).thenReturn(course());
        mockMvc.perform(get("/courses/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.idCourse").value(1));
    }

    @Test
    void createsCourse() throws Exception {
        when(courseService.saveCourse(any())).thenReturn(course());
        mockMvc.perform(post("/courses").contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(course())))
                .andExpect(status().isCreated());
    }

    @Test
    void updatesCourse() throws Exception {
        when(courseService.saveCourse(any())).thenReturn(course());
        mockMvc.perform(put("/courses/1").contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(course())))
                .andExpect(status().isOk());
    }

    @Test
    void deletesCourse() throws Exception {
        mockMvc.perform(delete("/courses/1")).andExpect(status().isNoContent());
        verify(courseService).deleteCourse(1L);
    }
}
