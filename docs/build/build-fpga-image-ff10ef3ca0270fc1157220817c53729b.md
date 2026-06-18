# Build an FPGA image

This page covers building a PandABlocks FPGA image with `make` and Vivado,
producing a `panda-fpga-<app>_<version>_all.ipk` package ready for deployment.
This is the only build route for FPGA images — Yocto/kas is not involved; the
[meta-panda](xref:meta-panda) layer only *includes*
the resulting `.ipk` in the PandA system image.

For how to select and deploy the resulting bitstream on a PandA, see
[Choose the FPGA bitstream](xref:meta-panda/how-to/choose-fpga-bitstream)
in the meta-panda docs.

## Prerequisites

- A clone of this repository.
- Xilinx Vivado (the supported version is the `VIVADO_VER` default in the
  top-level `Makefile`, currently 2023.2), plus a licence able to build the
  Zynq part for your target.
- A build environment with the FPGA build dependencies. The recommended way to
  get one is the development container with Vivado mounted in — see
  [](how-to/local-development) and "Running in a container manually" in the
  [meta-panda build guide](xref:meta-panda/how-to/build).

## Build steps

1. Create your build configuration by copying the example and editing it:

   ```shell
   cp CONFIG.example CONFIG
   ```

2. In `CONFIG`, set at least:

   - `APP_NAME` — which {term}`app` to build. Valid names are the `apps/*.app.ini`
     files without the extension, e.g.:

     ```
     APP_NAME = pandabox-no-fmc
     ```

     The first dash-separated component of the app name (e.g. `pandabox`)
     selects the {term}`target platform` it is built for.

   - `VIVADO` (and `VIVADO_VER` if not using the default) — the path to your
     Vivado `settings64.sh`.

   - `BUILD_DIR` if you want build products somewhere other than the default.

3. Run the build:

   ```shell
   make
   ```

   The default target builds the FPGA bitstream for `APP_NAME` and packages it,
   producing `panda-fpga-<APP_NAME>_<version>_all.ipk` in the build directory.
   (`make ipk` is equivalent; `make all-ipks` builds every app in `apps/`.)

4. Copy the package to your PandA and install it:

   ```shell
   scp <build-dir>/panda-fpga-<app>_*.ipk root@<panda-ip>:/tmp/
   ssh root@<panda-ip> opkg install /tmp/panda-fpga-<app>_*.ipk
   ```

   You can also install it through the Web Admin interface — see
   [managing packages](xref:meta-panda/how-to/packages)
   in the meta-panda docs.

## Next steps

After installing the `.ipk`, see
[Choose the FPGA bitstream](xref:meta-panda/how-to/choose-fpga-bitstream)
to configure the PandA to load your new bitstream, or
[Test firmware changes](xref:meta-panda/how-to/test-firmware-changes)
for the development and test workflow.
