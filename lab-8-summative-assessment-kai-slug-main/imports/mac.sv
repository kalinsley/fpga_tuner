module mac
 #(parameter int_in_lp = 1
  ,parameter frac_in_lp = 11
  ,parameter int_out_lp = 10
  ,parameter frac_out_lp = 22
  ) 
  (input [0:0] clk_i
  ,input [0:0] reset_i

  ,input signed [int_in_lp - 1 : -frac_in_lp] a_i
  ,input signed [int_in_lp - 1 : -frac_in_lp] b_i
  ,input [0:0] valid_i
  ,output [0:0] ready_o 

  ,input [0:0] ready_i
  ,output [0:0] valid_o 
  ,output signed [int_out_lp - 1 : -frac_out_lp] data_o
  );

  logic signed [int_out_lp - 1 : -frac_out_lp] prod, acc;
  assign prod = (a_i * b_i);
  assign acc = prod + data_o;

  elastic #(
    .width_p(int_out_lp + frac_out_lp)
  ) pipeline_stage (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .data_i(acc),
    .valid_i(valid_i),
    .ready_o(ready_o),
    .valid_o(valid_o),
    .ready_i(ready_i),
    .data_o(data_o)
  );
   
endmodule
