### Multi-stage Dockerfile
# 1) Build stage: use Maven image to compile the fat jar
FROM maven:3.9.4-eclipse-temurin-21 AS builder
WORKDIR /workspace

COPY pom.xml mvnw mvnw.cmd .mvn/ ./
COPY src ./src

RUN mvn -B -DskipTests package \
    && rm -rf /root/.m2/repository

# 2) Runtime stage: Distroless Java for minimal attack surface
FROM gcr.io/distroless/java21-debian12:nonroot

WORKDIR /app

COPY --from=builder /workspace/target/student-management-*.jar /app/app.jar

ENV SERVER_PORT=8089
EXPOSE 8089

# Distroless has no shell/curl/wget — health probes must run from the orchestrator
# (e.g. Jenkins curl, Kubernetes livenessProbe) against:
#   http://localhost:8089/student/actuator/health  (Basic auth required)

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
