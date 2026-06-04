FROM eclipse-temurin:17-jre
VOLUME /tmp
COPY target/student-management-*.jar app.jar
ENTRYPOINT ["java", "-jar", "/app.jar"]
# Recommended: set datasource env vars at runtime, e.g.:
# docker run -e SPRING_DATASOURCE_URL=... -e SPRING_DATASOURCE_USERNAME=... -e SPRING_DATASOURCE_PASSWORD=...