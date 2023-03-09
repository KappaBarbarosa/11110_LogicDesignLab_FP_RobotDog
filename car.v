module Car_control (
    input clk,
    input clk19,
    input rst,
    input sensor,
    input [2:0] Right,
    input next,
    input [7:0] cmd;
    output left_Motor, //ENA
    output reg [1:0]left, //IN1 IN2
    output right_Motor, //ENB
    output reg [1:0]right ,// IN3 IN4
    output reg [3:0]state,
    output reg [3:0] Motor,
    output wire pwm_out,
    input [3:0] fromleft,
    output reg[10:0] rcnt);
parameter NOCOMMAND=3'd0, Ready=3'd1, Find_search=3'd2,Return=3'd3, Stop=3'd4,Find_go=3'd5,
          Return_to_left=3'd7, Return_to_right=3'd6;
parameter cycle = 9'd128, Stop = 8'd10, Forward =8'd11, Backward =8'd12, Right_Forward=8'd13,
          Left_Forward=8'd14, Left =8'd15, Right = 8'd16, TurnARound = 8'd17, NTurnARound = 8'd18,
          catch = 8'd19, toReturn = 8'd20;
reg [3:0] next_state;
reg [10:0]nrcnt;
reg [3:0] next_Motor;
wire  da_in;
assign da_in =  state== Find_search & cmd==catch; //控制伺服馬達
motor_contorl mc(clk,rst,da_in,pwm_out,state);
motor m(clk,rst,Motor,{left_motor,right_motor}); //車車馬達
always @(*) begin //車車馬達轉向
    case (Motor)
        3'd0:  {left, right}  = 4'd0;
        3'd7: {left, right}  = 4'b1001;
        default: {left, right} =4'b0101;
    endcase
end

always @(posedge clk ) begin
    if(rst) begin
        state<=NOCOMMAND;
        rcnt <=0;
        Motor<=0;
    end
    else begin 
        state<=next_state;
        rcnt <= nrcnt;
        Motor<=next_Motor;
        display_dis <= ndisplay_dis;
    end

end
always @(*) begin  //車車state
    next_dis = dismemory[rcnt];
    ndisplay_dis=display_dis;
    //nrcnt = rcnt;
    case (state)
        NOCOMMAND: begin//等待Ready訊號
            next_state = (next | Right== Ready)? Find_search:NOCOMMAND;
            nrcnt =0;
            next_Motor=0;
        end
        Find_search: begin // 藍芽控制
            if(clk19) begin
                next_Motor = cmd;
            end else begin
                next_Motor = Motor;
            end
            next_state = toReturn? Return:Find_search; //等待Return訊號
        end 
        Return: begin
            if(clk19) begin
                nrcnt = rcnt+1;
                if(rcnt <500 && rcnt >=200) begin //車子暫停，等待聲音指令
                    next_Motor = SStop;
                    next_state = ( next | Right==Stop)?NOCOMMAND:Return;
                end else begin
                    if(rcnt < 200) begin //直線往前
                       next_Motor = Forward;
                       next_state =  ( next | Right==Stop)?NOCOMMAND:Return;
                    end else begin//500單位後
                        if(fromleft > 0) begin  //類比訊號強度夠，往左
                            next_state = Right==Stop? NOCOMMAND: Return_to_left;
                            next_Motor = Left_Forward;
                        end else begin
                            if( sensor | rcnt>300) begin
                                next_state = Right==Stop? NOCOMMAND: Return_to_right;
                                next_Motor = Right_Forward;
                         end else begin
                             next_Motor = SStop;
                             nrcnt=rcnt;
                         end
                        end
                    end
                end
            end else begin
                nrcnt = rcnt;
                next_state = state;
                next_Motor = Motor;
            end
            end
        default: begin
            if(clk19 ) begin
                if(rcnt <330) begin //30單位的轉向
                    nrcnt = rcnt+1;
                    next_state = state;
                    next_Motor = Motor;
                end else begin
                    nrcnt = 0;
                    next_state = Return;
                    next_Motor = Forward;
                end
            end else begin
                nrcnt = rcnt;
                next_state = state;
                next_Motor = Motor;
            end
        end
    endcase
end 

endmodule


