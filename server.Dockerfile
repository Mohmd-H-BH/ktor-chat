# ── Stage 1: Build everything ──────────────────────────────────────────────────
FROM eclipse-temurin:21-jdk-jammy AS build
WORKDIR /app

COPY gradlew .
COPY gradle/ gradle/
COPY gradle.properties .
COPY settings.gradle.kts .
COPY build.gradle.kts .
RUN chmod +x ./gradlew

# Copy all source modules
COPY server/ server/
COPY core/ core/
COPY db/ db/
COPY client/ client/


# Build Ktor fat JAR (task provided by the Ktor Gradle plugin)
RUN ./gradlew :server:rest:buildFatJar --no-daemon


# ── Stage 2: Runtime (nginx + JRE) ────────────────────────────────────────────
FROM nginx:alpine

# Install a JRE and process supervisor
RUN apk add --no-cache openjdk21-jre supervisor

# Copy Ktor JAR (Ktor's buildFatJar creates <module>-all.jar)
COPY --from=build /app/server/rest/build/libs/rest-all.jar /app/server.jar

# Copy configs
COPY nginx.conf /etc/nginx/nginx.conf
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 8080
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
