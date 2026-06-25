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
import tn.esprit.studentmanagement.entities.Department;
import tn.esprit.studentmanagement.services.IDepartmentService;

import java.util.Arrays;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class DepartmentControllerTest {

    private MockMvc mockMvc;

    @Mock
    private IDepartmentService departmentService;

    @InjectMocks
    private DepartmentController departmentController;

    private ObjectMapper objectMapper = new ObjectMapper();

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        mockMvc = MockMvcBuilders.standaloneSetup(departmentController).build();
    }

    @Test
    void testGetAllDepartments() throws Exception {
        Department d1 = new Department();
        d1.setIdDepartment(1L);
        when(departmentService.getAllDepartments()).thenReturn(Arrays.asList(d1));

        mockMvc.perform(get("/departments/getAllDepartments"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].idDepartment").value(1));

        verify(departmentService, times(1)).getAllDepartments();
    }

    @Test
    void testGetDepartment() throws Exception {
        Department d1 = new Department();
        d1.setIdDepartment(1L);
        when(departmentService.getDepartmentById(1L)).thenReturn(d1);

        mockMvc.perform(get("/departments/getDepartment/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.idDepartment").value(1));

        verify(departmentService, times(1)).getDepartmentById(1L);
    }

    @Test
    void testCreateDepartment() throws Exception {
        Department d1 = new Department();
        d1.setName("Math");
        when(departmentService.saveDepartment(any(Department.class))).thenReturn(d1);

        mockMvc.perform(post("/departments/createDepartment")
                .contentType(java.util.Objects.requireNonNull(MediaType.APPLICATION_JSON))
                .content(java.util.Objects.requireNonNull(objectMapper.writeValueAsString(d1))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Math"));

        verify(departmentService, times(1)).saveDepartment(any(Department.class));
    }

    @Test
    void testUpdateDepartment() throws Exception {
        Department d1 = new Department();
        d1.setName("Math");
        when(departmentService.saveDepartment(any(Department.class))).thenReturn(d1);

        mockMvc.perform(put("/departments/updateDepartment")
                .contentType(java.util.Objects.requireNonNull(MediaType.APPLICATION_JSON))
                .content(java.util.Objects.requireNonNull(objectMapper.writeValueAsString(d1))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Math"));

        verify(departmentService, times(1)).saveDepartment(any(Department.class));
    }

    @Test
    void testDeleteDepartment() throws Exception {
        doNothing().when(departmentService).deleteDepartment(anyLong());

        mockMvc.perform(delete("/departments/deleteDepartment/1"))
                .andExpect(status().isOk());

        verify(departmentService, times(1)).deleteDepartment(1L);
    }
}
