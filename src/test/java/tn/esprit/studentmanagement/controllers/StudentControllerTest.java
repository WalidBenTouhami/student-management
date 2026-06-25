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
import tn.esprit.studentmanagement.entities.Student;
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
        Student s1 = new Student();
        s1.setIdStudent(1L);
        when(studentService.getAllStudents()).thenReturn(Arrays.asList(s1));

        mockMvc.perform(get("/students/getAllStudents"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].idStudent").value(1));

        verify(studentService, times(1)).getAllStudents();
    }

    @Test
    void testGetStudent() throws Exception {
        Student s1 = new Student();
        s1.setIdStudent(1L);
        when(studentService.getStudentById(1L)).thenReturn(s1);

        mockMvc.perform(get("/students/getStudent/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.idStudent").value(1));

        verify(studentService, times(1)).getStudentById(1L);
    }

    @Test
    void testCreateStudent() throws Exception {
        Student s1 = new Student();
        s1.setFirstName("Alice");
        when(studentService.saveStudent(any(Student.class))).thenReturn(s1);

        mockMvc.perform(post("/students/createStudent")
                .contentType(java.util.Objects.requireNonNull(MediaType.APPLICATION_JSON))
                .content(java.util.Objects.requireNonNull(objectMapper.writeValueAsString(s1))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.firstName").value("Alice"));

        verify(studentService, times(1)).saveStudent(any(Student.class));
    }

    @Test
    void testUpdateStudent() throws Exception {
        Student s1 = new Student();
        s1.setFirstName("Alice");
        when(studentService.saveStudent(any(Student.class))).thenReturn(s1);

        mockMvc.perform(put("/students/updateStudent")
                .contentType(java.util.Objects.requireNonNull(MediaType.APPLICATION_JSON))
                .content(java.util.Objects.requireNonNull(objectMapper.writeValueAsString(s1))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.firstName").value("Alice"));

        verify(studentService, times(1)).saveStudent(any(Student.class));
    }

    @Test
    void testDeleteStudent() throws Exception {
        doNothing().when(studentService).deleteStudent(anyLong());

        mockMvc.perform(delete("/students/deleteStudent/1"))
                .andExpect(status().isOk());

        verify(studentService, times(1)).deleteStudent(1L);
    }
}
