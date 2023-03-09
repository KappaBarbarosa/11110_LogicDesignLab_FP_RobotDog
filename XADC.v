`timescale 1ns / 1ps
module XADC(
    input CLK100MHZ,
    input vauxp6,
    input vauxn6,
    input vauxp7,
    input vauxn7,
    input vauxp15,
    input vauxn15,
    input vauxp14,
    input vauxn14,
    input vp_in,
    input vn_in,
    output reg [15:0] led
);
    wire enable;  
    wire ready;
    wire [15:0] data;   
    wire [6:0] Address_in;
    assign Address_in = 8'h1e;
    //xadc instantiation connect the eoc_out .den_in to get continuous conversion
    xadc_wiz_0  XLXI_7 (
        .daddr_in(Address_in),
        .dclk_in(CLK100MHZ), 
        .den_in(enable), 
        .di_in(0), 
        .dwe_in(0), 
        .busy_out(),                    
        .vauxp6(vauxp6),
        .vauxn6(vauxn6),
        .vauxp7(vauxp7),
        .vauxn7(vauxn7),
        .vauxp14(vauxp14),
        .vauxn14(vauxn14),
        .vauxp15(vauxp15),
        .vauxn15(vauxn15),
        .vn_in(vn_in), 
        .vp_in(vp_in), 
        .alarm_out(), 
        .do_out(data), 
        //.reset_in(),
        .eoc_out(enable),
        .channel_out(),
        .drdy_out(ready)
    );  
    //led visual dmm              
    always @(posedge(CLK100MHZ)) begin            
        if(ready == 1'b1) begin
            case (data[15:12])
            13: led <= 16'b11111111111111;
            14: led <= 16'b111111111111111;
            15: led <= 16'b1111111111111111;                        
            default: led <= 16'b1; 
            endcase
        end
    end     
endmodule
