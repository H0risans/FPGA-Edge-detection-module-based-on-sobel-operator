module sobel
#(
parameter U_COL = 1280,
parameter U_ROW = 720,
parameter value = 120
)
(
	input clk,
	input rst_n,
	
	input cmos_frame_vsync,
	input cmos_frame_hsync,
	input cmos_frame_valid,
	input [15:0]cmos_frame_data,
	
	output sobel_clk,
	output sobel_vsync,
	output sobel_hsync,
	output sobel_de,
	output [15:0] sobel_data
);

wire vs_i;
wire hs_i;
wire de_i;
wire [7:0] d_Y_i;

wire [7:0] matrix_11;
wire [7:0] matrix_12;
wire [7:0] matrix_13;
wire [7:0] matrix_21;
wire [7:0] matrix_22;
wire [7:0] matrix_23;
wire [7:0] matrix_31;
wire [7:0] matrix_32;
wire [7:0] matrix_33;

reg     [ 9:0]              Gx1,Gx3,Gy1,Gy3,Gx,Gy;
reg     [10:0]              G                    ;

assign sobel_clk = clk;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        Gx1 <= 'd0;
        Gx3 <= 'd0;
        Gy1 <= 'd0;
        Gy3 <= 'd0; 
    end
    else begin
        Gx1 <= matrix_11 + (matrix_21 << 1) + matrix_31;
        Gx3 <= matrix_13 + (matrix_23 << 1) + matrix_33;
        Gy1 <= matrix_11 + (matrix_12 << 1) + matrix_13;
        Gy3 <= matrix_31 + (matrix_32 << 1) + matrix_33; 
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        Gx <= 'd0;
        Gy <= 'd0;
    end
    else begin
        Gx <= (Gx1 > Gx3) ? (Gx1 - Gx3) : (Gx3 - Gx1);
        Gy <= (Gy1 > Gy3) ? (Gy1 - Gy3) : (Gy3 - Gy1);
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        G <= 'd0;
    end
    else begin
        G <= Gx + Gy;
    end
end

reg [3:0] Y_de_r   ;
reg [3:0] Y_hsync_r;
reg [3:0] Y_vsync_r;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        Y_de_r    <= 4'b0;
        Y_hsync_r <= 4'b0;
        Y_vsync_r <= 4'b0;
    end
    else begin  
        Y_de_r    <= {Y_de_r[2:0],    de_i};
        Y_hsync_r <= {Y_hsync_r[2:0], hs_i};
        Y_vsync_r <= {Y_vsync_r[2:0], vs_i};
    end
end

assign sobel_de    = Y_de_r[3];
assign sobel_hsync = Y_hsync_r[3];
assign sobel_vsync = Y_vsync_r[3];

assign sobel_data = (G > value) ? 16'h0000 : 16'hffff;

rgb_to_ycbcr u0_rgb_to_ycbcr
(
	.clk       (clk),
	.rst_n	   (rst_n),
	
	.rgb565    (cmos_frame_data),
	.i_h_sync  (cmos_frame_hsync),
	.i_v_sync  (cmos_frame_vsync),
	.i_data_en (cmos_frame_valid),
	
	.o_y_clk	(),

	.o_y_8b    (d_Y_i),
	.o_cb_8b   (),
	.o_cr_8b   (),

	.o_h_sync  (hs_i),
	.o_v_sync  (vs_i),
	.o_data_en (de_i)
);

matrix_3x3 #(
	.COL  (U_COL),
	.ROW  (U_ROW)
)u_matrix_3x3
(
	.clk      (clk),
	.rst_n    (rst_n),
	.valid_in (de_i),
	.din      (d_Y_i),
	
	.matrix_11(matrix_11),
	.matrix_12(matrix_12),
	.matrix_13(matrix_13),
	.matrix_21(matrix_21),
	.matrix_22(matrix_22), 
	.matrix_23(matrix_23),
	.matrix_31(matrix_31),
	.matrix_32(matrix_32),
	.matrix_33(matrix_33)
);

endmodule