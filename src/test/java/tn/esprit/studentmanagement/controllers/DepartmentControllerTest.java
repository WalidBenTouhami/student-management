package tn.esprit.studentmanagement.controllers;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;
import tn.esprit.studentmanagement.dto.DepartmentDTO;
import tn.esprit.studentmanagement.entities.Department;
import tn.esprit.studentmanagement.mapper.DepartmentMapper;
import tn.esprit.studentmanagement.services.IDepartmentService;

import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(DepartmentController.class)
@WithMockUser(roles = "API")
class DepartmentControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private IDepartmentService departmentService;

    @MockBean
    private DepartmentMapper departmentMapper;

    private Department department;
    private DepartmentDTO departmentDTO;

    @BeforeEach
    void setUp() {
        department = new Department();
        department.setIdDepartment(1L);
        department.setName("IT");

        departmentDTO = new DepartmentDTO();
        departmentDTO.setIdDepartment(1L);
        departmentDTO.setName("IT");
    }

    @Test
    void create_ShouldReturnCreated() throws Exception {
        when(departmentMapper.toEntity(any(DepartmentDTO.class))).thenReturn(department);
        when(departmentService.saveDepartment(any(Department.class))).thenReturn(department);
        when(departmentMapper.toDto(any(Department.class))).thenReturn(departmentDTO);

        mockMvc.perform(post("/api/departments")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"IT\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.name").value("IT"));
    }

    @Test
    void getById_ShouldReturnDepartment() throws Exception {
        when(departmentService.getDepartmentById(1L)).thenReturn(department);
        when(departmentMapper.toDto(department)).thenReturn(departmentDTO);

        mockMvc.perform(get("/api/departments/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("IT"));
    }

    @Test
    void delete_ShouldReturnNoContent() throws Exception {
        doNothing().when(departmentService).deleteDepartment(1L);

        mockMvc.perform(delete("/api/departments/1").with(csrf()))
                .andExpect(status().isNoContent());
    }
}
