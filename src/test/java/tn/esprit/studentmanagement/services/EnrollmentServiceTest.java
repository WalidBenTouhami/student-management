package tn.esprit.studentmanagement.services;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import tn.esprit.studentmanagement.dto.EnrollmentDTO;
import tn.esprit.studentmanagement.entities.Enrollment;
import tn.esprit.studentmanagement.repositories.EnrollmentRepository;
import tn.esprit.studentmanagement.utils.DtoMapper;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class EnrollmentServiceTest {

    @Mock
    private EnrollmentRepository enrollmentRepository;

    @Mock
    private DtoMapper dtoMapper;

    @InjectMocks
    private EnrollmentService enrollmentService;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void testGetAllEnrollments() {
        Enrollment e1 = new Enrollment();
        e1.setIdEnrollment(1L);
        Enrollment e2 = new Enrollment();
        e2.setIdEnrollment(2L);
        when(enrollmentRepository.findAll()).thenReturn(Arrays.asList(e1, e2));
        
        EnrollmentDTO dto1 = new EnrollmentDTO();
        dto1.setIdEnrollment(1L);
        EnrollmentDTO dto2 = new EnrollmentDTO();
        dto2.setIdEnrollment(2L);
        when(dtoMapper.toEnrollmentDTO(e1)).thenReturn(dto1);
        when(dtoMapper.toEnrollmentDTO(e2)).thenReturn(dto2);

        List<EnrollmentDTO> enrollments = enrollmentService.getAllEnrollments();
        assertEquals(2, enrollments.size());
        verify(enrollmentRepository, times(1)).findAll();
    }

    @Test
    void testGetEnrollmentById() {
        Enrollment e1 = new Enrollment();
        e1.setIdEnrollment(1L);
        when(enrollmentRepository.findById(1L)).thenReturn(Optional.of(e1));
        
        EnrollmentDTO dto1 = new EnrollmentDTO();
        dto1.setIdEnrollment(1L);
        when(dtoMapper.toEnrollmentDTO(e1)).thenReturn(dto1);

        EnrollmentDTO result = enrollmentService.getEnrollmentById(1L);
        assertNotNull(result);
        assertEquals(1L, result.getIdEnrollment());
        verify(enrollmentRepository, times(1)).findById(1L);
    }

    @Test
    void testSaveEnrollment() {
        Enrollment e1 = new Enrollment();
        e1.setGrade(15.5);
        EnrollmentDTO dto1 = new EnrollmentDTO();
        dto1.setGrade(15.5);
        
        when(dtoMapper.toEnrollmentEntity(dto1)).thenReturn(e1);
        when(enrollmentRepository.save(e1)).thenReturn(e1);
        when(dtoMapper.toEnrollmentDTO(e1)).thenReturn(dto1);

        EnrollmentDTO result = enrollmentService.saveEnrollment(dto1);
        assertNotNull(result);
        assertEquals(15.5, result.getGrade());
        verify(enrollmentRepository, times(1)).save(e1);
    }

    @Test
    void testDeleteEnrollment() {
        when(enrollmentRepository.existsById(1L)).thenReturn(true);
        doNothing().when(enrollmentRepository).deleteById(1L);
        enrollmentService.deleteEnrollment(1L);
        verify(enrollmentRepository, times(1)).deleteById(1L);
    }

    @Test
    void rejectsUpdateMissingEnrollment() {
        EnrollmentDTO input = new EnrollmentDTO();
        input.setIdEnrollment(999L);
        when(enrollmentRepository.existsById(999L)).thenReturn(false);
        assertThrows(tn.esprit.studentmanagement.exceptions.ResourceNotFoundException.class, () -> enrollmentService.saveEnrollment(input));
    }

    @Test
    void rejectsDeleteMissingEnrollment() {
        when(enrollmentRepository.existsById(999L)).thenReturn(false);
        assertThrows(tn.esprit.studentmanagement.exceptions.ResourceNotFoundException.class, () -> enrollmentService.deleteEnrollment(999L));
    }
}
