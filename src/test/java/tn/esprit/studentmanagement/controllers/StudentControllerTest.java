package tn.esprit.studentmanagement.controllers;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.data.domain.PageImpl;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;
import tn.esprit.studentmanagement.dto.StudentDTO;
import tn.esprit.studentmanagement.entities.Student;
import tn.esprit.studentmanagement.mapper.StudentMapper;
import tn.esprit.studentmanagement.services.IStudentService;

import java.time.LocalDate;
import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(StudentController.class)
@WithMockUser(roles = "API")
@SuppressWarnings({"null"})
class StudentControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private IStudentService studentService;

    @MockitoBean
    private StudentMapper studentMapper;

    private Student student;
    private StudentDTO studentDTO;

    @BeforeEach
    void setUp() {
        student = new Student();
        student.setIdStudent(1L);
        student.setFirstName("Alice");

        studentDTO = new StudentDTO();
        studentDTO.setIdStudent(1L);
        studentDTO.setFirstName("Alice");
        studentDTO.setLastName("Martin");
        studentDTO.setEmail("alice@example.com");
        studentDTO.setDateOfBirth(LocalDate.of(2000, 1, 1));
    }

    @Test
    void create_ShouldReturnCreated() throws Exception {
        when(studentMapper.toEntity(any(StudentDTO.class))).thenReturn(student);
        when(studentService.saveStudent(any(Student.class))).thenReturn(student);
        when(studentMapper.toDto(any(Student.class))).thenReturn(studentDTO);

        mockMvc.perform(post("/api/students")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"firstName\":\"Alice\",\"lastName\":\"Martin\",\"email\":\"alice@example.com\",\"dateOfBirth\":\"2000-01-01\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.firstName").value("Alice"));
    }

    @Test
    void getById_ShouldReturnStudent() throws Exception {
        when(studentService.getStudentById(1L)).thenReturn(student);
        when(studentMapper.toDto(student)).thenReturn(studentDTO);

        mockMvc.perform(get("/api/students/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.firstName").value("Alice"));
    }

    @Test
    void delete_ShouldReturnNoContent() throws Exception {
        doNothing().when(studentService).deleteStudent(1L);

        mockMvc.perform(delete("/api/students/1").with(csrf()))
                .andExpect(status().isNoContent());
    }

    @Test
    void search_ShouldReturnPage() throws Exception {
        when(studentService.searchStudents(any(), any(), any(), any(), anyInt(), anyInt()))
                .thenReturn(new PageImpl<>(List.of(student)));
        when(studentMapper.toDto(any(Student.class))).thenReturn(studentDTO);

        mockMvc.perform(get("/api/students/search")
                        .param("name", "Alice"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content[0].firstName").value("Alice"));
    }
}
