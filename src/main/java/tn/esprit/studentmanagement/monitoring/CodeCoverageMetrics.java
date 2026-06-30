package tn.esprit.studentmanagement.monitoring;

import io.micrometer.core.instrument.Gauge;
import io.micrometer.core.instrument.MeterRegistry;
import jakarta.annotation.PostConstruct;
import org.jacoco.core.analysis.Analyzer;
import org.jacoco.core.analysis.CoverageBuilder;
import org.jacoco.core.analysis.IClassCoverage;
import org.jacoco.core.data.ExecutionDataReader;
import org.jacoco.core.data.ExecutionDataStore;
import org.jacoco.core.data.SessionInfoStore;
import org.springframework.stereotype.Component;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;

@Component
public class CodeCoverageMetrics {

    private final MeterRegistry registry;
    private static final String EXEC_FILE_PATH = "target/jacoco.exec";

    public CodeCoverageMetrics(MeterRegistry registry) {
        this.registry = registry;
    }

    @PostConstruct
    public void registerCoverageMetric() {
        Gauge.builder("student_management_coverage_percent", this::calculateCoveragePercentage)
                .description("Pourcentage de couverture de code JaCoCo")
                .baseUnit("percent")
                .register(registry);
    }

    private double calculateCoveragePercentage() {
        File execFile = new File(EXEC_FILE_PATH);
        if (!execFile.exists()) {
            return 0.0;
        }

        try (FileInputStream fis = new FileInputStream(execFile)) {
            ExecutionDataStore executionData = new ExecutionDataStore();
            SessionInfoStore sessionInfo = new SessionInfoStore();

            ExecutionDataReader reader = new ExecutionDataReader(fis);
            reader.setExecutionDataVisitor(executionData);
            reader.setSessionInfoVisitor(sessionInfo);
            reader.read();

            CoverageBuilder coverageBuilder = new CoverageBuilder();
            Analyzer analyzer = new Analyzer(executionData, coverageBuilder);

            // Analyse toutes les classes compilées
            File classesDir = new File("target/classes");
            if (classesDir.exists()) {
                analyzer.analyzeAll(classesDir);
            }

            int totalInstructions = 0;
            int coveredInstructions = 0;

            for (IClassCoverage classCoverage : coverageBuilder.getClasses()) {
                totalInstructions += classCoverage.getInstructionCounter().getTotalCount();
                coveredInstructions += classCoverage.getInstructionCounter().getCoveredCount();
            }

            return totalInstructions > 0 
                    ? Math.round((coveredInstructions * 100.0) / totalInstructions * 100.0) / 100.0 
                    : 0.0;

        } catch (IOException e) {
            return 0.0;
        }
    }
}
