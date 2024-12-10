module duplicator
  #(parameter [31:0] width_p = 8
   ,parameter [31:0] duplications_p = 2
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

   wire enable_w;
   assign enable_w = (ready_o & valid_i);

   wire reset_w;
     assign reset_w = reset_i;

   logic [width_p-1:0] data_r;
     
   always_ff @(posedge clk_i) begin
      if(reset_w)
         data_r <= '0;
      else if(enable_w) begin
         data_r <= data_i;
         $display("Took Data");
      end
   end

   wire [$clog2(duplications_p + 1)-1:0] count_w;
   assign data_o = data_r;
   assign ready_o = (count_w == 0);
   assign valid_o = (count_w != 0);

   counter
     #(.max_val_p(duplications_p)
      ,.width_p($clog2(duplications_p + 1)))
   counter_inst
     (// Outputs
      .count_o                          (count_w),
      // Inputs
      .clk_i                            (clk_i),
      .reset_i                          (reset_i),
      .up_i                             ((ready_i & valid_o) | (ready_o & valid_i)),
      .down_i                           (1'b0));

endmodule

module counter
  #(parameter [31:0] max_val_p = 15
   ,parameter width_p = $clog2(max_val_p)  
    /* verilator lint_off WIDTHTRUNC */
   ,parameter [width_p-1:0] reset_val_p = '0
    )
    /* verilator lint_on WIDTHTRUNC */
   (input [0:0] clk_i
   ,input [0:0] reset_i
   ,input [0:0] up_i
   ,input [0:0] down_i
    ,output [width_p-1:0] count_o);

   localparam [width_p-1:0] max_val_lp = max_val_p[width_p-1:0];

   logic [width_p-1:0]      count_r;

   always_ff @(posedge clk_i) begin
      if(reset_i) begin
         count_r <= reset_val_p;
      end else if (up_i & down_i) begin
         count_r <= count_r;
      end else if (up_i & ~down_i & (count_r != max_val_p)) begin
         count_r <= count_r + 1;
      end else if (up_i & ~down_i) begin
         count_r <= '0;
      end else if (~up_i & down_i & (count_r != 0)) begin
         count_r <= count_r - 1;
      end else if (~up_i & down_i) begin
         count_r <= max_val_lp;
      end
   end

   assign count_o = count_r;

endmodule
