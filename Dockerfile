FROM eclipse-temurin:17-jre

# Install lightweight tools for healthcheck and run as non-root
RUN apt-get update \
		&& apt-get install -y --no-install-recommends curl \
		&& rm -rf /var/lib/apt/lists/*

RUN groupadd -r app && useradd -r -g app -m -d /home/app app
WORKDIR /home/app

ENV APP_HOME=/home/app
VOLUME /tmp
COPY target/student-management-*.jar app.jar

# Expose configured server port
EXPOSE ${SERVER_PORT:8089}

USER app
ENTRYPOINT ["java", "-jar", "/home/app/app.jar"]

# Healthcheck: call root context; requires app to expose an endpoint
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
	CMD curl -f http://localhost:${SERVER_PORT:-8089}/student || exit 1