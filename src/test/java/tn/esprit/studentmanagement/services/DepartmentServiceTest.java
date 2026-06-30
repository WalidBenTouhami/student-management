package tn.esprit.studentmanagement.services;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import tn.esprit.studentmanagement.dto.DepartmentDTO;
import tn.esprit.studentmanagement.entities.Department;
import tn.esprit.studentmanagement.repositories.DepartmentRepository;
import tn.esprit.studentmanagement.utils.DtoMapper;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class DepartmentServiceTest {

    @Mock
    private DepartmentRepository departmentRepository;

    @Mock
    private DtoMapper dtoMapper;

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
        
        DepartmentDTO dto1 = new DepartmentDTO();
        dto1.setIdDepartment(1L);
        DepartmentDTO dto2 = new DepartmentDTO();
        dto2.setIdDepartment(2L);
        when(dtoMapper.toDepartmentDTO(d1)).thenReturn(dto1);
        when(dtoMapper.toDepartmentDTO(d2)).thenReturn(dto2);

        List<DepartmentDTO> departments = departmentService.getAllDepartments();
        assertEquals(2, departments.size());
        verify(departmentRepository, times(1)).findAll();
    }

    @Test
    void testGetDepartmentById() {
        Department d1 = new Department();
        d1.setIdDepartment(1L);
        when(departmentRepository.findById(1L)).thenReturn(Optional.of(d1));
        
        DepartmentDTO dto1 = new DepartmentDTO();
        dto1.setIdDepartment(1L);
        when(dtoMapper.toDepartmentDTO(d1)).thenReturn(dto1);

        DepartmentDTO result = departmentService.getDepartmentById(1L);
        assertNotNull(result);
        assertEquals(1L, result.getIdDepartment());
        verify(departmentRepository, times(1)).findById(1L);
    }

    @Test
    void testSaveDepartment() {
        Department d1 = new Department();
        d1.setName("Math");
        DepartmentDTO dto1 = new DepartmentDTO();
        dto1.setName("Math");
        
        when(dtoMapper.toDepartmentEntity(dto1)).thenReturn(d1);
        when(departmentRepository.save(d1)).thenReturn(d1);
        when(dtoMapper.toDepartmentDTO(d1)).thenReturn(dto1);

        DepartmentDTO result = departmentService.saveDepartment(dto1);
        assertNotNull(result);
        assertEquals("Math", result.getName());
        verify(departmentRepository, times(1)).save(d1);
    }

    @Test
    void testDeleteDepartment() {
        when(departmentRepository.existsById(1L)).thenReturn(true);
        doNothing().when(departmentRepository).deleteById(1L);
        departmentService.deleteDepartment(1L);
        verify(departmentRepository, times(1)).deleteById(1L);
    }
}
