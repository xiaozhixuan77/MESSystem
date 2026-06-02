# 构建阶段
FROM eclipse-temurin:17-jdk-alpine AS builder
WORKDIR /app

RUN apk add --no-cache maven
COPY pom.xml .
RUN mvn dependency:go-offline -B

COPY src ./src
# 编译（测试应在 CI 流水线中先于镜像构建执行）
RUN mvn clean package -DskipTests -B

# 运行阶段
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# curl 用于健康检查
RUN apk add --no-cache curl && \
    addgroup -S app && \
    adduser -S app -G app

COPY --from=builder /app/target/*.jar app.jar
RUN chown app:app app.jar

EXPOSE 8080

ENV SPRING_PROFILES_ACTIVE=prod
ENV JAVA_OPTS="-Xms512m -Xmx1024m -XX:+UseG1GC"

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD curl -s -o /dev/null http://localhost:8080/me || exit 1

USER app
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar app.jar"]
