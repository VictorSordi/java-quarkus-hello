FROM openjdk:17-alpine

WORKDIR /app

USER root

RUN apk update && apk --no-cache add bind-tools

COPY target/quarkus-app/quarkus-run.jar /app

CMD ["java", "-jar", "quarkus-run.jar"]

