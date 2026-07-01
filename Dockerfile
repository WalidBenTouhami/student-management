FROM eclipse-temurin:21-jre-alpine
LABEL org.opencontainers.image.title="Student Management"
LABEL org.opencontainers.image.source="https://github.com/WalidBenTouhami/student-management"

RUN addgroup -g 1001 spring && adduser -u 1001 -S spring -G spring -h /app
WORKDIR /app
COPY --chown=1001:1001 target/*.jar app.jar

USER 1001
EXPOSE 8089
ENV JAVA_OPTS="-XX:MaxRAMPercentage=75.0 -XX:+UseContainerSupport"
HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
  CMD wget -q -O - http://localhost:8089/student/actuator/health || exit 1
ENTRYPOINT ["sh", "-c", "exec java ${JAVA_OPTS} -jar app.jar"]
