FROM openjdk:17-alpine

WORKDIR /app

USER root

RUN apk update && apk --no-cache add bind-tools

COPY target/quarkus-app/ /app

CMD ["java", "-jar", "/app/quarkus-run.jar"]