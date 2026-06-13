FROM eclipse-temurin:25-jdk AS builder
WORKDIR /app
COPY . .
RUN ./mvnw clean package -DskipTests
FROM eclipse-temurin:25-jre-alpine
WORKDIR /app

# Run as non-root user for security (Pod Security Standards)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

COPY --from=builder /app/target/student-management-*.jar app.jar
EXPOSE 8089

# JVM Flags: container support, max RAM 75%
ENTRYPOINT ["java", "-XX:+UseContainerSupport", "-XX:MaxRAMPercentage=75.0", "-jar", "app.jar"]
