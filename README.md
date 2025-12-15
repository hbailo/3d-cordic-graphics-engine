# 3D CORDIC Graphics Engine
A 3D rotation graphics engine based on a CORDIC core, with uart data loading and VGA video output, fully developed in VHDL.

## RTL Schematic

## Project structure
src/                 # RTL design sources (synthesizable)
test/                # Testbenches and simulation resources
  ├── unit/          # Unit tests (one TB per entity)
  ├── integration/   # Integration tests (multiple entities)
  ├── main/          # System-level testbench
  └── resources/     # Mocks, data files, helpers (simulation only)
constraints/         # XDC constraints
scripts/             # Vivado TCL scripts

## Building
Build the vivado project targeting the Arty Z7-10 board.

Prerequisites
- Vivado 2023.2
- Arty Z7-10 board files installed in vivado
- GNU Make (optional)

* With make
Edit Makefile VIVADO variable to point to vivado binary

```makefile
    VIVADO := /path/to/vivado/2023.2/bin/vivado
```

Run

```console
   make vivado
``` 

* Without make

Run

```console
    vivado -source scripts/create-vivado-project.tcl
```
 
## Pre-synthesis testing
Prerequisites
- GHDL >= 5.0.1
- GTKWave >= 3.3.121 (optional)
- Bash

Run

```console
    bash run.sh
```

inside each `test/` subdir.

## Documentation
Prerequisites
- Doxygen >= 1.9.8

Run

```console
    doxygen Doxyfile 
```

Generated doc is inside `doc/doxygen`, open `doc/doxygen/html/index.html` to see it.
