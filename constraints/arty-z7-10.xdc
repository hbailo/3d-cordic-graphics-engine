## Clock
set_property -dict { PACKAGE_PIN H16    IOSTANDARD LVCMOS33 } [get_ports { sysclk }];   #IO_L13P_T2_MRCC_35 Sch=SYSCLK
create_clock -add -name sysclk_pin -period 8.00 -waveform {0 4} [get_ports { sysclk }]; #set

# UART rx
set_property -dict { PACKAGE_PIN Y18    IOSTANDARD LVCMOS33 } [get_ports { rx }]; #IO_L17P_T2_34 Sch=JA1_P

## Reset button
set_property -dict { PACKAGE_PIN L19    IOSTANDARD LVCMOS33 } [get_ports { rst }]; #IO_L9P_T1_DQS_AD3P_35 Sch=BTN3

## Angle up switches
set_property -dict { PACKAGE_PIN D19    IOSTANDARD LVCMOS33 } [get_ports { x_angle_up_sw }]; #IO_L4P_T0_35 Sch=BTN0
set_property -dict { PACKAGE_PIN D20    IOSTANDARD LVCMOS33 } [get_ports { y_angle_up_sw }]; #IO_L4N_T0_35 Sch=BTN1
set_property -dict { PACKAGE_PIN L20    IOSTANDARD LVCMOS33 } [get_ports { z_angle_up_sw }]; #IO_L9N_T1_DQS_AD3N_35 Sch=BTN2

## VGA
set_property -dict { PACKAGE_PIN Y19   IOSTANDARD LVCMOS33 } [get_ports { h_sync }]; #IO_L17N_T2_34 Sch=JA1_N (Pin 2)
set_property -dict { PACKAGE_PIN Y16   IOSTANDARD LVCMOS33 } [get_ports { v_sync }]; #IO_L7P_T1_34 Sch=JA2_P (Pin 3)
set_property -dict { PACKAGE_PIN Y17   IOSTANDARD LVCMOS33 } [get_ports { red }];    #IO_L7N_T1_34 Sch=JA2_N (Pin 4)
set_property -dict { PACKAGE_PIN U18   IOSTANDARD LVCMOS33 } [get_ports { green }];  #IO_L12P_T1_MRCC_34 Sch=JA3_P (Pin 7)
set_property -dict { PACKAGE_PIN U19   IOSTANDARD LVCMOS33 } [get_ports { blue }];   #IO_L12N_T1_MRCC_34 Sch=JA3_N (Pin 8)
