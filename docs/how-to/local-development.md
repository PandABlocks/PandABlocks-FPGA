# Develop locally with the devcontainer

The standardised local development environment for PandABlocks-FPGA is provided
by the **PandABlocks-devcontainer** repository. It gives you a consistent
build, test, and documentation workflow without needing a native Yocto
toolchain.

See the [PandABlocks-devcontainer docs](https://github.com/PandABlocks/PandABlocks-devcontainer)
for setup instructions.

## Using the Python client from a local session

<!-- Stage A xref/intersphinx probe: a real cross-link into a Sphinx repo
     (PandABlocks-client) that must resolve in the BUILT output. -->
When developing locally you can talk to a running PandA using the Python
client's
[`BlockingClient`](xref:PandABlocks-client#pandablocks.blocking.BlockingClient).
