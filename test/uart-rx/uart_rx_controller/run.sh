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
baseline_wavefile="${WAVEDIR}/uart_rx_controller_tb-baseline.ghw"
baseline_savefile="${WAVEDIR}/uart_rx_controller_tb-baseline.gtkw"

if [ -f "$baseline_savefile" ]; then
    cp $baseline_savefile $savefile
    sed -i -E \
        -e "s|^\[dumpfile\].*|[dumpfile] \"$(realpath $wavefile)\"|" \
        -e "s|^\[dumpfile_size\].*|[dumpfile_size] $(stat -c%s $wavefile)|" \
        -e "s|^\[savefile\].*|[savefile] \"$(realpath $savefile)\"|" \
        "$savefile"
    
    twinwave $wavefile $savefile + $baseline_wavefile $baseline_savefile
else
    gtkwave --saveonexit $wavefile $savefile
fi

latest_wavefile="${WAVEDIR}/uart_rx_controller_tb-latest.ghw"
latest_savefile="${WAVEDIR}/uart_rx_controller_tb-latest.gtkw"

ln -sf "$(realpath $wavefile)" $latest_wavefile
ln -sf "$(realpath $savefile)" $latest_savefile
