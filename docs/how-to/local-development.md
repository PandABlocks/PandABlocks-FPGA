# Develop locally with the devcontainer

The standardised local development environment for PandABlocks-FPGA is the
devcontainer defined in this repository (`.devcontainer/devcontainer.json` and
the top-level `Dockerfile`). Opening the repo in VS Code (or any
[devcontainer-compatible](https://containers.dev) tool) gives you a consistent
build, test, and documentation environment.

For FPGA builds, mount your Vivado installation into the container — see the
commented bind-mount example in `.devcontainer/devcontainer.json` and
[](/how-to/build-fpga-image.md).

## Using the Pandablocks Container

A `pandablocks-dev-container` image is published on the GitHub 
Container Registry for your development needs.

Pull it:

```bash
docker pull ghcr.io/pandablocks/pandablocks-dev-container:latest
```

Use a numbered tag instead of `latest` to pin a specific release.

Create three host directories:

- `REPO_DIR` — containing all PandA repositories
- `VIVADO_DIR` — containing a Vivado installation
- `BUILD_DIR` — an empty scratch directory

Run the container with those directories mounted:

```bash
docker run --rm --net=host -it \
  -v REPO_DIR:/repos:Z \
  -v BUILD_DIR:/build:Z \
  -v VIVADO_DIR:/scratch/Xilinx \
  ghcr.io/pandablocks/pandablocks-dev-container /bin/bash
```

:::{note}
The mount path for Vivado inside the container must match your local path.
For example, if Vivado is at `/FPGA/Xilinx` on the host use
`-v /FPGA/Xilinx:/FPGA/Xilinx` and edit `CONFIG` accordingly.
:::

In each repository inside the container:

```bash
cp CONFIG.example CONFIG
```

## Using the Python client from a local session

<!-- Stage A xref/intersphinx probe: a real cross-link into a Sphinx repo
     (PandABlocks-client) that must resolve in the BUILT output. -->
When developing locally you can talk to a running PandA using the Python
client's
[`BlockingClient`](xref:PandABlocks-client#pandablocks.blocking.BlockingClient).
