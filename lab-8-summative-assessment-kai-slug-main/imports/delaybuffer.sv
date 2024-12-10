module delaybuffer
  #(parameter [31:0] width_p = 8
   ,parameter [31:0] delay_p = 8
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

  localparam counter_width = (delay_p != 1) ? $clog2(delay_p) : 1;

  wire upshake, downshake;

  logic [counter_width-1:0] rd_addr_d, rd_addr_q, wr_addr_d, wr_addr_q;

  assign upshake = ready_o && valid_i;
  assign downshake = ready_i && valid_o;
  
  wire [width_p-1:0] ram_o;
  ram_1r1w_sync #(
    .width_p(width_p),
    .depth_p(delay_p)
  ) mem (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .wr_valid_i(upshake),
    .wr_data_i(data_i),
    .wr_addr_i(wr_addr_q),
    .rd_valid_i(downshake),
    .rd_addr_i(rd_addr_q),
    .rd_data_o(ram_o)
  );
  
  always_comb begin
    rd_addr_d = rd_addr_q;
    wr_addr_d = wr_addr_q;
    if ((delay_p != 1) && (upshake)) begin
        rd_addr_d = rd_addr_q + 1;
        wr_addr_d = wr_addr_q + 1;
      end
  end

  always_ff @(posedge clk_i) begin
    if (reset_i) begin
      wr_addr_q <= 0;
      rd_addr_q <= 0;
    end else begin
      wr_addr_q <= wr_addr_d;
      rd_addr_q <= rd_addr_d;
    end
  end

  reg valid_ol;
  always_ff @(posedge clk_i) begin
    if(reset_i) begin // Positive, synchronous reset
      valid_ol <= 0;
    end else if (ready_o) begin
      valid_ol <= ready_o && valid_i;
    end
  end

  assign valid_o = valid_ol;
  assign ready_o = ~valid_o || ready_i;

  assign data_o = ram_o;

endmodule