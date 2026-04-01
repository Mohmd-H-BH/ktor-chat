# ── Stage 1: Build ────────────────────────────────────────────────────────────
FROM eclipse-temurin:21-jdk-jammy AS build
WORKDIR /app

# Cache Gradle wrapper and deps before copying source code.
# This layer only rebuilds when gradle files change.
COPY gradlew .
COPY gradle/ gradle/
COPY gradle.properties .
COPY settings.gradle.kts .
COPY build.gradle.kts .
RUN chmod +x ./gradlew
# Download dependencies (layer-cached separately from source)
RUN ./gradlew dependencies --no-daemon || true

# Copy source and build
COPY . .
RUN chmod +x ./gradlew
RUN ./gradlew :app:wasmJs:wasmJsBrowserDistribution --no-daemon

# ── Stage 2: Serve ────────────────────────────────────────────────────────────
FROM nginx:alpine

# Copy built static files
COPY --from=build /app/wasmJs/build/dist/wasmJs/productionExecutable /usr/share/nginx/html

# Copy entrypoint that sets nginx port from $PORT env var
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 10000
ENTRYPOINT ["/entrypoint.sh"]
