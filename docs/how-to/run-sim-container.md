# Run the FPGA simulation container

The `PandABlocks-sim` image runs a whole PandA in simulation — no hardware and
no Vivado required. It bundles three services under `supervisord`:

- the **FPGA simulation** (`make run_sim_server`), an NVC simulation of the
  `testtarget` {term}`app` driven by cocotb, serving register reads/writes on
  port 9999 inside the container;
- the **PandABlocks-server** `sim_server`, which talks to that simulation
  instead of real hardware and offers the usual control (`8888`) and data
  (`8889`) ports;
- the **web control** interface on port `8008`.

The image is built from `Dockerfile_sim` and published to GHCR.

## Run it

```shell
docker run -p 8008:8008 ghcr.io/pandablocks/pandablocks-sim:latest
```

Then open <http://localhost:8008> to drive the simulated PandA from the web
control interface.

:::{note}
The FPGA simulation is a VHDL simulation of the whole app, so startup takes
considerably longer than real hardware and runs far slower than real time.
`supervisord` restarts each service until they all come up — expect the
server and web control to log connection failures on the first attempts while
the simulation is still generating `config_d` and elaborating the design.
:::

## Expose the server ports as well

To talk to the simulated PandA with the
[Python client](xref:PandABlocks-client) or any other TCP client, publish the
control and data ports too:

```shell
docker run -p 8008:8008 -p 8888:8888 -p 8889:8889 \
  ghcr.io/pandablocks/pandablocks-sim:main
```

`nc localhost 8888` then gets you an interactive control connection, on which
`*IDN?` reports the software and FPGA versions.

The FPGA simulation's own port 9999 is deliberately bound to `localhost`
inside the container: it is the private interface between `sim_server` and the
simulation, not a client interface.

## Waveforms

The FPGA simulation is started with `dump_waveform=1`, so NVC writes a
`wave.fst` into `/repos/PandABlocks-FPGA/build/sim_sim_server/` inside the
container. To get at it from the host, mount a directory over the build
directory or copy the file out:

```shell
docker cp panda-sim:/repos/PandABlocks-FPGA/build/sim_sim_server/wave.fst .
```

Open the result in **GTKWave** (or NVC's own viewer).

:::{note}
Waveform dumping of a full app is expensive in both time and disk space. If
you only need the simulation to run, use
[](/how-to/cocotb.md) or `make run_sim_server APP_NAME=testtarget` locally
instead — see [](/how-to/local-development.md).
:::

## Build the image locally

```shell
docker build -f Dockerfile_sim -t pandablocks-sim .
```

The build clones `PandABlocks-server` and `PandABlocks-webcontrol` from GitHub
and compiles the server, so it needs network access and takes a while. The
repository working tree is copied in as `/repos/PandABlocks-FPGA`, which makes
this the way to try local FPGA changes in the full simulated system.
