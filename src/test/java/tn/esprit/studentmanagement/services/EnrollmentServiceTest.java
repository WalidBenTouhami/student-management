package tn.esprit.studentmanagement.services;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import tn.esprit.studentmanagement.entities.Enrollment;
import tn.esprit.studentmanagement.repositories.EnrollmentRepository;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class EnrollmentServiceTest {

    @Mock
    private EnrollmentRepository enrollmentRepository;

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

        List<Enrollment> enrollments = enrollmentService.getAllEnrollments();
        assertEquals(2, enrollments.size());
        verify(enrollmentRepository, times(1)).findAll();
    }

    @Test
    void testGetEnrollmentById() {
        Enrollment e1 = new Enrollment();
        e1.setIdEnrollment(1L);
        when(enrollmentRepository.findById(1L)).thenReturn(Optional.of(e1));

        Enrollment result = enrollmentService.getEnrollmentById(1L);
        assertNotNull(result);
        assertEquals(1L, result.getIdEnrollment());
        verify(enrollmentRepository, times(1)).findById(1L);
    }

    @Test
    void testSaveEnrollment() {
        Enrollment e1 = new Enrollment();
        e1.setGrade(15.5);
        when(enrollmentRepository.save(e1)).thenReturn(e1);

        Enrollment result = enrollmentService.saveEnrollment(e1);
        assertNotNull(result);
        assertEquals(15.5, result.getGrade());
        verify(enrollmentRepository, times(1)).save(e1);
    }

    @Test
    void testDeleteEnrollment() {
        doNothing().when(enrollmentRepository).deleteById(1L);
        enrollmentService.deleteEnrollment(1L);
        verify(enrollmentRepository, times(1)).deleteById(1L);
    }
}
