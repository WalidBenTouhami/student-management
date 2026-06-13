### Multi-stage Dockerfile — production-grade, security-hardened
# ─────────────────────────────────────────────────────────────────────────────
# Build Arguments (injected by CI/CD)
# ─────────────────────────────────────────────────────────────────────────────
ARG IMAGE_TAG=latest
ARG BUILD_DATE
ARG GIT_COMMIT

# ─────────────────────────────────────────────────────────────────────────────
# STAGE 1 — Dependency cache layer
#   pom.xml copied first → dependency layer only invalidated when pom changes
# ─────────────────────────────────────────────────────────────────────────────
FROM maven:3.9.4-eclipse-temurin-21 AS builder
WORKDIR /workspace

# 1a) Maven wrapper + POM only (maximises cache hit rate)
COPY pom.xml mvnw mvnw.cmd ./
COPY .mvn/ .mvn/

# 1b) Pre-download all dependencies (cached unless pom.xml changes)
RUN mvn -B dependency:go-offline -q

# 1c) Copy sources and build (skip tests — already run in CI)
COPY src ./src
RUN mvn -B -DskipTests package \
    && rm -rf /root/.m2/repository \
    && ls -la target/*.jar

# ─────────────────────────────────────────────────────────────────────────────
# STAGE 2 — Runtime (Distroless — minimal attack surface)
#   - No shell, no package manager, no OS utilities
#   - Runs as non-root uid 65532 (nonroot) by default
#   - Zero CVEs from OS packages
# ─────────────────────────────────────────────────────────────────────────────
FROM gcr.io/distroless/java21-debian12:nonroot
WORKDIR /app

# OCI standard labels (for image registries & tooling)
LABEL org.opencontainers.image.title="student-management" \
      org.opencontainers.image.description="Student Management System — Spring Boot 3 / Java 21" \
      org.opencontainers.image.vendor="ESPRIT" \
      org.opencontainers.image.source="https://github.com/WalidBenTouhami/student-management" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${GIT_COMMIT}" \
      org.opencontainers.image.version="${IMAGE_TAG}"

COPY --from=builder /workspace/target/student-management-*.jar /app/app.jar

ENV SERVER_PORT=8089
EXPOSE 8089

# ─────────────────────────────────────────────────────────────────────────────
# JVM Flags — production-optimised for containers
#
#   -XX:+UseContainerSupport      → respect Docker/K8s cgroup memory limits
#   -XX:InitialRAMPercentage=50.0 → start with 50% of container RAM
#   -XX:MaxRAMPercentage=75.0     → cap at 75% (leave headroom for OS/GC)
#   -XX:+UseZGC                   → low-latency GC (< 1ms pauses), Java 21 stable
#   -XX:+ZGenerational            → generational ZGC (Java 21+), higher throughput
#   -Djava.security.egd=...       → faster SecureRandom on Linux (non-blocking)
#   -Dfile.encoding=UTF-8         → explicit UTF-8 for all environments
#   -XX:+HeapDumpOnOutOfMemoryError → capture OOM for debugging
#   -XX:HeapDumpPath=/tmp/heap.hprof
#
# Kubernetes health probes (no shell available in distroless):
#   livenessProbe.httpGet:  /student/actuator/health/liveness  :8089
#   readinessProbe.httpGet: /student/actuator/health/readiness :8089
# ─────────────────────────────────────────────────────────────────────────────
ENTRYPOINT ["java", \
    "-XX:+UseContainerSupport", \
    "-XX:InitialRAMPercentage=50.0", \
    "-XX:MaxRAMPercentage=75.0", \
    "-XX:+UseZGC", \
    "-XX:+ZGenerational", \
    "-Djava.security.egd=file:/dev/./urandom", \
    "-Dfile.encoding=UTF-8", \
    "-XX:+HeapDumpOnOutOfMemoryError", \
    "-XX:HeapDumpPath=/tmp/heap.hprof", \
    "-jar", "/app/app.jar"]
