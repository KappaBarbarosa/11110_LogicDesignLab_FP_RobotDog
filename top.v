module Top(    
    input clk,
    input rst_n,
    input next,   //測試時可以快速跳過車車state的按鈕
    input sensor, //數位聲音感測模組的訊號
    input vauxp6, //類比聲音感設模組的訊號
    input vauxn6, //for xadc
    input vauxp7, //for xadc
    input vauxn7, //for xadc
    input vauxp15, //for xadc
    input vauxn15, //for xadc
    input vauxp14, //for xadc
    input vauxn14, //for xadc
    input vp_in, //for xadc
    input vn_in, //for xadc
    input SlaveRx, //藍芽的輸入
    input [2:0] mode, //決定要Record還是Display
    input [2:0] cmd,  //決定要哪一個指令
    output left_motor, //ENA
    output  [1:0]left, //IN1 IN2
    output right_motor, //ENB
    output [1:0]right ,// IN3 IN4
    output [6:0] segment,
    output [3:0] AN,
    output [2:0] car_state, //車車的state
    output [2:0] recorder_state, //Recorder的state
    output [2:0] motor, //車車馬達的狀態
    output  [3:0] fromleft_cnt, //顯示類比訊號是否有一定的強度
    output pwm_out);    //伺服馬達輸出
    wire clk19,clk20;
    wire rst_db,rst;
    wire N_db,N_op;
    wire fromleft;
    wire [15:0] analogy_signal;
    wire [15:0] Cmd;
    assign fromleft_cnt = {analogy_signal[15],analogy_signal[15],analogy_signal[14],analogy_signal[14]};
    debounce d(rst_db,rst_n,clk);
    onepulse o(rst,rst_db,clk);
    debounce d1(N_db,next,clk);
    onepulse o2(N_op,N_db,clk);
    wire [2:0] Right;
    wire [10:0] rcnt;
    wire [9:0] discnt;
    wire stop_check;
    assign stop_check = Cmd==8'd88;
    XADC   xadc(clk,auxp6,vauxn6,vauxp7, vauxn7,vauxp15,vauxn15,vauxp14,vauxn14,vp_in,vn_in,analogy_signal); // XADC:類比數位轉換器
    Recorder reco(clk,clk20,rst,sensor,mode,cmd,stop_check,Right,recorder_state,discnt); //指令節奏記錄器
    Car_control co(clk,clk19,rst,sensor,Right,N_op,Cmd,left_motor,left,right_motor,right,car_state,motor,pwm_out,fromleft_cnt,rcnt);//車車控制
    NumberDisplay ND(clk ,rst,discnt,segment,AN,clk19,clk20);//顯示
    UART_RXX UR(clk,SlaveRx, rst_op, Cmd); //接收手機App的藍芽指令
endmodule