package tn.esprit.studentmanagement.controllers;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import tn.esprit.studentmanagement.dto.DashboardStatsDTO;
import tn.esprit.studentmanagement.dto.EnrollmentReportDTO;
import tn.esprit.studentmanagement.services.IStatsService;

import java.util.List;

@RestController
@RequestMapping("/api/stats")
@RequiredArgsConstructor
public class StatsController {

    private final IStatsService statsService;

    @GetMapping("/dashboard")
    public ResponseEntity<DashboardStatsDTO> getDashboardStats() {
        return ResponseEntity.ok(statsService.getDashboardStats());
    }

    @GetMapping("/report")
    public ResponseEntity<List<EnrollmentReportDTO>> getEnrollmentReport() {
        return ResponseEntity.ok(statsService.getEnrollmentReport());
    }
}
