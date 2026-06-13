### Multi-stage Dockerfile — optimized for Docker layer cache
# ─────────────────────────────────────────────────────────────
# STAGE 1 — Dependency cache
#   Copy pom.xml first, download dependencies, THEN copy sources.
#   This way, the "mvn dependency:go-offline" layer is only invalidated
#   when pom.xml changes — not on every source file change.
# ─────────────────────────────────────────────────────────────
FROM maven:3.9.4-eclipse-temurin-21 AS builder
WORKDIR /workspace

# 1a) Copy Maven wrapper and POM only (maximises cache hit)
COPY pom.xml mvnw mvnw.cmd ./
COPY .mvn/ .mvn/

# 1b) Pre-download all dependencies (cached unless pom.xml changes)
RUN mvn -B dependency:go-offline -q

# 1c) Copy sources and build
COPY src ./src
RUN mvn -B -DskipTests package \
    && rm -rf /root/.m2/repository

# ─────────────────────────────────────────────────────────────
# STAGE 2 — Runtime (Distroless — minimal attack surface)
#   - No shell, no package manager, no OS tools
#   - Runs as non-root (uid 65532) by default
# ─────────────────────────────────────────────────────────────
FROM gcr.io/distroless/java21-debian12:nonroot
WORKDIR /app

COPY --from=builder /workspace/target/student-management-*.jar /app/app.jar

ENV SERVER_PORT=8089
EXPOSE 8089

# Health probes must be performed from the orchestrator (no curl/wget available):
#   GET http://localhost:8089/student/actuator/health  (Basic auth: ACTUATOR_USER/ACTUATOR_PASSWORD)
#
# Kubernetes example:
#   livenessProbe:
#     httpGet:
#       path: /student/actuator/health/liveness
#       port: 8089

ENTRYPOINT ["java", \
    "-XX:+UseContainerSupport", \
    "-XX:MaxRAMPercentage=75.0", \
    "-jar", "/app/app.jar"]
