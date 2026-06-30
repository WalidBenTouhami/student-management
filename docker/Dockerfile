# ============================================================
# 🐳 DOCKERFILE - STUDENT MANAGEMENT
# ============================================================

# Image de base Java 25
FROM eclipse-temurin:25-jre-jammy

# Labels pour identification
LABEL maintainer="devops@esprit.tn"
LABEL version="1.0.0"
LABEL description="Student Management Application"

# Variables d'environnement
ENV JAVA_OPTS="-Xmx512m -Xms256m"
ENV APP_HOME=/app
ENV SPRING_PROFILES_ACTIVE=prod

# Création du répertoire de travail
WORKDIR ${APP_HOME}

# Installation des outils utiles
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Création d'un utilisateur non-root
RUN groupadd -r spring && useradd -r -g spring spring

# Copie du JAR
COPY target/student-management-*.jar app.jar

# Copie des fichiers de configuration (si nécessaire)
# COPY src/main/resources/application.properties ${APP_HOME}/config/

# Changement des permissions
RUN chown -R spring:spring ${APP_HOME}

# Passage à l'utilisateur non-root
USER spring

# Exposition du port
EXPOSE 8089

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8089/student/actuator/health || exit 1

# Point d'entrée
ENTRYPOINT ["sh", "-c", "java ${JAVA_OPTS} -jar app.jar"]
