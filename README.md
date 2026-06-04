# Student Management

This repository contains a Spring Boot student management application.

Build locally:

```powershell
./mvnw -DskipTests package
```

Build Docker image (multi-stage, uses Maven to build):

```powershell
docker build -t <namespace>/student-management:latest .
```

Run locally:

```powershell
docker run -e SPRING_DATASOURCE_URL="jdbc:mysql://host:3306/studentdb" -e SPRING_DATASOURCE_USERNAME=root -e SPRING_DATASOURCE_PASSWORD=*** -e SERVER_PORT=8089 -p 8089:8089 <namespace>/student-management:latest
```

Jenkins pipeline notes:
- The `Jenkinsfile` builds using `./mvnw`, builds the Docker image, tags it with `latest` and the Git commit short SHA, then pushes both tags to Docker Hub (credentials required).
- Ensure Jenkins has credentials `docker-hub-credentials` set up (username/password) and `github-token` for checkout.

Security notes:
- Database credentials are read from environment variables. Do not hardcode secrets in this repo.
- The Docker image uses a distroless runtime and runs as non-root.

Healthcheck:
- The container exposes `/actuator/health` which returns `{"status":"UP"}` when healthy.
