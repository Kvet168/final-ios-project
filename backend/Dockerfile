FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /src
COPY pom.xml .
RUN mvn -q -B dependency:go-offline
COPY src ./src
RUN mvn -q -B -DskipTests package

FROM eclipse-temurin:21-jre
WORKDIR /app
RUN useradd --system --uid 1001 wayfarer
COPY --from=build /src/target/wayfarer-api-1.0.0.jar app.jar
USER wayfarer
EXPOSE 8080
# Tuned for small containers (a small VPS container: 512 MB and a fraction of a CPU): cap the heap below the
# container limit, use the low-overhead serial collector, and favour fast startup. Override with JAVA_OPTS.
ENV JAVA_OPTS="-XX:MaxRAMPercentage=70 -XX:+UseSerialGC -XX:TieredStopAtLevel=1 -Xss512k -XX:+ExitOnOutOfMemoryError"
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar app.jar"]
