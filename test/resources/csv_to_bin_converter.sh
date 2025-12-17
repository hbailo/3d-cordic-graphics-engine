#!/bin/bash
set -euo pipefail

# Paths definitions
readonly WORKDIR="./build"

mkdir -p "$WORKDIR"

# DUT entity
readonly DUT="csv_to_bin_converter"

# Design analysis
readonly GHDL_FLAGS="--std=08 --workdir=$WORKDIR -Wall"

# Testbench analysis
ghdl -a $GHDL_FLAGS ${DUT}.vhd

# Testbench simulation
ghdl -r $GHDL_FLAGS ${DUT}
