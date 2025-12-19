# This script must be run from project root directory

# ---------------------------------------
# Project settings
# ---------------------------------------
set proj_name 3d-cordic-graphics-engine
#A7-35
set proj_dir  ./build/vivado-arty-a7-35
set part xc7z010clg400-1
#Z7-10
#set proj_dir  ./build/vivado-arty-z7-10
#set part xc7a35ticsg324-1L

# ---------------------------------------
# Args processing
# ---------------------------------------
set BASE_PATH [file normalize [lindex $argv 0]]

# ---------------------------------------
# Create project
# ---------------------------------------
create_project -part $part $proj_name $proj_dir

# ---------------------------------------
# Set board 
# ---------------------------------------
#set_property board_part digilentinc.com:arty-z7-10:part0:1.1 [current_project]
set_property board_part digilentinc.com:arty-a7-35:part0:1.1 [current_project]

# ---------------------------------------
# Set project-level VHDL 2008
# ---------------------------------------
set_property target_language VHDL [current_project]

# ---------------------------------------
# Add RTL sources
# ---------------------------------------
set_property file_type {VHDL 2008} [add_files -fileset sources_1 ./src]

# ---------------------------------------
# Set top entity
# ---------------------------------------
set_property top main [get_filesets sources_1]

# ---------------------------------------
# Add testbenches
# ---------------------------------------
# --- Unit tests ---
create_fileset -simset sim_unit

set_property file_type {VHDL 2008} [add_files -fileset sim_unit ./test/unit]

# Resources
set_property file_type {VHDL 2008} [add_files -fileset sim_unit ./test/resources/mocks/sram_mock/sram_mock.vhd]

# --- Integration tests ---
# 1) Uart + SRAM external memory
create_fileset -simset sim_int_uart_mem_sram

set_property file_type {VHDL 2008} [add_files -fileset sim_int_uart_mem_sram ./test/integration/uart-memory/sram/integration_tb.vhd]

set_property top integration_tb [get_filesets sim_int_uart_mem_sram]
set_property generic "BASE_PATH=$BASE_PATH" [get_filesets sim_int_uart_mem_sram]

# Resources
set_property file_type {VHDL 2008} [add_files -fileset sim_int_uart_mem ./test/resources/mocks/sram_mock/sram_mock.vhd]

# 2) Uart + SRAM external memory

# 3) External SRAM memory to vga
create_fileset -simset sim_int_mem_sram_ui_proc_video

set_property file_type {VHDL 2008} [add_files -fileset sim_int_mem_sram_ui_proc_video ./test/integration/memory-ui-processing-vram-vga/sram/integration_tb.vhd]

set_property top integration_tb [get_filesets sim_int_mem_sram_ui_proc_video]
set_property generic "BASE_PATH=$BASE_PATH" [get_filesets sim_int_mem_sram_ui_proc_video]

# 4) Internal BRAM memory to vga
create_fileset -simset sim_int_mem_bram_ui_proc_video

set_property file_type {VHDL 2008} [add_files -fileset sim_int_mem_bram_ui_proc_video ./test/integration/memory-ui-processing-vram-vga/bram/integration_tb.vhd]

set_property top integration_tb [get_filesets sim_int_mem_bram_ui_proc_video]
set_property generic "BASE_PATH=$BASE_PATH" [get_filesets sim_int_mem_bram_ui_proc_video]

# Resources
set_property file_type {VHDL 2008} [add_files -fileset sim_int_mem_ui_proc_video ./test/resources/mocks/sram_mock/sram_mock.vhd]

# --- System test ---
create_fileset -simset sim_main
set_property file_type {VHDL 2008} [add_files -fileset sim_main ./test/main/main_bram/main_bram_tb.vhd]
set_property file_type {VHDL 2008} [add_files -fileset sim_main ./test/main/main_sram/main_sram_tb.vhd]
set_property top main_bram_tb [get_filesets sim_main]
set_property generic "BASE_PATH=$BASE_PATH" [get_filesets sim_main]
current_fileset -simset [get_filesets sim_main]

# Resources
set_property file_type {VHDL 2008} [add_files -fileset sim_main ./test/resources/mocks/sram_mock/sram_mock.vhd]

# Delete automatically generated sim_1
delete_fileset [get_filesets sim_1]

# ---------------------------------------
# Add constraints
# ---------------------------------------
#add_files -fileset constrs_1 ./constraints/arty-z7-10.xdc
add_files -fileset constrs_1 ./constraints/arty-a7-35.xdc
# ---------------------------------------
# Compile order
# ---------------------------------------
update_compile_order -fileset sources_1
update_compile_order -fileset sim_unit
update_compile_order -fileset sim_int_uart_mem
update_compile_order -fileset sim_int_mem_ui_proc_video
update_compile_order -fileset sim_main
