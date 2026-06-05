### Multi-stage Dockerfile
# 1) Build stage: use Maven image to compile the fat jar
FROM maven:3.9.4-eclipse-temurin-25 AS builder
WORKDIR /workspace

# Copy sources and build
COPY pom.xml mvnw .mvn/ ./
COPY src ./src

# Install tini via package manager in builder and build jar
RUN apt-get update \
  && apt-get install -y --no-install-recommends tini ca-certificates \
  && mvn -B -DskipTests package \
  && rm -rf /var/lib/apt/lists/*

# 2) Runtime stage: use Distroless Java for minimal attack surface
FROM gcr.io/distroless/java25-debian11:nonroot

WORKDIR /app

# Copy tini from builder and application jar
COPY --from=builder /usr/bin/tini /tini
# NOTE: we install `tini` via package manager in the builder stage. If you prefer to
# download `tini` manually you can replace the builder stage's apt-get lines with a
# curl + sha256 checksum verification before copying the binary into the runtime image.
# Example (sketch):
# RUN curl -fsSL -o /tini "https://github.com/krallin/tini/releases/download/v0.19.0/tini" \
#     && echo "<sha256sum>  /tini" | sha256sum -c - \
#     && chmod +x /tini
COPY --from=builder /workspace/target/student-management-*.jar /app/app.jar

# Expose configured server port
ENV SERVER_PORT=8089
EXPOSE ${SERVER_PORT}

# Use tini as PID 1 to reap processes and forward signals
ENTRYPOINT ["/tini", "--", "java", "-jar", "/app/app.jar"]

# Healthcheck: use actuator health endpoint (assumes Actuator is enabled)
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- --timeout=2000 http://localhost:${SERVER_PORT:-8089}/actuator/health | grep -q '"status":"UP"' || exit 1
