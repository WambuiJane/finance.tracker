# First stage: Build the application
FROM maven:3.9-eclipse-temurin-17 AS builder
WORKDIR /app

# Copy pom.xml first for dependency resolution (better layer caching)
COPY pom.xml .
# Download dependencies
RUN mvn dependency:go-offline

# Copy source code
COPY src/ ./src/

# Build the application with tests
RUN mvn package

# Second stage: Run the application
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# Create non-root user
RUN addgroup --system --gid 1001 javauser && \
    adduser --system --uid 1001 --ingroup javauser javauser

# Copy the JAR from the builder stage
COPY --from=builder /app/target/*.jar app.jar

# Set permissions
RUN chown -R javauser:javauser /app
USER javauser

EXPOSE 8080

# Add health check
HEALTHCHECK --interval=30s --timeout=3s CMD wget -q -O /dev/null http://localhost:8080/actuator/health || exit 1

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]