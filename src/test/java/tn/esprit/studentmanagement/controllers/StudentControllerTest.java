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
import tn.esprit.studentmanagement.dto.StudentDTO;
import tn.esprit.studentmanagement.services.IStudentService;

import java.util.Arrays;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class StudentControllerTest {

    private MockMvc mockMvc;

    @Mock
    private IStudentService studentService;

    @InjectMocks
    private StudentController studentController;

    private ObjectMapper objectMapper = new ObjectMapper();

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        mockMvc = MockMvcBuilders.standaloneSetup(studentController).build();
    }

    @Test
    void testGetAllStudents() throws Exception {
        StudentDTO s1 = new StudentDTO();
        s1.setIdStudent(1L);
        when(studentService.getAllStudents()).thenReturn(Arrays.asList(s1));

        mockMvc.perform(get("/students"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].idStudent").value(1));

        verify(studentService, times(1)).getAllStudents();
    }

    @Test
    void testGetStudent() throws Exception {
        StudentDTO s1 = new StudentDTO();
        s1.setIdStudent(1L);
        when(studentService.getStudentById(1L)).thenReturn(s1);

        mockMvc.perform(get("/students/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.idStudent").value(1));

        verify(studentService, times(1)).getStudentById(1L);
    }

    @Test
    void testCreateStudent() throws Exception {
        StudentDTO s1 = new StudentDTO();
        s1.setFirstName("John");
        when(studentService.saveStudent(any(StudentDTO.class))).thenReturn(s1);

        mockMvc.perform(post("/students")
                .contentType(java.util.Objects.requireNonNull(MediaType.APPLICATION_JSON))
                .content(java.util.Objects.requireNonNull(objectMapper.writeValueAsString(s1))))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.firstName").value("John"));

        verify(studentService, times(1)).saveStudent(any(StudentDTO.class));
    }

    @Test
    void testUpdateStudent() throws Exception {
        StudentDTO s1 = new StudentDTO();
        s1.setFirstName("John");
        when(studentService.saveStudent(any(StudentDTO.class))).thenReturn(s1);

        mockMvc.perform(put("/students/1")
                .contentType(java.util.Objects.requireNonNull(MediaType.APPLICATION_JSON))
                .content(java.util.Objects.requireNonNull(objectMapper.writeValueAsString(s1))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.firstName").value("John"));

        verify(studentService, times(1)).saveStudent(any(StudentDTO.class));
    }

    @Test
    void testDeleteStudent() throws Exception {
        doNothing().when(studentService).deleteStudent(anyLong());

        mockMvc.perform(delete("/students/1"))
                .andExpect(status().isNoContent());

        verify(studentService, times(1)).deleteStudent(1L);
    }
}
