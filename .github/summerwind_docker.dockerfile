FROM summerwind/actions-runner:latest

USER root

RUN curl -fsSL https://get.docker.com | sh

USER runner
