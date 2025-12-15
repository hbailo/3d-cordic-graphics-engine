#!/bin/bash
set -euo pipefail

# Paths definitions
readonly SRCDIR="../../../src/processing"
readonly WORKDIR="../../../build"
readonly WAVEDIR="./build"

mkdir -p "$WORKDIR" "$WAVEDIR"

# DUT entity
readonly DUT="integration"

# Design analysis
readonly GHDL_FLAGS="--std=08 --workdir=$WORKDIR -Wall"

ghdl -a $GHDL_FLAGS $SRCDIR/projector/orthographic_projector.vhd
ghdl -a $GHDL_FLAGS $SRCDIR/rotator/cordic/cordic_pipeline_synchronizer.vhd
ghdl -a $GHDL_FLAGS $SRCDIR/rotator/cordic/cordic_preprocessor.vhd
ghdl -a $GHDL_FLAGS $SRCDIR/rotator/cordic/cordic_stage.vhd
ghdl -a $GHDL_FLAGS $SRCDIR/rotator/cordic/cordic_postprocessor.vhd
ghdl -a $GHDL_FLAGS $SRCDIR/rotator/cordic/cordic.vhd
ghdl -a $GHDL_FLAGS $SRCDIR/rotator/axis_rotator.vhd
ghdl -a $GHDL_FLAGS $SRCDIR/rotator/xyz_rotator.vhd

# Testbench analysis
ghdl -a $GHDL_FLAGS ${DUT}_tb.vhd

# Testbench simulation
timestamp=$(date +"%Y-%m-%dT%H-%M-%S")
wavefile="$WAVEDIR/${DUT}_tb-${timestamp}.ghw"

ghdl -r $GHDL_FLAGS ${DUT}_tb --stop-time=250us --wave=$wavefile

# Simulation waveform display
savefile="${WAVEDIR}/${DUT}_tb-${timestamp}.gtkw"
baseline_wavefile="${WAVEDIR}/${DUT}_tb-baseline.ghw"
baseline_savefile="${WAVEDIR}/${DUT}_tb-baseline.gtkw"

if [ -f "$baseline_savefile" ]; then
    cp $baseline_savefile $savefile
    sed -i -E \
        -e "s|^\[dumpfile\].*|[dumpfile] \"$(realpath $wavefile)\"|" \
        -e "s|^\[dumpfile_size\].*|[dumpfile_size] $(stat -c%s $wavefile)|" \
        -e "s|^\[savefile\].*|[savefile] \"$(realpath $savefile)\"|" \
        "$savefile"
    
    twinwave $wavefile $savefile ++ $baseline_wavefile $baseline_savefile
else
    gtkwave --saveonexit $wavefile $savefile
fi

latest_wavefile="${WAVEDIR}/${DUT}_tb-latest.ghw"
latest_savefile="${WAVEDIR}/${DUT}_tb-latest.gtkw"

ln -sf "$(realpath $wavefile)" $latest_wavefile
ln -sf "$(realpath $savefile)" $latest_savefile
