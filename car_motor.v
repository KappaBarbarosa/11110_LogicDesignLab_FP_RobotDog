
module motor(
    input clk,
    input rst,
    input [7 :0]mode,
    output  [1:0]pwm
);
    parameter Stop = 8'd10; //停止
    parameter Forward =8'd11; 
    parameter Backward =8'd12;
    parameter Right_Forward=8'd13;
    parameter Left_Forward=8'd14;
    parameter Left =8'd15;
    parameter Right = 8'd16;
    parameter TurnARound = 8'd17;
    parameter NTurnARound = 8'd18;
    reg [9:0]next_left_motor, next_right_motor;
    reg [9:0]left_motor, right_motor;
    wire left_pwm, right_pwm;

    motor_pwm m0(clk, rst, left_motor, left_pwm);
    motor_pwm m1(clk, rst, right_motor, right_pwm);
    assign pwm = {left_pwm, right_pwm};
    always@(posedge clk)begin
        if(rst)begin
            left_motor <= 10'd0;
            right_motor <= 10'd0;
        end else begin
            left_motor <= next_left_motor;
            right_motor <= next_right_motor;
        end
    end
    always @(*) begin
        case (mode)
            Stop: begin
                next_left_motor=10'd0;
                next_right_motor=10'd0;
            end
            Forward: begin
                next_left_motor=10'd750;
                next_right_motor=10'd750;
            end 
            Backward: begin
                next_left_motor=10'd750;
                next_right_motor=10'd750;
            end 
            Right_Forward: begin
                next_left_motor=10'd750;
                next_right_motor=10'd700;
            end
            Left_Forward: begin
                next_left_motor=10'd700;
                next_right_motor=10'd750;
            end
            Left: begin
                next_left_motor=10'd0;
                next_right_motor=10'd750;
            end
            Right: begin
                next_left_motor=10'd750;
                next_right_motor=10'd0;
            end
            TurnARound: begin
                next_left_motor=10'd550;
                next_right_motor=10'd550;
            end
            NTurnARound: begin
                next_left_motor=10'd550;
                next_right_motor=10'd550;
            end  
            default: begin
                next_left_motor=10'd0;
                next_right_motor=10'd0;
            end
        endcase
    end
   
endmodule

module motor_pwm (
    input clk,
    input reset,
    input [9:0]duty,
	output pmod_1 //PWM
);
        
    PWM_gen pwm_0 ( 
        .clk(clk), 
        .reset(reset), 
        .freq(32'd25000),
        .duty(duty), 
        .PWM(pmod_1)
    );

endmodule

//generte PWM by input frequency & duty
module PWM_gen (
    input wire clk,
    input wire reset,
	input [31:0] freq,
    input [9:0] duty,
    output reg PWM
);
    wire [31:0] count_max = 32'd100_000_000 / freq;
    wire [31:0] count_duty = count_max * duty / 32'd1024;
    reg [31:0] count;
        
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            count <= 32'b0;
            PWM <= 1'b0;
        end else if (count < count_max) begin
            count <= count + 32'd1;
            if(count < count_duty)
                PWM <= 1'b1;
            else
                PWM <= 1'b0;
        end else begin
            count <= 32'b0;
            PWM <= 1'b0;
        end
    end
endmodule

