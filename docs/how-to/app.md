# Assemble blocks into an app

A collection of {term}`block` instances that can be loaded to a PandABlocks
device is called an {term}`app`. This page explains how to create and build a
new app.

## The app ini file

An ini file specifies the blocks that make up an app. It lives in the `apps/`
directory with the extension `.app.ini`. It contains a top-level `[.]` section
followed by one section for every block in the app.

### The `[.]` section

The first section holds app-wide information:

```ini
[.]
description: Short description of what this app will do
target: device_type
```

`description`
: A human-readable description of what the app contains and why it should be
  used.

`target`
: Must match a directory name under `targets/` that wraps the blocks in a
  top-level entity loadable on the given PandABlocks device.

### `[BLOCK]` sections

All other sections specify block instance information:

```ini
[MYBLOCK]
number: 4
module: mymodule
ini: myblock.block.ini
```

The section name becomes the block name in the resulting app. Use upper-case
letters and underscores only — no numbers.

`number`
: Number of block instances to include. Defaults to `1` if omitted.

`module`
: Directory under `modules/` containing the block ini file. Defaults to the
  lowercase section name if omitted.

`ini`
: Block ini filename relative to the module directory. Defaults to the lowercase
  section name + `.block.ini` if omitted.

## Building the app

Run:

```shell
make
```

This builds the app named by `APP_NAME` in the top-level `CONFIG` file and
produces an `.ipk` package (`panda-fpga-<app>_<version>_all.ipk`) that can be
deployed to a PandABlocks device:

```
APP_NAME = pandabox-no-fmc
```

To build every app in `apps/`, run `make all-ipks` instead. See
[](/how-to/build-fpga-image.md) for the full build setup.

## Querying the app at runtime

Query the loaded app name via the TCP server:

```
< *METADATA.APPNAME?
> OK =pandabox-fmc-24vio
```

The app name is kebab-case, following the `.ipk` name — for example
`panda-fpga-pandabox-fmc-acq430_4.2b1.ipk` reports `pandabox-fmc-acq430`.
