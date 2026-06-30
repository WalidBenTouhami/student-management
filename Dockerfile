FROM maven:3.9.11-eclipse-temurin-25 AS build
WORKDIR /workspace
COPY pom.xml mvnw ./
COPY .mvn .mvn
RUN ./mvnw dependency:go-offline --no-transfer-progress
COPY src src
RUN ./mvnw clean package -DskipTests --no-transfer-progress

FROM eclipse-temurin:25-jre
LABEL org.opencontainers.image.title="Student Management"
LABEL org.opencontainers.image.source="https://github.com/WalidBenTouhami/student-management"

RUN groupadd --system spring \
    && useradd --system --gid spring --home-dir /app spring
WORKDIR /app
COPY --from=build --chown=spring:spring /workspace/target/student-management-*.jar app.jar

USER spring
EXPOSE 8089
ENV JAVA_OPTS="-XX:MaxRAMPercentage=75.0 -XX:+UseContainerSupport"
ENTRYPOINT ["sh", "-c", "exec java ${JAVA_OPTS} -jar app.jar"]
