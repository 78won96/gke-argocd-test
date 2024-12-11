
FROM openjdk:11-jdk AS builder
COPY gradlew .
COPY gradle gradle
COPY build.gradle .
COPY settings.gradle .
COPY src src
RUN chmod +x ./gradlew
RUN ./gradlew bootJar
RUN useradd -u 1001 customuser
USER customuser

FROM openjdk:11.0.11-jre-slim


COPY --from=builder build/libs/*.jar springboot-sample-app.jar
VOLUME /tmp
EXPOSE 8080

ENTRYPOINT ["java", "-jar", "/springboot-sample-app.jar"]
