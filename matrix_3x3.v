module matrix_3x3
#(
parameter COL = 30,
parameter ROW = 30
)
(
	input clk,
    input rst_n,
    input valid_in,//输入数据有效信号
    input [7:0] din,     //输入的图像数据，将一帧的数据从左到右，然后从上到下依次输入
	
	output reg [7:0] matrix_11, 
	output reg [7:0] matrix_12, 
	output reg [7:0] matrix_13, 
	output reg [7:0] matrix_21, 
	output reg [7:0] matrix_22, 
	output reg [7:0] matrix_23, 
	output reg [7:0] matrix_31, 
	output reg [7:0] matrix_32, 
	output reg [7:0] matrix_33 
	
);

reg [15:0] col_cnt;
reg [15:0] row_cnt;

always @(posedge clk or negedge rst_n)
    if(rst_n == 1'b0)
        col_cnt             <=          11'd0;
    else if(col_cnt == COL-1 && valid_in == 1'b1)
        col_cnt             <=          11'd0;
    else if(valid_in == 1'b1)
        col_cnt             <=          col_cnt + 1'b1;
    else
        col_cnt             <=          col_cnt;

always @(posedge clk or negedge rst_n)
    if(rst_n == 1'b0)
        row_cnt             <=          11'd0;
    else if(row_cnt == ROW-1 && col_cnt == COL-1 && valid_in == 1'b1)
        row_cnt             <=          11'd0;
    else if(col_cnt == COL-1 && valid_in == 1'b1) 
        row_cnt             <=          row_cnt + 1'b1;

wire [7:0] q_1;
wire [7:0] q_2;

wire [7:0] dout_r2;
wire [7:0] dout_r1;
wire [7:0] dout_r0;

assign dout_r2 = din;
assign dout_r1 = q_1;
assign dout_r0 = q_2;

wire wr_en_1;
wire rd_en_1;
wire wr_en_2;
wire rd_en_2;

assign wr_en_1 = (row_cnt < ROW - 1) ? valid_in : 1'b0; //不写最后1行
assign rd_en_1 = (row_cnt > 0) ? valid_in : 1'b0; //从第1行开始读
assign wr_en_2 = (row_cnt < ROW - 2) ? valid_in : 1'b0; //不写最后2行
assign rd_en_2 = (row_cnt > 1) ? valid_in : 1'b0; //从第2行开始读

	FIFO_SC_HS_Top u1_FIFO_SC_HS_Top(
		.Data(din), //input [7:0] Data
		.Clk(clk), //input Clk
		.WrEn(wr_en_1), //input WrEn
		.RdEn(rd_en_1), //input RdEn
		.Reset(~rst_n), //input Reset
		.Q(q_1), //output [7:0] Q
		.Empty(), //output Empty
		.Full() //output Full
	);

	FIFO_SC_HS_Top u2_FIFO_SC_HS_Top(
		.Data(din), //input [7:0] Data
		.Clk(clk), //input Clk
		.WrEn(wr_en_2), //input WrEn
		.RdEn(rd_en_2), //input RdEn
		.Reset(~rst_n), //input Reset
		.Q(q_2), //output [7:0] Q
		.Empty(), //output Empty
		.Full() //output Full
	);

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        {matrix_11, matrix_12, matrix_13} <= {8'd0, 8'd0, 8'd0};
        {matrix_21, matrix_22, matrix_23} <= {8'd0, 8'd0, 8'd0};
        {matrix_31, matrix_32, matrix_33} <= {8'd0, 8'd0, 8'd0};
    end
    //------------------------------------------------------------------------- 第1排矩阵
    else if(row_cnt == 0)begin
        if(col_cnt == 0) begin        //第1个矩阵
            {matrix_11, matrix_12, matrix_13} <= {dout_r2, dout_r2, dout_r2};
            {matrix_21, matrix_22, matrix_23} <= {dout_r2, dout_r2, dout_r2};
            {matrix_31, matrix_32, matrix_33} <= {dout_r2, dout_r2, dout_r2};
        end
        else begin                    //剩余矩阵
            {matrix_11, matrix_12, matrix_13} <= {matrix_12, matrix_13, dout_r2};
            {matrix_21, matrix_22, matrix_23} <= {matrix_22, matrix_23, dout_r2};
            {matrix_31, matrix_32, matrix_33} <= {matrix_32, matrix_33, dout_r2};
        end
    end
    //------------------------------------------------------------------------- 第2排矩阵
    else if(row_cnt == 1)begin
        if(col_cnt == 0) begin        //第1个矩阵
            {matrix_11, matrix_12, matrix_13} <= {dout_r1, dout_r1, dout_r1};
            {matrix_21, matrix_22, matrix_23} <= {dout_r1, dout_r1, dout_r1};
            {matrix_31, matrix_32, matrix_33} <= {dout_r2, dout_r2, dout_r2};
        end
        else begin                    //剩余矩阵
            {matrix_11, matrix_12, matrix_13} <= {matrix_12, matrix_13, dout_r1};
            {matrix_21, matrix_22, matrix_23} <= {matrix_22, matrix_23, dout_r1};
            {matrix_31, matrix_32, matrix_33} <= {matrix_32, matrix_33, dout_r2};
        end
    end
    //------------------------------------------------------------------------- 剩余矩阵
    else begin
        if(col_cnt == 0) begin        //第1个矩阵
            {matrix_11, matrix_12, matrix_13} <= {dout_r0, dout_r0, dout_r0};
            {matrix_21, matrix_22, matrix_23} <= {dout_r1, dout_r1, dout_r1};
            {matrix_31, matrix_32, matrix_33} <= {dout_r2, dout_r2, dout_r2};
        end
        else begin                    //剩余矩阵
            {matrix_11, matrix_12, matrix_13} <= {matrix_12, matrix_13, dout_r0};
            {matrix_21, matrix_22, matrix_23} <= {matrix_22, matrix_23, dout_r1};
            {matrix_31, matrix_32, matrix_33} <= {matrix_32, matrix_33, dout_r2};
        end
    end
end

endmodule