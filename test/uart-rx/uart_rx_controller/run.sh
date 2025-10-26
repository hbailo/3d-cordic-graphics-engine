#!/bin/bash
set -euo pipefail

# Paths definitions
readonly SRCDIR="../../../src"
readonly WORKDIR="../../../build"
readonly WAVEDIR="./build"

mkdir -p "$WORKDIR" "$WAVEDIR"

# Design analysis
readonly GHDL_FLAGS="--std=08 --workdir=$WORKDIR -Wall"

ghdl -a $GHDL_FLAGS $SRCDIR/uart-rx/baud_rate_generator.vhd
ghdl -a $GHDL_FLAGS $SRCDIR/uart-rx/uart_rx_controller.vhd

# Testbench analysis
ghdl -a $GHDL_FLAGS uart_rx_controller_tb.vhd

# Testbench simulation
timestamp=$(date +"%Y-%m-%dT%H-%M-%S")
wavefile="${WAVEDIR}/uart_rx_controller_tb-${timestamp}.ghw"

ghdl -r $GHDL_FLAGS uart_rx_controller_tb --stop-time=225us --wave=$wavefile

# Simulation waveform display
savefile="${WAVEDIR}/uart_rx_controller_tb-${timestamp}.gtkw"
last_wavefile="${WAVEDIR}/uart_rx_controller_tb-last.ghw"
last_savefile="${WAVEDIR}/uart_rx_controller_tb-last.gtkw"

if [ -f "$last_savefile" ]; then
    cp "$last_savefile" "$savefile"
    twinwave $wavefile $savefile ++ $last_wavefile $last_savefile
else
    gtkwave --saveonexit $wavefile $savefile
fi

ln -sf "$(realpath $wavefile)" $last_wavefile
ln -sf "$(realpath $savefile)" $last_savefile
