package tn.esprit.studentmanagement.controllers;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;
import tn.esprit.studentmanagement.dto.EnrollmentDTO;
import tn.esprit.studentmanagement.entities.Enrollment;
import tn.esprit.studentmanagement.mapper.EnrollmentMapper;
import tn.esprit.studentmanagement.services.IEnrollmentService;

import java.time.LocalDate;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(EnrollmentController.class)
@WithMockUser(roles = "API")
@SuppressWarnings("null")
class EnrollmentControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private IEnrollmentService enrollmentService;

    @MockitoBean
    private EnrollmentMapper enrollmentMapper;

    private Enrollment enrollment;
    private EnrollmentDTO enrollmentDTO;

    @BeforeEach
    void setUp() {
        enrollment = new Enrollment();
        enrollment.setIdEnrollment(1L);
        enrollment.setStatus("ACTIVE");

        enrollmentDTO = new EnrollmentDTO();
        enrollmentDTO.setIdEnrollment(1L);
        enrollmentDTO.setStatus("ACTIVE");
        enrollmentDTO.setEnrollmentDate(LocalDate.of(2025, 1, 1));
        enrollmentDTO.setStudentId(1L);
        enrollmentDTO.setCourseId(1L);
    }

    @Test
    void create_ShouldReturnCreated() throws Exception {
        when(enrollmentMapper.toEntity(any(EnrollmentDTO.class))).thenReturn(enrollment);
        when(enrollmentService.saveEnrollment(any(Enrollment.class))).thenReturn(enrollment);
        when(enrollmentMapper.toDto(any(Enrollment.class))).thenReturn(enrollmentDTO);

        mockMvc.perform(post("/api/enrollments")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"enrollmentDate\":\"2025-01-01\",\"status\":\"ACTIVE\",\"studentId\":1,\"courseId\":1}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.status").value("ACTIVE"));
    }

    @Test
    void getById_ShouldReturnEnrollment() throws Exception {
        when(enrollmentService.getEnrollmentById(1L)).thenReturn(enrollment);
        when(enrollmentMapper.toDto(enrollment)).thenReturn(enrollmentDTO);

        mockMvc.perform(get("/api/enrollments/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("ACTIVE"));
    }

    @Test
    void delete_ShouldReturnNoContent() throws Exception {
        doNothing().when(enrollmentService).deleteEnrollment(1L);

        mockMvc.perform(delete("/api/enrollments/1").with(csrf()))
                .andExpect(status().isNoContent());
    }
}
