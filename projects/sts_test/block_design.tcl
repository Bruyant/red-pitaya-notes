source projects/cfg_test/block_design.tcl

# Create axi_sts_register
cell pavel-demin:user:axi_sts_register sts_0 {
  STS_DATA_WIDTH 1024
  AXI_ADDR_WIDTH 32
  AXI_DATA_WIDTH 32
} {
  sts_data cfg_0/cfg_data
}

addr 0x40001000 4K sts_0/S_AXI /ps_0/M_AXI_GP0
