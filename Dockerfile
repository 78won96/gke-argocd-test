# 빌더 이미지
FROM openjdk:11-jdk AS builder

# 새 사용자 생성
RUN useradd -ms /bin/bash appuser

COPY gradlew .
COPY gradle gradle
COPY build.gradle .
COPY settings.gradle .
COPY src src

RUN chmod +x ./gradlew
RUN ./gradlew bootJar

# 애플리케이션 실행 이미지
FROM openjdk:11.0.11-jre-slim

# 새 사용자 생성
RUN useradd -ms /bin/bash appuser

# 빌더 단계에서 생성된 JAR 파일 복사
COPY --from=builder build/libs/*.jar springboot-sample-app.jar

# 디렉토리 권한 설정
RUN chown appuser:appuser /springboot-sample-app.jar

# 새 사용자로 실행
USER appuser

# 애플리케이션 설정
VOLUME /tmp
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/springboot-sample-app.jar"]

