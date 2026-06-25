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
import tn.esprit.studentmanagement.entities.Enrollment;
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
    void testGetAllEnrollments() throws Exception {
        Enrollment e1 = new Enrollment();
        e1.setIdEnrollment(1L);
        when(enrollmentService.getAllEnrollments()).thenReturn(Arrays.asList(e1));

        mockMvc.perform(get("/enrollments/getAllEnrollments"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].idEnrollment").value(1));

        verify(enrollmentService, times(1)).getAllEnrollments();
    }

    @Test
    void testGetEnrollment() throws Exception {
        Enrollment e1 = new Enrollment();
        e1.setIdEnrollment(1L);
        when(enrollmentService.getEnrollmentById(1L)).thenReturn(e1);

        mockMvc.perform(get("/enrollments/getEnrollment/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.idEnrollment").value(1));

        verify(enrollmentService, times(1)).getEnrollmentById(1L);
    }

    @Test
    void testCreateEnrollment() throws Exception {
        Enrollment e1 = new Enrollment();
        e1.setGrade(15.5);
        when(enrollmentService.saveEnrollment(any(Enrollment.class))).thenReturn(e1);

        mockMvc.perform(post("/enrollments/createEnrollment")
                .contentType(java.util.Objects.requireNonNull(MediaType.APPLICATION_JSON))
                .content(java.util.Objects.requireNonNull(objectMapper.writeValueAsString(e1))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.grade").value(15.5));

        verify(enrollmentService, times(1)).saveEnrollment(any(Enrollment.class));
    }

    @Test
    void testUpdateEnrollment() throws Exception {
        Enrollment e1 = new Enrollment();
        e1.setGrade(15.5);
        when(enrollmentService.saveEnrollment(any(Enrollment.class))).thenReturn(e1);

        mockMvc.perform(put("/enrollments/updateEnrollment")
                .contentType(java.util.Objects.requireNonNull(MediaType.APPLICATION_JSON))
                .content(java.util.Objects.requireNonNull(objectMapper.writeValueAsString(e1))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.grade").value(15.5));

        verify(enrollmentService, times(1)).saveEnrollment(any(Enrollment.class));
    }

    @Test
    void testDeleteEnrollment() throws Exception {
        doNothing().when(enrollmentService).deleteEnrollment(anyLong());

        mockMvc.perform(delete("/enrollments/deleteEnrollment/1"))
                .andExpect(status().isOk());

        verify(enrollmentService, times(1)).deleteEnrollment(1L);
    }
}
