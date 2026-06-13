package tn.esprit.studentmanagement.services;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import tn.esprit.studentmanagement.entities.Department;
import tn.esprit.studentmanagement.exception.ResourceNotFoundException;
import tn.esprit.studentmanagement.repositories.DepartmentRepository;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class DepartmentServiceTest {

    @Mock
    private DepartmentRepository departmentRepository;

    @InjectMocks
    private DepartmentService departmentService;

    private Department department;

    @BeforeEach
    void setUp() {
        department = new Department();
        department.setIdDepartment(1L);
        department.setName("IT");
    }

    @Test
    void getAllDepartments_ShouldReturnList() {
        when(departmentRepository.findAll(Sort.by("name"))).thenReturn(List.of(department));
        List<Department> result = departmentService.getAllDepartments();
        assertThat(result).hasSize(1);
    }

    @Test
    void getAllDepartmentsPaginated_ShouldReturnPage() {
        Page<Department> page = new PageImpl<>(List.of(department));
        when(departmentRepository.findAll(PageRequest.of(0, 10, Sort.by("name")))).thenReturn(page);
        Page<Department> result = departmentService.getAllDepartmentsPaginated(0, 10);
        assertThat(result.getContent()).hasSize(1);
    }

    @Test
    void getDepartmentById_WhenExists_ShouldReturnDepartment() {
        when(departmentRepository.findById(1L)).thenReturn(Optional.of(department));
        Department result = departmentService.getDepartmentById(1L);
        assertThat(result).isEqualTo(department);
    }

    @Test
    void getDepartmentById_WhenNotFound_ShouldThrowException() {
        when(departmentRepository.findById(99L)).thenReturn(Optional.empty());
        assertThatThrownBy(() -> departmentService.getDepartmentById(99L))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void saveDepartment_ShouldSave() {
        when(departmentRepository.save(department)).thenReturn(department);
        Department result = departmentService.saveDepartment(department);
        assertThat(result).isEqualTo(department);
    }

    @Test
    void deleteDepartment_WhenExists_ShouldDelete() {
        when(departmentRepository.existsById(1L)).thenReturn(true);
        doNothing().when(departmentRepository).deleteById(1L);
        departmentService.deleteDepartment(1L);
        verify(departmentRepository).deleteById(1L);
    }

    @Test
    void deleteDepartment_WhenNotFound_ShouldThrowException() {
        when(departmentRepository.existsById(99L)).thenReturn(false);
        assertThatThrownBy(() -> departmentService.deleteDepartment(99L))
                .isInstanceOf(ResourceNotFoundException.class);
    }
}
