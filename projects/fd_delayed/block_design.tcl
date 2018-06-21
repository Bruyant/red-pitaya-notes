#fd_delayed 111

# Create processing_system7
cell xilinx.com:ip:processing_system7:5.5 ps_0 {
  PCW_IMPORT_BOARD_PRESET cfg/red_pitaya.xml
  PCW_USE_S_AXI_HP0 1
} {
  M_AXI_GP0_ACLK ps_0/FCLK_CLK0
  S_AXI_HP0_ACLK ps_0/FCLK_CLK0
}

# Create all required interconnections
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {
  make_external {FIXED_IO, DDR}
  Master Disable
  Slave Disable
} [get_bd_cells ps_0]

# Create util_ds_buf
cell xilinx.com:ip:util_ds_buf:2.1 buf_0 {
  C_SIZE 2
  C_BUF_TYPE IBUFDS
} {
  IBUF_DS_P daisy_p_i
  IBUF_DS_N daisy_n_i
}

# Create util_ds_buf
cell xilinx.com:ip:util_ds_buf:2.1 buf_1 {
  C_SIZE 2
  C_BUF_TYPE OBUFDS
} {
  OBUF_DS_P daisy_p_o
  OBUF_DS_N daisy_n_o
}

# Create proc_sys_reset
cell xilinx.com:ip:proc_sys_reset:5.0 rst_0


# Create axis_red_pitaya_adc
cell pavel-demin:user:axis_red_pitaya_adc:1.0 adc_0 {} {
  adc_clk_p adc_clk_p_i
  adc_clk_n adc_clk_n_i
  adc_dat_a adc_dat_a_i
  adc_dat_b adc_dat_b_i
  adc_csn adc_csn_o
}

# Create c_counter_binary
cell xilinx.com:ip:c_counter_binary:12.0 cntr_0 {
  Output_Width 32
} {
  CLK adc_0/adc_clk
}

# Create xlslice
cell xilinx.com:ip:xlslice:1.0 slice_0 {
  DIN_WIDTH 32 DIN_FROM 25 DIN_TO 25 DOUT_WIDTH 1
} {
  Din cntr_0/Q
 }


# Create axi_cfg_register
cell pavel-demin:user:axi_cfg_register:1.0 cfg_0 {
  CFG_DATA_WIDTH 352
  AXI_ADDR_WIDTH 32
  AXI_DATA_WIDTH 32
}

# Create all required interconnections
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {
  Master /ps_0/M_AXI_GP0
  Clk Auto
} [get_bd_intf_pins cfg_0/S_AXI]

set_property RANGE 4K [get_bd_addr_segs ps_0/Data/SEG_cfg_0_reg0]
set_property OFFSET 0x40000000 [get_bd_addr_segs ps_0/Data/SEG_cfg_0_reg0]

# Create xlslice
cell xilinx.com:ip:xlslice:1.0 slice_1 {
  DIN_WIDTH 352 DIN_FROM 134 DIN_TO 128 DOUT_WIDTH 7
} {
  Din cfg_0/cfg_data
}

# Create xlconcat
cell xilinx.com:ip:xlconcat:2.1 concat_0 {
  IN1_WIDTH 7
} {
  In0 slice_0/Dout
  In1 slice_1/Dout
  dout led_o
}


# Create xlslice
cell xilinx.com:ip:xlslice:1.0 slice_pktzr_reset {
  DIN_WIDTH 352 DIN_FROM 0 DIN_TO 0
} {
  Din cfg_0/cfg_data
}

# Create xlslice
cell xilinx.com:ip:xlslice:1.0 slice_write_enable {
  DIN_WIDTH 352 DIN_FROM 1 DIN_TO 1
} {
  Din cfg_0/cfg_data
}


# Create xlslice
cell xilinx.com:ip:xlslice:1.0 slice_record_length {
  DIN_WIDTH 352 DIN_FROM 63 DIN_TO 32 DOUT_WIDTH 32
} {
  Din cfg_0/cfg_data
}

# Create xlslice
cell xilinx.com:ip:xlslice:1.0 slice_trig_record {
  DIN_WIDTH 352 DIN_FROM 3 DIN_TO 3
} {
  Din cfg_0/cfg_data
}

# Create xlslice
cell xilinx.com:ip:xlslice:1.0 slice_trx_reset {
  DIN_WIDTH 352 DIN_FROM 4 DIN_TO 4
} {
  Din cfg_0/cfg_data
}

# Create xlconstant
cell xilinx.com:ip:xlconstant:1.1 const_1



# Create axis_clock_converter
cell xilinx.com:ip:axis_clock_converter:1.1 fifo_ADC { 
} {
  S_AXIS adc_0/M_AXIS
  s_axis_aclk adc_0/adc_clk
  s_axis_aresetn const_1/dout
  m_axis_aclk ps_0/FCLK_CLK0
  m_axis_aresetn rst_0/peripheral_aresetn
}


# Create xlslice
cell xilinx.com:ip:xlslice:1.0 slice_delay {
  DIN_WIDTH 352 DIN_FROM 351 DIN_TO 320
} {
  Din cfg_0/cfg_data
}

# Create gpio_trigger
cell pavel-demin:user:gpio_delayed_trigger:1.0 trigger_0 {
	GPIO_DATA_WIDTH 8
        GPIO_INPUT_WIDTH 2	
} {
  gpio_data exp_p_tri_io
  soft_trig slice_trig_record/Dout
  delay slice_delay/Dout
  aclk ps_0/FCLK_CLK0
  aresetn slice_pktzr_reset/Dout
}
#connect_bd_intf_net [get_bd_pins trigger_0/out_data] [get_bd_pins trigger_0/soft_trig]
connect_bd_net [get_bd_pins trigger_0/out_data] [get_bd_pins trigger_0/trigger]

# Create xlslice
cell xilinx.com:ip:xlslice:1.0 slice_frequency {
  DIN_WIDTH 352 DIN_FROM 95 DIN_TO 64
} {
  Din cfg_0/cfg_data
}

# Create axis_constant
cell pavel-demin:user:axis_constant:1.0 phase_0 {
  AXIS_TDATA_WIDTH 32
} {
  cfg_data slice_frequency/Dout
  aclk ps_0/FCLK_CLK0
}

# Create xlconstant
cell xilinx.com:ip:xlconstant:1.1 const_modulus {
  CONST_WIDTH 32
  CONST_VAL 0
}

# Create dds_compiler
cell xilinx.com:ip:dds_compiler:6.0 dds_0 {
  DDS_CLOCK_RATE 125
  parameter_entry Hardware_Parameters
  OUTPUT_WIDTH 14
  PHASE_WIDTH 32
  PHASE_INCREMENT Streaming
  DSP48_USE Maximal
  HAS_TREADY true
  Has_ARESETn false
  Has_Phase_Out true
} {
  S_AXIS_PHASE phase_0/M_AXIS
  aclk ps_0/FCLK_CLK0
}

# Create axis_combiner
cell xilinx.com:ip:axis_combiner:1.1 comb_sine_phase {
  TDATA_NUM_BYTES.VALUE_SRC USER
  TDATA_NUM_BYTES 4
 } {
  S00_AXIS  dds_0/M_AXIS_DATA
  S01_AXIS  dds_0/M_AXIS_PHASE
  aclk ps_0/FCLK_CLK0
  aresetn rst_0/peripheral_aresetn
}



# Create clk_wiz
cell xilinx.com:ip:clk_wiz:5.3 pll_0 {
  PRIM_IN_FREQ.VALUE_SRC USER
  PRIM_IN_FREQ 125.0
  CLKOUT1_USED true
  CLKOUT1_REQUESTED_OUT_FREQ 250.0
} {
  clk_in1 adc_0/adc_clk
}


# Create axis_broadcaster
cell xilinx.com:ip:axis_broadcaster:1.1 bcast_DDS {
  S_TDATA_NUM_BYTES 8
  M_TDATA_NUM_BYTES 8
 } {
  S_AXIS  comb_sine_phase/M_AXIS
  aclk ps_0/FCLK_CLK0
  aresetn rst_0/peripheral_aresetn
}

# Create axis_lfsr
cell pavel-demin:user:axis_lfsr:1.0 lfsr_0 {} {
  aclk ps_0/FCLK_CLK0
  aresetn rst_0/peripheral_aresetn
}


# Create axis_lfsr
cell pavel-demin:user:axis_lfsr:1.0 lfsr_1 {} {
  aclk ps_0/FCLK_CLK0
  aresetn rst_0/peripheral_aresetn
}

# Create xlslice
cell xilinx.com:ip:xlslice:1.0 slice_dds_delay {
  DIN_WIDTH 352 DIN_FROM 255 DIN_TO 224
} {
  Din cfg_0/cfg_data
}

# Create axis_data_fifo
cell xilinx.com:ip:axis_data_fifo:1.1 fifo_delay {
  FIFO_DEPTH 512
  TDATA_NUM_BYTES.VALUE_SRC USER
  TDATA_NUM_BYTES 8
} {
  s_axis_aclk ps_0/FCLK_CLK0
  s_axis_aresetn rst_0/peripheral_aresetn
}

# create delay
cell pavel-demin:user:axis_delay:1.0 delay_dds {
  AXIS_TDATA_WIDTH 64
} {
  s_axis bcast_DDS/M01_AXIS
  s_axis_fifo fifo_delay/m_axis
  m_axis_fifo fifo_delay/s_axis 
  axis_data_count fifo_delay/axis_data_count
  cfg_data slice_dds_delay/dout
  aclk ps_0/FCLK_CLK0
  aresetn rst_0/peripheral_aresetn
}

# Create axis_combiner
cell xilinx.com:ip:axis_combiner:1.1 comb_ADC_DDS {
  TDATA_NUM_BYTES.VALUE_SRC USER
  TDATA_NUM_BYTES 8
 } {
  S00_AXIS  delay_dds/M_AXIS
  S01_AXIS  fifo_ADC/M_AXIS
  aclk ps_0/FCLK_CLK0
  aresetn rst_0/peripheral_aresetn
}

#  M02_TDATA_REMAP tdata[95:64]

# Create axis_broadcaster
cell xilinx.com:ip:axis_broadcaster:1.1 bcast_ADC_DDS {
  NUM_MI 5
  S_TDATA_NUM_BYTES 12
  M_TDATA_NUM_BYTES 8
  M00_TDATA_REMAP 48'b0,tdata[79:64]
  M01_TDATA_REMAP 32'b0,tdata[31:0]
  M02_TDATA_REMAP tdata[63:32],tdata[95:64]
  M03_TDATA_REMAP 48'b0,tdata[95:80]
  M04_TDATA_REMAP 32'b0,tdata[31:0]
 } {
  S_AXIS  comb_ADC_DDS/M_AXIS
  aclk ps_0/FCLK_CLK0
  aresetn rst_0/peripheral_aresetn
}

# Create cmpy
cell xilinx.com:ip:cmpy:6.0 mult_0 {
  FLOWCONTROL Blocking
  APORTWIDTH.VALUE_SRC USER
  BPORTWIDTH.VALUE_SRC USER
  APORTWIDTH 14
  BPORTWIDTH 14
  ROUNDMODE Random_Rounding
  OUTPUTWIDTH 28
} {
  S_AXIS_A bcast_ADC_DDS/M00_AXIS
  s_axis_b bcast_ADC_DDS/M01_AXIS
  S_AXIS_CTRL lfsr_0/M_AXIS
  aclk ps_0/FCLK_CLK0
}


# Create cmpy
cell xilinx.com:ip:cmpy:6.0 mult_1 {
  FLOWCONTROL Blocking
  APORTWIDTH.VALUE_SRC USER
  BPORTWIDTH.VALUE_SRC USER
  APORTWIDTH 14
  BPORTWIDTH 14
  ROUNDMODE Random_Rounding
  OUTPUTWIDTH 28
} {
  S_AXIS_A bcast_ADC_DDS/M03_AXIS
  s_axis_b bcast_ADC_DDS/M04_AXIS
  S_AXIS_CTRL lfsr_1/M_AXIS
  aclk ps_0/FCLK_CLK0
}

# create filter
module filter_xy_0 {
  source projects/filter_test/filter_xy.tcl
} {
  s_axis mult_0/M_AXIS_DOUT
  cfg cfg_0/cfg_data
  aclk ps_0/FCLK_CLK0
  aresetn rst_0/peripheral_aresetn
}

# create filter
module filter_xy_1 {
  source projects/filter_test/filter_xy_reversed.tcl
} {
  s_axis mult_1/M_AXIS_DOUT
  cfg cfg_0/cfg_data
  aclk ps_0/FCLK_CLK0
  aresetn rst_0/peripheral_aresetn
}


# Create axis_combiner
cell  xilinx.com:ip:axis_combiner:1.1 comb_xy {
  NUM_SI 4
  TDATA_NUM_BYTES.VALUE_SRC USER
  TDATA_NUM_BYTES 4
} {
  S00_AXIS filter_xy_0/M_AXIS_x
  S01_AXIS filter_xy_0/M_AXIS_y
  S02_AXIS filter_xy_1/M_AXIS_x
  S03_AXIS filter_xy_1/M_AXIS_y
  aclk ps_0/FCLK_CLK0
  aresetn rst_0/peripheral_aresetn
  }


#create value
cell pavel-demin:user:axis_value:1.0 value_xy {
AXIS_TDATA_WIDTH 128
} {
  s_axis comb_xy/M_AXIS
  aclk ps_0/FCLK_CLK0
  aresetn rst_0/peripheral_aresetn
}

# Create axis_packetizer_phase
cell pavel-demin:user:axis_packetizer_phase:1.0 pktzr_0 {
  AXIS_TDATA_WIDTH 32
  AXIS_TDATA_PHASE_WIDTH 32
  CNTR_WIDTH 26
  CONTINUOUS FALSE
  NON_BLOCKING TRUE
} {
  S_AXIS bcast_ADC_DDS/M02_AXIS
  cfg_data slice_record_length/Dout
  trigger trigger_0/trigger
  aclk ps_0/FCLK_CLK0
  aresetn slice_pktzr_reset/Dout
}



# Create axis_dwidth_converter
cell xilinx.com:ip:axis_dwidth_converter:1.1 conv_0 {
  S_TDATA_NUM_BYTES.VALUE_SRC USER
  S_TDATA_NUM_BYTES 4
  M_TDATA_NUM_BYTES 8
} {
  S_AXIS pktzr_0/M_AXIS
  aclk ps_0/FCLK_CLK0
  aresetn slice_write_enable/Dout
}

# Create xlconstant
cell xilinx.com:ip:xlconstant:1.1 const_2 {
  CONST_WIDTH 32
  CONST_VAL 268435456
}

# Create axis_ram_writer
cell pavel-demin:user:axis_ram_writer:1.0 writer_0 {
  ADDR_WIDTH 25
} {
  S_AXIS conv_0/M_AXIS
  M_AXI ps_0/S_AXI_HP0
  m_axi_awready  ps_0/S_AXI_HP0_AWREADY
  m_axi_wready ps_0/S_AXI_HP0_WREADY
  cfg_data const_2/dout
  aclk ps_0/FCLK_CLK0
  aresetn slice_write_enable/Dout
}

assign_bd_address [get_bd_addr_segs ps_0/S_AXI_HP0/HP0_DDR_LOWOCM]


# Create axis_level_cross
cell pavel-demin:user:axis_level_cross:1.0 level_cross {
  AXIS_TDATA_WIDTH 16
} {
  S_AXIS bcast_DDS/M00_AXIS
  aclk ps_0/FCLK_CLK0
  aresetn trigger_0/trigger
}



# Create xlslice
cell xilinx.com:ip:xlslice:1.0 slice_switch_direction {
  DIN_WIDTH 352 DIN_FROM 7 DIN_TO 7
} {
  Din cfg_0/cfg_data
}

# Create not gate
cell xilinx.com:ip:util_vector_logic:2.0 dir_gate {
  C_SIZE 1
  C_OPERATION xor
} {
  op1 level_cross/state_out
  op2 slice_switch_direction/Dout
}

# Create xlconstant
cell xilinx.com:ip:xlconstant:1.1 const_default {
  CONST_WIDTH 16
  CONST_VAL 0
}

# Create axis_switch
cell pavel-demin:user:axis_switch:1.0 switch_dac {
  AXIS_TDATA_WIDTH 16
} {
  S_AXIS level_cross/M_AXIS
  aclk ps_0/FCLK_CLK0
  switch_flag dir_gate/Res
  default_value const_default/dout
}

# Create dac_clock_converter
cell xilinx.com:ip:axis_clock_converter:1.1 fifo_DAC {
  TDATA_NUM_BYTES.VALUE_SRC USER
  TDATA_NUM_BYTES 4
} {
  s_axis switch_dac/M_AXIS
  s_axis_aclk ps_0/FCLK_CLK0
  s_axis_aresetn rst_0/peripheral_aresetn
  m_axis_aclk adc_0/adc_clk
  m_axis_aresetn const_1/dout
}

# Create axis_red_pitaya_dac
cell pavel-demin:user:axis_red_pitaya_dac:1.0 dac_0 {} {
  aclk adc_0/adc_clk
  ddr_clk pll_0/clk_out1
  locked pll_0/locked
  S_AXIS fifo_DAC/M_AXIS
  dac_clk dac_clk_o
  dac_rst dac_rst_o
  dac_sel dac_sel_o
  dac_wrt dac_wrt_o
  dac_dat dac_dat_o
}



# Create xlconstant
cell xilinx.com:ip:xlconstant:1.1 const_ID {
  CONST_WIDTH 16
  CONST_VAL 111
}

# Create xlconcat
cell xilinx.com:ip:xlconcat:2.1 concat_sts {
  NUM_PORTS 11
  IN0_WIDTH 32
  IN1_WIDTH 32
  IN2_WIDTH 1
  IN3_WIDTH 1
  IN4_WIDTH 1
  IN5_WIDTH 1
  IN6_WIDTH 12
  IN7_WIDTH 16
  IN8_WIDTH 32
  IN9_WIDTH 128
  IN10_WIDTH 32 
} {
  In0 writer_0/sts_data
  In1 pktzr_0/trigger_pos
  In2 trigger_0/trigger
  In3 pktzr_0/complete
  In4 ps_0/S_AXI_HP0_AWREADY
  In5 ps_0/S_AXI_HP0_WREADY
  In7 const_ID/dout
  In8 pktzr_0/phase
  In9 value_xy/data
  In10 const_modulus/dout
}

# Create axi_sts_register
cell pavel-demin:user:axi_sts_register:1.0 sts_0 {
  STS_DATA_WIDTH 288
  AXI_ADDR_WIDTH 32
  AXI_DATA_WIDTH 32
} {
  sts_data concat_sts/dout
}

# Create all required interconnections
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {
  Master /ps_0/M_AXI_GP0
  Clk Auto
} [get_bd_intf_pins sts_0/S_AXI]

set_property RANGE 4K [get_bd_addr_segs ps_0/Data/SEG_sts_0_reg0]
set_property OFFSET 0x40001000 [get_bd_addr_segs ps_0/Data/SEG_sts_0_reg0]

