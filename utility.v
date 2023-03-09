module Clock_Divider (clk,rst_n, display_clk,num_clk,sensor_clk);
input clk,rst_n;
output reg display_clk,num_clk, sensor_clk;
reg [17:0] ctr_co;
reg [19:0] ctr_CO;
reg [20:0] ctr_cO;
always @(posedge clk) begin
    if(rst_n) begin
    ctr_co <= 1'b0;
    ctr_CO <=1'b0;
    ctr_cO <= 1'b0;
    end
    else begin
    ctr_co <= ctr_co+1'b1;
    ctr_CO <= ctr_CO+1'b1;
    ctr_cO <= ctr_cO+1'b1;
    end
    
end

always @(posedge clk) begin
    if(rst_n) begin
        display_clk <=1'b0;
        num_clk <= 1'b0;
        sensor_clk <= 1'b0;
    end
    else begin
        display_clk <= ctr_co== 18'b111111111111111111;
        num_clk <= ctr_CO== 20'b11111111111111111111;
        sensor_clk <= ctr_cO == 21'b111111111111111111111;
    end
    
end
endmodule

module debounce (pb_debounced, pb, clk);
 output pb_debounced; // signal of a pushbutton after being debounced
 input pb; // signal from a pushbutton
 input clk;

 reg [3:0] DFF; // use shift_reg to filter pushbutton bounce
 always @(posedge clk)
 begin
 DFF[3:1] <= DFF[2:0];
 DFF[0] <= pb;
 end
 assign pb_debounced = ((DFF == 4'b1111) ? 1'b1 : 1'b0);
endmodule
module Debounce (pb_debounced, pb, clk);
 output pb_debounced; // signal of a pushbutton after being debounced
 input pb; // signal from a pushbutton
 input clk;

 reg [5:0] DFF; // use shift_reg to filter pushbutton bounce
 always @(posedge clk)
 begin
 DFF[5:1] <= DFF[4:0];
 DFF[0] <= pb;
 end
 assign pb_debounced = ((DFF == 6'b111111) ? 1'b1 : 1'b0);
endmodule
module onepulse (PB_one_pulse,PB_debounced, CLK);
 input PB_debounced;
 input CLK;
 output PB_one_pulse;
 reg PB_one_pulse;
 reg PB_debounced_delay;
 always @(posedge CLK) begin
 PB_one_pulse <= PB_debounced & (! PB_debounced_delay);
 PB_debounced_delay <= PB_debounced;
 end
endmodule

module trasfer(input [3:0] in, output reg [6:0] out);
always @(*) begin
    case (in)
        4'd0: out = 7'b0000001;   
        4'd1: out = 7'b1001111; 
        4'd2: out = 7'b0010010;  
        4'd3: out = 7'b0000110; 
        4'd4: out = 7'b1001100; 
        4'd5: out = 7'b0100100;  
        4'd6: out = 7'b0100000; 
        4'd7: out = 7'b0001111; 
        4'd8: out = 7'b0000000;  
        4'd9: out = 7'b0000100;
        4'd10: out = 7'b0001000;
        4'd11: out = 7'b1100000; 
        4'd12: out = 7'b1111111;
        default: out=7'b1111111;
    endcase
end
endmodule
module NumberDisplay(clk , rst_n,Cnt,segment,AN,clk19,clk20);
input clk,rst_n;
input [19:0] Cnt;
output reg [3:0] AN;
output reg [6:0] segment;
wire [9:0] cnt;
assign cnt = Cnt <= 9999? Cnt:9999;
wire [6:0] cotrasfer [3:0];
wire [3:0]A,B,C,D;
assign A = cnt/1000;
assign B = (cnt - A*1000)/100;
assign C = ( cnt - A*1000 - B*100)/10;
assign D = (cnt - A*1000 - B*100 - C*10);
trasfer t0(A,cotrasfer[3]);
trasfer t1(B,cotrasfer[2]);
trasfer t2(C,cotrasfer[1]);
trasfer t3(D,cotrasfer[0]);
reg [1:0] rf_cnt;
wire [1:0] nrfcnt;
wire clk17;
output clk19;
output clk20;
 Clock_Divider CD(clk,rst_n, clk17,clk19,clk20);
//display
always @(posedge clk) begin
    if(rst_n) rf_cnt<=2'b0;
    else  rf_cnt <= nrfcnt;
end
assign nrfcnt =  clk17?rf_cnt+1'b1:rf_cnt;
always @(*) begin
    case(rf_cnt)
    2'd0: begin
        AN = 4'b0111;
        segment = cotrasfer[3];
    end
    2'd1: begin
        AN = 4'b1011;
        segment = cotrasfer[2];
    end
    2'd2: begin
        AN = 4'b1101;
        segment = cotrasfer[1];
    end
    2'd3: begin
        AN = 4'b1110;
        segment = cotrasfer[0];
    end
    endcase
end
endmodule
module clk_divider#(parameter N = 5, parameter MAX = 20)(dclk, clk, rst_n);
input clk, rst_n;
output reg dclk;
reg next_dclk;
reg [N-1:0] counter;
reg [N-1:0] next_counter;
always@(posedge clk) begin
    if(rst_n==1'b1) begin
        counter <= 0;
        dclk <= 1'b1;
    end
    else begin
        counter <= next_counter;
        dclk <= next_dclk;
    end
end

always@(*) begin
    if(counter==MAX-1) begin
        next_dclk = 1'b1;
        next_counter = 0;         
    end
    else begin
        next_dclk = 1'b0;
        next_counter = counter + 1;
    end
end
endmodule
module sonic_top(clk, rst, Echo, Trig, d);
	input clk, rst, Echo;
	output Trig;
    //output [9:0] od;
	wire [19:0] dis;
	output [19:0] d;
    wire clk1M;
	wire clk_2_17;
    assign d = dis/100;
    div clk1(clk ,clk1M);
	TrigSignal u1(.clk(clk), .rst(rst), .trig(Trig));
	PosCounter u2(.clk(clk1M), .rst(rst), .echo(Echo), .distance_count(dis));
    //assign od = dis/63; //12500 - 40cm
endmodule

module PosCounter(clk, rst, echo, distance_count); 
    input clk, rst, echo;
    output[19:0] distance_count;

    parameter S0 = 2'b00;
    parameter S1 = 2'b01; 
    parameter S2 = 2'b10;
    
    wire start, finish;
    reg[1:0] curr_state, next_state;
    reg echo_reg1, echo_reg2;
    reg[19:0] count, next_count, distance_register, next_distance;
    wire[19:0] distance_count; 

    always@(posedge clk) begin
        if(rst) begin
            echo_reg1 <= 1'b0;
            echo_reg2 <= 1'b0;
            count <= 20'b0;
            distance_register <= 20'b0;
            curr_state <= S0;
        end
        else begin
            echo_reg1 <= echo;   
            echo_reg2 <= echo_reg1; 
            count <= next_count;
            distance_register <= next_distance;
            curr_state <= next_state;
        end
    end

    always @(*) begin
        case(curr_state)
            S0: begin
                next_distance = distance_register;
                if (start) begin
                    next_state = S1;
                    next_count = count;
                end else begin
                    next_state = curr_state;
                    next_count = 20'b0;
                end 
            end
            S1: begin
                next_distance = distance_register;
                if (finish) begin
                    next_state = S2;
                    next_count = count;
                end else begin
                    next_state = curr_state;
                    next_count = (count > 20'd600_000) ? count : count + 1'b1;
                end 
            end
            S2: begin
                next_distance = count;
                next_count = 20'b0;
                next_state = S0;
            end
            default: begin
                next_distance = 20'b0;
                next_count = 20'b0;
                next_state = S0;
            end
        endcase
    end

    assign distance_count = distance_register * 20'd100 / 20'd58; 
    assign start = echo_reg1 & ~echo_reg2;  
    assign finish = ~echo_reg1 & echo_reg2; 
endmodule

module TrigSignal(clk, rst, trig);
    input clk, rst;
    output trig;

    reg trig, next_trig;
    reg[23:0] count, next_count;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            count <= 24'b0;
            trig <= 1'b0;
        end
        else begin
            count <= next_count;
            trig <= next_trig;
        end
    end

    always @(*) begin
        next_trig = trig;
        next_count = count + 1'b1;
        if(count == 24'd999)
            next_trig = 1'b0;
        else if(count == 24'd9999999) begin
            next_trig = 1'b1;
            next_count = 24'd0;
        end
    end
endmodule

module div(clk ,out_clk);
    input clk;
    output out_clk;
    reg out_clk;
    reg [6:0]cnt;
    
    always @(posedge clk) begin   
        if(cnt < 7'd50) begin
            cnt <= cnt + 1'b1;
            out_clk <= 1'b1;
        end 
        else if(cnt < 7'd100) begin
	        cnt <= cnt + 1'b1;
	        out_clk <= 1'b0;
        end
        else if(cnt == 7'd100) begin
            cnt <= 7'b0;
            out_clk <= 1'b1;
        end
        else begin 
            cnt <= 7'b0;
            out_clk <= 1'b1;
        end
    end
endmodule
