package tn.esprit.studentmanagement.controllers;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import tn.esprit.studentmanagement.dto.EnrollmentDTO;
import tn.esprit.studentmanagement.services.IEnrollment;

import java.util.Arrays;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class EnrollmentControllerTest {

    private MockMvc mockMvc;

    @Mock
    private IEnrollment enrollmentService;

    @InjectMocks
    private EnrollmentController enrollmentController;

    private ObjectMapper objectMapper = new ObjectMapper();

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        mockMvc = MockMvcBuilders.standaloneSetup(enrollmentController).build();
    }

    @Test
    void testGetAllEnrollment() throws Exception {
        EnrollmentDTO e1 = new EnrollmentDTO();
        e1.setIdEnrollment(1L);
        when(enrollmentService.getAllEnrollments()).thenReturn(Arrays.asList(e1));

        mockMvc.perform(get("/enrollments"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].idEnrollment").value(1));

        verify(enrollmentService, times(1)).getAllEnrollments();
    }

    @Test
    void testGetEnrollment() throws Exception {
        EnrollmentDTO e1 = new EnrollmentDTO();
        e1.setIdEnrollment(1L);
        when(enrollmentService.getEnrollmentById(1L)).thenReturn(e1);

        mockMvc.perform(get("/enrollments/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.idEnrollment").value(1));

        verify(enrollmentService, times(1)).getEnrollmentById(1L);
    }

    @Test
    void testCreateEnrollment() throws Exception {
        EnrollmentDTO e1 = new EnrollmentDTO();
        e1.setGrade(15.5);
        when(enrollmentService.saveEnrollment(any(EnrollmentDTO.class))).thenReturn(e1);

        mockMvc.perform(post("/enrollments")
                .contentType(java.util.Objects.requireNonNull(MediaType.APPLICATION_JSON))
                .content(java.util.Objects.requireNonNull(objectMapper.writeValueAsString(e1))))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.grade").value(15.5));

        verify(enrollmentService, times(1)).saveEnrollment(any(EnrollmentDTO.class));
    }

    @Test
    void testUpdateEnrollment() throws Exception {
        EnrollmentDTO e1 = new EnrollmentDTO();
        e1.setGrade(15.5);
        when(enrollmentService.saveEnrollment(any(EnrollmentDTO.class))).thenReturn(e1);

        mockMvc.perform(put("/enrollments/1")
                .contentType(java.util.Objects.requireNonNull(MediaType.APPLICATION_JSON))
                .content(java.util.Objects.requireNonNull(objectMapper.writeValueAsString(e1))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.grade").value(15.5));

        verify(enrollmentService, times(1)).saveEnrollment(any(EnrollmentDTO.class));
    }

    @Test
    void testDeleteEnrollment() throws Exception {
        doNothing().when(enrollmentService).deleteEnrollment(anyLong());

        mockMvc.perform(delete("/enrollments/1"))
                .andExpect(status().isNoContent());

        verify(enrollmentService, times(1)).deleteEnrollment(1L);
    }
}
