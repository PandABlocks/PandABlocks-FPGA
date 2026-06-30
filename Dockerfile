# The devcontainer should use the developer target and run as root with podman
# or docker with user namespaces.
FROM ghcr.io/diamondlightsource/ubuntu-devcontainer:resolute AS developer

# Add any system dependencies for the developer/build environment here.
# Vivado itself is not installed in the container: mount it in from the host
# (see the commented mount in .devcontainer/devcontainer.json).
#
# npm provides npx, used by `make docs` to run mystmd on demand. matplotlib + numpy
# are installed to the system python because the block_fields/timing_plot docs
# directives shell out to `python3 -m common.python.*`. nvc is the VHDL simulator the
# cocotb tests drive (installed via install_nvc.sh, mirrored in CI).
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    curl \
    npm \
    && apt-get dist-clean

COPY .github/scripts/install_nvc.sh /tmp/install_nvc.sh
RUN bash /tmp/install_nvc.sh && rm /tmp/install_nvc.sh
