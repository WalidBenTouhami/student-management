package tn.esprit.studentmanagement.services;

import tn.esprit.studentmanagement.dto.DashboardStatsDTO;
import tn.esprit.studentmanagement.dto.EnrollmentReportDTO;
import java.util.List;

public interface IStatsService {
    DashboardStatsDTO getDashboardStats();
    List<EnrollmentReportDTO> getEnrollmentReport();
}
