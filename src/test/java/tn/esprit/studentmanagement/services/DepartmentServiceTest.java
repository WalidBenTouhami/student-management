package tn.esprit.studentmanagement.services;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import tn.esprit.studentmanagement.entities.Department;
import tn.esprit.studentmanagement.repositories.DepartmentRepository;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class DepartmentServiceTest {

    @Mock
    private DepartmentRepository departmentRepository;

    @InjectMocks
    private DepartmentService departmentService;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void testGetAllDepartments() {
        Department d1 = new Department();
        d1.setIdDepartment(1L);
        Department d2 = new Department();
        d2.setIdDepartment(2L);
        when(departmentRepository.findAll()).thenReturn(Arrays.asList(d1, d2));

        List<Department> departments = departmentService.getAllDepartments();
        assertEquals(2, departments.size());
        verify(departmentRepository, times(1)).findAll();
    }

    @Test
    void testGetDepartmentById() {
        Department d1 = new Department();
        d1.setIdDepartment(1L);
        when(departmentRepository.findById(1L)).thenReturn(Optional.of(d1));

        Department result = departmentService.getDepartmentById(1L);
        assertNotNull(result);
        assertEquals(1L, result.getIdDepartment());
        verify(departmentRepository, times(1)).findById(1L);
    }

    @Test
    void testSaveDepartment() {
        Department d1 = new Department();
        d1.setName("Computer Science");
        when(departmentRepository.save(d1)).thenReturn(d1);

        Department result = departmentService.saveDepartment(d1);
        assertNotNull(result);
        assertEquals("Computer Science", result.getName());
        verify(departmentRepository, times(1)).save(d1);
    }

    @Test
    void testDeleteDepartment() {
        doNothing().when(departmentRepository).deleteById(1L);
        departmentService.deleteDepartment(1L);
        verify(departmentRepository, times(1)).deleteById(1L);
    }
}
