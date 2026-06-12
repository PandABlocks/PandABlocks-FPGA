# Develop locally with the devcontainer

The standardised local development environment for PandABlocks-FPGA is the
devcontainer defined in this repository (`.devcontainer/devcontainer.json` and
the top-level `Dockerfile`). Opening the repo in VS Code (or any
[devcontainer-compatible](https://containers.dev) tool) gives you a consistent
build, test, and documentation environment.

For FPGA builds, mount your Vivado installation into the container — see the
commented bind-mount example in `.devcontainer/devcontainer.json` and
[](build-fpga-image.md).

## Using the Python client from a local session

<!-- Stage A xref/intersphinx probe: a real cross-link into a Sphinx repo
     (PandABlocks-client) that must resolve in the BUILT output. -->
When developing locally you can talk to a running PandA using the Python
client's
[`BlockingClient`](xref:PandABlocks-client#pandablocks.blocking.BlockingClient).
