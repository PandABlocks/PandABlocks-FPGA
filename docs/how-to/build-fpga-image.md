# Build an FPGA image

This page covers building a PandABlocks FPGA bitstream inside the `kas`
development container, producing an `.ipk` package ready for deployment.

For how to select and deploy the resulting bitstream on a PandA, see
[](meta-panda:how-to/choose-fpga-bitstream) in the meta-panda docs.

## Prerequisites

- Docker (or Podman) available on your host
- A clone of this repository
- The `kas` container image pulled (see [](how-to/local-development))

## Build steps

1. Start the `kas` build container:

   ```shell
   kas shell kas/pandablocks-fpga.yml
   ```

2. Inside the container, build the FPGA image for your target:

   ```shell
   bitbake pandablocks-fpga
   ```

   Replace `pandablocks-fpga` with the appropriate Yocto image target if
   building for a non-default hardware target.

3. The build produces a `.ipk` package under `tmp/deploy/ipk/`. Copy it to
   your PandA:

   ```shell
   scp tmp/deploy/ipk/<arch>/pandablocks-fpga_*.ipk root@<panda-ip>:/tmp/
   ```

4. On the PandA, install the package and restart the server:

   ```shell
   opkg install /tmp/pandablocks-fpga_*.ipk
   systemctl restart pandablocks-server
   ```

:::{note}
The exact `kas` YAML filename and Yocto target name depend on the hardware
target you are building for. Check the `kas/` directory in this repository
for the available configuration files.
:::

## Next steps

After building and installing the `.ipk`, see
[](meta-panda:how-to/choose-fpga-bitstream) to configure the PandA to load
your new bitstream, or [](meta-panda:how-to/test-firmware-changes) for the
full `devtool`-based development and test workflow.
