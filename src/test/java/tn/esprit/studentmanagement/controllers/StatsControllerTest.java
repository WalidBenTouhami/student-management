package tn.esprit.studentmanagement.controllers;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;
import tn.esprit.studentmanagement.dto.DashboardStatsDTO;
import tn.esprit.studentmanagement.dto.EnrollmentReportDTO;
import tn.esprit.studentmanagement.services.IStatsService;

import java.util.HashMap;
import java.util.List;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(StatsController.class)
@WithMockUser(roles = "API")
@SuppressWarnings({"null", "deprecation"})
class StatsControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private IStatsService statsService;

    @Test
    void getDashboardStats_ShouldReturnStats() throws Exception {
        DashboardStatsDTO stats = DashboardStatsDTO.builder()
                .totalStudents(10)
                .totalCourses(5)
                .totalDepartments(2)
                .totalEnrollments(15)
                .averageGrade(14.5)
                .statusBreakdown(new HashMap<>())
                .enrollmentsByCourse(new HashMap<>())
                .enrollmentsByDepartment(new HashMap<>())
                .build();

        when(statsService.getDashboardStats()).thenReturn(stats);

        mockMvc.perform(get("/api/stats/dashboard"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalStudents").value(10))
                .andExpect(jsonPath("$.averageGrade").value(14.5));
    }

    @Test
    void getEnrollmentReport_ShouldReturnReport() throws Exception {
        EnrollmentReportDTO row = new EnrollmentReportDTO("IT", "Java", "JA-101", 3L, 5L, 15.0);
        when(statsService.getEnrollmentReport()).thenReturn(List.of(row));

        mockMvc.perform(get("/api/stats/report"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].departmentName").value("IT"))
                .andExpect(jsonPath("$[0].courseName").value("Java"));
    }
}
