module  motor_contorl(clk,rst_n,da_in,pwm_out,state);
input clk;
input rst_n;
input  da_in;
input [3:0] state;
output reg pwm_out;
reg [3:0] next_state;
parameter  s=32'd1000_000;//20ms-----T
parameter  s0=32'd500_000;//2.5ms----180
parameter  s2=32'd125_000;//1.5ms----90
reg	[31:0] cnt_r,cnt,ncnt_r;
wire [31:0] ncnt;	

always @(posedge clk)begin
	if(rst_n) pwm_out <= 1'b0;
	else if(cnt <= cnt_r) pwm_out <= 1'b1;
	else pwm_out <= 1'b0;
end
always @(posedge clk ) begin
	if(rst_n) cnt_r <=31'd0;
	else cnt_r <= ncnt_r;
end
always@(*) begin
	if(cnt_r==s2) ncnt_r = state==NOCOMMAND? s0:s2; //回到nocommand再鬆開夾子
	else begin
		case(da_in)
			1'd0: ncnt_r = s0;
			1'd1: ncnt_r = s2; //夾住
			default: ncnt_r = s0;
		endcase
	end
end
always @(posedge clk)begin
	if(rst_n) cnt <= 32'd0;
	else cnt <= ncnt;
end
assign ncnt = (cnt>=s)?32'd0:cnt+1'b1;

endmodule