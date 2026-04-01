# ── Stage 1: Build ────────────────────────────────────────────────────────────
FROM eclipse-temurin:21-jdk-jammy AS build
WORKDIR /app

# ✅ FIX: Node.js v25 (downloaded by Kotlin WasmJS tooling) requires libatomic
RUN apt-get update && apt-get install -y --no-install-recommends \
    libatomic1 \
 && rm -rf /var/lib/apt/lists/*

# Cache Gradle deps before copying source
COPY gradlew .
COPY gradle/ gradle/
COPY gradle.properties .
COPY settings.gradle.kts .
COPY build.gradle.kts .
RUN chmod +x ./gradlew
RUN ./gradlew dependencies --no-daemon || true

COPY . .
RUN chmod +x ./gradlew
RUN ./gradlew :app:wasmJs:wasmJsBrowserDistribution --no-daemon

# ── Stage 2: Serve ────────────────────────────────────────────────────────────
FROM nginx:alpine
COPY --from=build /app/app/wasmJs/build/dist/wasmJs/productionExecutable /usr/share/nginx/html
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
EXPOSE 10000
ENTRYPOINT ["/entrypoint.sh"]
