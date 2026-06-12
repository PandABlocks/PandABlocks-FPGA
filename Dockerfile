# The devcontainer should use the developer target and run as root with podman
# or docker with user namespaces.
FROM ghcr.io/diamondlightsource/ubuntu-devcontainer:noble AS developer

# Add any system dependencies for the developer/build environment here.
# Vivado itself is not installed in the container: mount it in from the host
# (see the commented mount in .devcontainer/devcontainer.json).
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    && apt-get dist-clean
