
`timescale 1 ns / 1 ps

module gpio_delayed_trigger #
(
  parameter integer GPIO_DATA_WIDTH = 8,
  parameter integer GPIO_INPUT_WIDTH = 4,
  parameter integer GPIO_OUTPUT_WIDTH = 4
)
(
  // System signals
  input  wire                        aclk,
  input  wire                        aresetn,

  inout  wire [GPIO_DATA_WIDTH-1:0]  gpio_data,
  input  wire [GPIO_OUTPUT_WIDTH-1:0]  out_data,


  input  wire                        soft_trig,
  input  wire [31:0]                 delay,
  output wire                        trigger,
  output wire                        instant_trigger,
  output wire                        delay_pulse
);

  reg  [GPIO_DATA_WIDTH-1:0] int_data_reg [1:0];
  reg  triggered, int_trig_reg, int_trig_reg_next,out_trig, out_trig_next;
  reg  [31:0] counter, counter_next;
  wire [GPIO_DATA_WIDTH-1:0] int_data_wire;
  wire int_comp_wire;
  wire [GPIO_OUTPUT_WIDTH-1:0] int_output;

  genvar j;


  // input pins
  generate
    for(j = 0; j < GPIO_INPUT_WIDTH; j = j + 1)
      begin : GPIO
        IOBUF gpio_iobuf (.O(int_data_wire[j]), .IO(gpio_data[j]), .I({(GPIO_INPUT_WIDTH){1'b0}}), .T(1'b1)); 
      end
  endgenerate

  // output pins
  generate
    for(j = GPIO_INPUT_WIDTH; j < GPIO_DATA_WIDTH; j = j + 1)
      begin : GPIO_OUT
        IOBUF gpio_iobuf (.O(int_data_wire[j]), .IO(gpio_data[j]), .I(int_output[j-GPIO_INPUT_WIDTH]), .T(1'b0)); 
      end
  endgenerate
 
  assign int_comp_wire = counter < delay;
  always @(posedge aclk)
  begin
      int_data_reg[0] <= int_data_wire;
      int_data_reg[1] <= int_data_reg[0];
      if(~aresetn)
         begin
      	int_trig_reg <= 1'b0;
           out_trig <= 1'b0;
           counter <= 32'b0;
         end
      else
         begin
  	    int_trig_reg <= int_trig_reg_next;
            out_trig <= out_trig_next;
            counter <= counter_next;
         end
  end

  always @*
  begin 
      int_trig_reg_next = int_trig_reg;
      out_trig_next = out_trig;
      counter_next = counter;
      if(soft_trig | int_data_reg[1][0:0])
          int_trig_reg_next = 1'b1;
      if ( int_comp_wire & int_trig_reg)
           counter_next=counter  + 1'b1;
      if ( ~int_comp_wire)
          out_trig_next = 1'b1;
      end
    

  assign trigger  = out_trig;
  assign instant_trigger  = int_trig_reg;
  assign delay_pulse = instant_trigger&~trigger;
  assign int_output = {{(GPIO_OUTPUT_WIDTH-1){1'b0}},delay_pulse};

endmodule
