module UART_RXX(
    input clk, 
    input UART_RX,
    input rst_n,
    output reg [7:0] data
);

wire UART_clk;
clk_divider #(.N(10), .MAX(650)) cd1 (.dclk(UART_clk), .clk(clk),.rst_n(rst_n) );//9600
parameter IDLE = 2'b00, START = 2'b01, READ = 2'b10, STOP = 2'b11;
parameter CNT_HOLD_MAX = 10'd640;
reg [1:0]  state, next_state;
reg [7:0]  next_data;
reg [4:0] count, next_count;
reg [3:0] bit_count, next_bit_count;
reg [9:0] cnt_hold, next_cnt_hold;
reg hold_valid, next_hold_valid;
always@(posedge clk) begin
    if(rst_n) begin
        state <= IDLE;
        data <= 8'd0;
        count <= 5'd0;
        bit_count <= 4'd0;
        cnt_hold <= 10'd0;
        hold_valid <= 1'b0;
    end
    else begin
        state <= next_state;
        data <= next_data;
        count <= next_count;
        bit_count <= next_bit_count;
        cnt_hold <= next_cnt_hold;
        hold_valid <= next_hold_valid;
    end
end

always@(*) begin
    case(state) 
        IDLE: begin
            next_state = UART_RX?IDLE:START; //讀到低電位就開始
            next_data = data;
            next_count = 5'd0;
            next_bit_count = 4'd0;
        end
        START: begin
            if(count==5'd8) begin //確保在中間讀到
                next_state = READ;
                next_data = data;
                next_count = 5'd0;
                next_bit_count = 4'd0;
            end
            else begin
                next_state = START;
                next_data = data;
                next_count = UART_clk? count+1'b1:count;
                next_bit_count = 4'd0;
            end
        end
        READ: begin
                if(bit_count==4'd8) begin //已經讀滿8個bit
                    next_state = STOP;
                    next_data = data;
                    next_count = 5'd0;
                    next_bit_count = 4'd0;
                end
                else begin
                    if(count==5'd16) begin //確保在中間讀到
                        next_state = READ;
                        next_data = {UART_RX, data[7:1]}; //shift
                        next_count = 5'd0;
                        next_bit_count = bit_count + 4'd1;
                    end
                    else begin
                        if(UART_clk ) begin
                            next_state = READ;
                            next_data = data;
                            next_count = count + 5'd1;
                            next_bit_count = bit_count;
                        end
                        else begin
                            next_state = READ;
                            next_data = data;
                            next_count = count;
                            next_bit_count = bit_count;
                        end
                    end
                end
        end
        STOP: begin
            if(count==5'd24) begin
                next_state = IDLE;
                next_data = data;
                next_count = 5'd0;
                next_bit_count = 4'd0;
            end
            else begin
                next_state = STOP;
                next_data = data;
                next_bit_count = bit_count;
                if(UART_clk ) begin
                   next_count = count +5'd1;
                end
                else begin
                    next_count = count;
                end
            end
        end
    endcase
end
always@(*) begin
    if(state==STOP) begin
        next_cnt_hold = 10'd0;
        next_hold_valid = 1'b1;
    end
    else begin
        if(hold_valid==1'b1) begin
            if(cnt_hold==CNT_HOLD_MAX) begin
                next_cnt_hold = 10'd0;
                next_hold_valid=1'b0;
            end
            else begin 
                if(UART_clk==1'b1) begin
                    next_cnt_hold = cnt_hold + 10'd1;
                end
                else begin
                   next_cnt_hold = cnt_hold;
                end
                next_hold_valid = 1'b1;
            end
        end
        else begin
            next_cnt_hold = 10'd0;
            next_hold_valid = 1'b0;
        end
    end
end
endmodule
