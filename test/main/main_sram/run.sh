#!/bin/bash
set -euo pipefail

# Paths definitions
readonly BASE_PATH="../../.."
readonly SRCDIR="${BASE_PATH}/src"
readonly RESDIR="${BASE_PATH}/test/resources"
readonly WORKDIR="${BASE_PATH}/build"
readonly WAVEDIR="./build"

mkdir -p "$WORKDIR" "$WAVEDIR"

# DUT entity
readonly DUT="main_sram"

# Design analysis
readonly GHDL_FLAGS="--std=08 --workdir=$WORKDIR -Wall"

ghdl -a $GHDL_FLAGS $SRCDIR/memory/memory_loader.vhd
ghdl -a $GHDL_FLAGS $SRCDIR/memory/memory_reader.vhd
ghdl -a $GHDL_FLAGS $SRCDIR/memory/sram_controller.vhd
ghdl -a $GHDL_FLAGS $SRCDIR/processing/rotator/cordic/cordic_pipeline_synchronizer.vhd
ghdl -a $GHDL_FLAGS $SRCDIR/processing/rotator/cordic/cordic_preprocessor.vhd
ghdl -a $GHDL_FLAGS $SRCDIR/processing/rotator/cordic/cordic_stage.vhd
ghdl -a $GHDL_FLAGS $SRCDIR/processing/rotator/cordic/cordic_postprocessor.vhd
ghdl -a $GHDL_FLAGS $SRCDIR/processing/rotator/cordic/cordic.vhd
ghdl -a $GHDL_FLAGS $SRCDIR/processing/rotator/axis_rotator.vhd
ghdl -a $GHDL_FLAGS $SRCDIR/processing/rotator/xyz_rotator.vhd
ghdl -a $GHDL_FLAGS $SRCDIR/uart-rx/meta_harden.vhd
ghdl -a $GHDL_FLAGS $SRCDIR/uart-rx/baud_rate_generator.vhd
ghdl -a $GHDL_FLAGS $SRCDIR/uart-rx/uart_rx_controller.vhd
ghdl -a $GHDL_FLAGS $SRCDIR/uart-rx/uart_rx_interface.vhd
ghdl -a $GHDL_FLAGS $SRCDIR/uart-rx/uart_rx.vhd
ghdl -a $GHDL_FLAGS $SRCDIR/ui/angle_stepper.vhd
ghdl -a $GHDL_FLAGS $SRCDIR/ui/switch_debouncer.vhd
ghdl -a $GHDL_FLAGS $SRCDIR/video/vga/image_generator.vhd
ghdl -a $GHDL_FLAGS $SRCDIR/video/vga/vga_controller.vhd
ghdl -a $GHDL_FLAGS $SRCDIR/video/vga/vga.vhd
ghdl -a $GHDL_FLAGS $SRCDIR/video/vram/bitmap_clearer.vhd
ghdl -a $GHDL_FLAGS $SRCDIR/video/vram/bitmap_drawer.vhd
ghdl -a $GHDL_FLAGS $SRCDIR/video/vram/bitmap_sequencer.vhd
ghdl -a $GHDL_FLAGS $SRCDIR/video/vram/dual_port_ram.vhd
ghdl -a $GHDL_FLAGS $RESDIR/mocks/sram_mock/sram_mock.vhd
ghdl -a $GHDL_FLAGS $SRCDIR/${DUT}.vhd

# Testbench analysis
ghdl -a $GHDL_FLAGS ${DUT}_tb.vhd

# Testbench simulation
timestamp=$(date +"%Y-%m-%dT%H-%M-%S")
wavefile="$WAVEDIR/${DUT}_tb-${timestamp}.ghw"

ghdl -r $GHDL_FLAGS -gBASE_PATH=${BASE_PATH} ${DUT}_tb --stop-time=2ms --wave=$wavefile

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
