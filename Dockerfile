FROM openjdk:17-alpine

USER root

RUN apk update && apk --no-cache add bind-tools

COPY target/ .

CMD ["java", "-jar", "quarkus-run.jar"]

