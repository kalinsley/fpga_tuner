module elastic
  #(
    parameter [31:0] width_p = 8
   )
  (input [0:0] clk_i
  ,input [0:0] reset_i

  ,input [width_p - 1:0] data_i
  ,input [0:0] valid_i
  ,output [0:0] ready_o 

  ,output [0:0] valid_o 
  ,output [width_p - 1:0] data_o 
  ,input [0:0] ready_i
  );

  genvar i;
  generate 
    for (i = 0; i < width_p; i = i + 1) begin
      dff #(
      ) dff_i (
        .clk_i(clk_i),
        .reset_i(reset_i),
        .d_i(data_i[i]),
        .en_i((ready_o && valid_i)),
        .q_o(data_o[i])
      );
    end
  endgenerate

  dff #() state_i (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .d_i(ready_o && valid_i),
    .en_i(ready_o),
    .q_o(valid_o)
  );

  assign ready_o = ~valid_o || ready_i;

endmodule
