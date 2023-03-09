`timescale 1ns / 1ps
module UART_TXD(
    input clk, 
    input rst_n, 
    input [7:0] tosend, 
    input start, 
    output reg UART_TX, 
);
wire UART_clk;
wire rst_db,rst_op,st_db,st_op;
debounce d1(st_db,start,clk);
debounce d2(rst_db,rst_n,clk);
onepulse o1(st_op,st_db,clk);
onepulse o2(rst_op,rst_db,clk);    
clk_divider #( .N(14), .MAX(10420)) cd1 (.dclk(UART_clk),
                                         .clk(clk),
                                         .rst_n(rst_n)
                                         );
reg next_UART_TX;
reg [7:0] send, next_send;
parameter IDLE = 1'b0, SEND = 1'b1; 
parameter MAX_SND_SIZE = 4'd8;

reg state, next_state;
reg [3:0] bits, next_bits;
always@(posedge clk) begin
    if(rst_op) begin
        state <= IDLE;
        send <= 8'd0;
        bits <= 4'd0;
        UART_TX <= 1'b1;
        data_led <= 8'b0;
    end
    else begin
        state <= next_state;
        send <= next_send;
        bits <= next_bits;
        UART_TX <= next_UART_TX;
        data_led <= next_data_led;
    end
end
always@(*) begin
    case(state) 
        IDLE: begin
            if(st_op) begin
                next_state = SEND;
                next_UART_TX = 1'b1;
                next_send = tosend;
                next_bits = 4'd0;
            end
            else begin
                next_state = IDLE;
                next_UART_TX = 1'b1;
                next_send = tosend;
                next_bits = 4'd0;
            end
        end
        SEND: begin
            if(bits==4'd0) begin
                next_state = SEND;
                if(UART_clk) begin
                    next_UART_TX = 1'b0;//Start Bit
                    next_bits = bits + 4'd1;
                end
                else begin
                    next_UART_TX = UART_TX;
                    next_bits = bits;
                end
                next_send = send;
            end
            else if(bits>4'd0&&bits<=MAX_SND_SIZE) begin
                next_state = SEND;
                if(UART_clk) begin
                    next_UART_TX = send[0];//7th Bit to 0th Bit
                    next_bits = bits + 4'd1;
                    next_send = {1'b0,send[7:1]};
                end
                else begin
                    next_UART_TX = UART_TX;
                    next_bits = bits;
                    next_send = send;
                end
            end
            else if(bits==MAX_SND_SIZE+4'd1) begin
                next_state = SEND;
                if(UART_clk) begin
                    next_UART_TX = 1'b1;//END Bit
                    next_bits = bits + 4'd1;
                end
                else begin
                    next_UART_TX = UART_TX;
                    next_bits = bits;
                end
                next_send = send;
            end
            else begin
                if(UART_clk)begin
                    next_state = IDLE;
                    next_UART_TX = 1'b1;
                    next_send = tosend;
                    next_bits = 4'd0;
                end
                else begin
                    next_state = SEND;
                    next_UART_TX = UART_TX;
                    next_send = send;
                    next_bits = bits;
                end
            end
        end
    endcase
end
endmodule
