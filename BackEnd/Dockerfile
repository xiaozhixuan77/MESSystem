# 构建阶段 — Maven 镜像内置 JDK+Maven，无需 apk add
FROM maven:3.9-eclipse-temurin-17-alpine AS builder
WORKDIR /app

# 先缓存依赖（源码变更时此层不变，跳过依赖下载）
COPY docker/settings.xml /usr/share/maven/conf/settings.xml
COPY pom.xml .
RUN --mount=type=cache,target=/root/.m2 \
    mvn dependency:go-offline -B

# 编译（使用缓存 Maven repo + 跳过测试）
ARG CACHEBUST=0
COPY src ./src
RUN --mount=type=cache,target=/root/.m2 \
    mvn clean package -DskipTests -B

# 运行阶段
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

RUN sed -i 's#dl-cdn.alpinelinux.org#mirrors.aliyun.com#g' /etc/apk/repositories && \
    apk add --no-cache curl && \
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
