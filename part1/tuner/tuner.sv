module tuner
 #(parameter int_in_lp = 1
  ,parameter frac_in_lp = 11
  ) 
  (input [0:0] clk_i
  ,input [0:0] reset_i

  ,input [int_in_lp - 1 : -frac_in_lp] audio_i
  ,input [0:0] valid_i
  ,output [0:0] ready_o 

  ,output [7 : 0] ssd_o
  );

   assign ready_o = 1;

   // WIRES
   wire [16:0] sample_count;
   wire [11:0] a_freq, b_freq, c_freq, d_freq, e_freq, f_freq, g_freq;
   logic [11:0] sinusoid_o;
   logic mac_ready_o, mac_valid_o;
   logic [31:0] abs_o, mac_o, buffer_o;
   logic buffer_ready_o, buffer_valid_o;
   logic [2:0] tuning_note_d, tuning_note_q;
   logic [31:0] max_freq_d, max_freq_q;
   wire [2:0] note_count;

   //  -------------------------------------------------------- MAX COMPARATOR --------------------------------------------------------
   always_comb begin
      if (buffer_o > max_freq_q) begin
         tuning_note_d = note_count;
         max_freq_d = buffer_o;
      end else begin
         tuning_note_d = tuning_note_q;
         max_freq_d = max_freq_q;
      end
   end

   always_ff @(posedge clk_i) begin
      if (reset_i) begin
         tuning_note_q <= 0;
         max_freq_q <= 0;
      end else begin
         max_freq_q <= max_freq_d;
         tuning_note_q <= tuning_note_d;
      end
   end

   // -------------------------------------------------------- SIN GENERATORS --------------------------------------------------------
   sinusoid #(
      .width_p(12),
      .note_freq_p(440)
   ) A_gen (
      .clk_i,
      .reset_i,
      .ready_i(valid_i && ready_o),
      .data_o(a_freq),
      .valid_o()
   );

   sinusoid #(
      .width_p(12),
      .note_freq_p(496)
   ) B_gen (
      .clk_i,
      .reset_i,
      .ready_i(valid_i && ready_o),
      .data_o(b_freq),
      .valid_o()
   );

   sinusoid #(
      .width_p(12),
      .note_freq_p(262)
   ) C_gen (
      .clk_i,
      .reset_i,
      .ready_i(valid_i && ready_o),
      .data_o(c_freq),
      .valid_o()
   );

   sinusoid #(
      .width_p(12),
      .note_freq_p(294)
   ) D_gen (
      .clk_i,
      .reset_i,
      .ready_i(valid_i && ready_o),
      .data_o(d_freq),
      .valid_o()
   );

   sinusoid #(
      .width_p(12),
      .note_freq_p(329)
   ) E_gen (
      .clk_i,
      .reset_i,
      .ready_i(valid_i && ready_o),
      .data_o(e_freq),
      .valid_o()
   );

   sinusoid #(
      .width_p(12),
      .note_freq_p(350)
   ) F_gen (
      .clk_i,
      .reset_i,
      .ready_i(valid_i && ready_o),
      .data_o(f_freq),
      .valid_o()
   );

   sinusoid #(
      .width_p(12),
      .note_freq_p(392)
   ) G_gen (
      .clk_i,
      .reset_i,
      .ready_i(valid_i && ready_o),
      .data_o(g_freq),
      .valid_o()
   );

   // -------------------------------------------------------- NOTE MUX -----------------------------------------------------------
   always_comb begin
      case (note_count)
         3'd0 : sinusoid_o = a_freq;
         3'd1 : sinusoid_o = b_freq;
         3'd2 : sinusoid_o = c_freq;
         3'd3 : sinusoid_o = d_freq;
         3'd4 : sinusoid_o = e_freq;
         3'd5 : sinusoid_o = f_freq;
         3'd6 : sinusoid_o = g_freq;
         default : sinusoid_o = a_freq;
      endcase
   end

   // ------------------------------------------------------------ MAC ------------------------------------------------------------
   mac #(
    .int_in_lp(2),
    .frac_in_lp(10),
    .int_out_lp(17),
    .frac_out_lp(15)
   ) sinusoid_mac (
      .clk_i(clk_i),
      .reset_i(sample_count == 17'd6536 || reset_i),
      .a_i(sinusoid_o),
      .b_i(audio_i),
      .valid_i(valid_i && ready_o),
      .ready_o(mac_ready_o),
      .ready_i(buffer_ready_o),
      .valid_o(mac_valid_o),
      .data_o(mac_o)
   );

   assign abs_o = ($signed(mac_o) > 0) ? $signed(mac_o) : -$signed(mac_o);

   // -------------------------------------------------------- COUNTERS  ---------------------------------------------------------
   counter #(
      .width_p(17)
   ) sample_counter (
      .clk_i,
      .reset_i(sample_count == 17'd6537 || reset_i),
      .up_i(valid_i && ready_o),
      .down_i(1'b0),
      .count_o(sample_count)
   );

   counter #(
      .width_p(3)
   ) note_counter (
      .clk_i,
      .reset_i(note_count == 3'd7 || reset_i),
      .up_i(sample_count == 17'd6537),
      .down_i(1'b0),
      .count_o(note_count)
   );
   
   // -------------------------------------------------------- DELAY BUFFER  --------------------------------------------------------
   delaybuffer #(
      .width_p(32),
      .delay_p(6)
   ) delay_buffer (
      .clk_i,
      .reset_i,
      .data_i(abs_o),
      .valid_i(mac_valid_o),
      .ready_o(buffer_ready_o),
      .valid_o(buffer_valid_o),
      .ready_i(1'b1),
      .data_o(buffer_o)
   );

   //  -------------------------------------------------------- HEX DISPLAY --------------------------------------------------------
   logic [6:0] note_display;
   always_comb begin
      case (tuning_note_q)
         3'd0 : note_display =   7'b0001000;     // A
         3'd1 : note_display =   7'b0000011;     // B
         3'd2 : note_display =   7'b1000110;     // C
         3'd3 : note_display =   7'b0100001;     // D
         3'd4 : note_display =   7'b0000110;     // E
         3'd5 : note_display =   7'b0001110;     // F
         3'd6 : note_display =   7'b0010000;     // G
         default: note_display = 7'b1111111;
      endcase
   end

   assign ssd_o = note_display;

endmodule
