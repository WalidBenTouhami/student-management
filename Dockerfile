FROM openjdk:21-jdk-slim AS builder
WORKDIR /app
COPY . .
RUN ./mvnw clean package -DskipTests

FROM openjdk:21-jdk-slim
WORKDIR /app
COPY --from=builder /app/target/student-management-*.jar app.jar
EXPOSE 8089
ENTRYPOINT ["java", "-jar", "app.jar"]
