FROM gradle:8.5-jdk21 AS build

WORKDIR /app

# Copy gradle files
COPY gradle/ gradle/
COPY gradlew gradlew.bat build.gradle.kts settings.gradle.kts gradle.properties ./

# Copy source code
COPY server/ server/
COPY shared/ shared/

# Make gradlew executable
RUN chmod +x ./gradlew

# Build the application
RUN ./gradlew :server:shadowJar --no-daemon

FROM eclipse-temurin:21-jre-jammy

WORKDIR /app

# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Copy the built JAR
COPY --from=build /app/server/build/libs/server-all.jar app.jar

# Create uploads directory and set permissions
RUN mkdir -p uploads logs && \
    addgroup --gid 1001 appuser && \
    adduser --uid 1001 --gid 1001 --disabled-password --gecos "" appuser && \
    chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/ || exit 1

# Run the application
CMD ["java", "-jar", "app.jar"] 