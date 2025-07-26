#!/bin/bash
set -euo pipefail

# Paths definitions
readonly SRCDIR="../../../src"
readonly WORKDIR="../../../build"

mkdir -p "$WORKDIR"

# Design analysis
readonly GHDL_FLAGS="--std=08 --workdir=$WORKDIR"

ghdl -a $GHDL_FLAGS $SRCDIR/uart-rx/baud_rate_generator.vhd

# Testbench analysis
ghdl -a $GHDL_FLAGS baud_rate_generator_tb.vhd

# Testbench simulation
timestamp=$(date +"[%Y-%m-%dT%H-%M-%S]")
wavefile="./build/${timestamp}.ghw"

mkdir -p "./build"

ghdl -r $GHDL_FLAGS baud_rate_generator_tb --stop-time=10us --wave=$wavefile

# Simulation waveform display
gtkwave $wavefile
