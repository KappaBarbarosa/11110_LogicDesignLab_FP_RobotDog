module Recorder (clk,clk19,rst_n,da_in,mode,cmd,stop_check,Right,state,cnt);
input clk,clk19,rst_n,da_in,stop_check;
input [2:0] cmd,mode;
output reg [9:0] cnt;
output reg[3:0] Right;
reg [3:0] right;
//----------------------------------------------------------------------------
parameter Wait = 3'd2 , Record=3'd1, Check=3'd0 , Display=3'd4;
parameter NOCOMMAND=3'd0,Ready = 3'd1,Find=3'd2,Return=3'd3, Stop=3'd4;
//---------------------------------------------------------------------------- CmdRecorder
output reg [2:0] state;
reg [2:0] next_state;
reg [9:0] ReadyRecorder [10:0];
reg [9:0] FindRecorder [10:0];
reg [9:0] ReturnRecorder [10:0];
reg [9:0] StopRecorder [10:0];
//---------------------------------------------------------------------------- Counter
reg [9:0]newReady,ncnt,newFind,newReturn,newStop,Display_cnt,ndc; // new tone
reg [3:0] Ready_cnt,CReady_cnt;
reg [3:0] Next_Ready_cnt,Next_Find_cnt,Next_Return_cnt,Next_Stop_cnt,Return_cnt,Stop_cnt,Find_cnt;
reg [3:0] Next_CReady_cnt,CFind_cnt,Next_CFind_cnt,CReturn_cnt,Next_CReturn_cnt,CStop_cnt,Next_CStop_cnt,tmp1,tmp2,tmp3,tmp4;

reg [3:0] Check_Signal;
wire ReadyDone,FindDone,ReturnDone,StopDone;
wire [3:0] Dc;
assign Dc = Display_cnt/25;
assign ReadyDone = Ready_cnt==10, FindDone = Find_cnt==10, ReturnDone = Return_cnt==10, StopDone = Stop_cnt == 10; //最多紀錄十組
//----------------------------------------------------------------------------preprocess
wire DD,DA_in,SD,SC;
debounce d1(DD,da_in,clk);
onepulse o1(Da_in,DD,clk); //對聲音感測模組進行one_pulse
debounce d2(SD,stop_check,clk);
onepulse o2(SC,SD,clk);
reg f,S;
wire nf,nS;
always @(posedge clk)begin
    if(Da_in) f <= Da_in;
    else f<=nf;
    if(SC) S <= SC;
    else S<=nS;
end
assign nf = clk19?1'b0:f;
assign nS = clk19?1'b0:S;
//---------------------------------------------------------------------------- 
parameter CheckWait=3'd0, Checking=3'd1,Error=3'd2,Done=3'd3;
reg[2:0] Ready_Check_state;
reg[2:0] NRC,Find_Check_state,NFC,Return_Check_state,NREC,Stop_Check_state,NSC;
always @(posedge clk ) begin
    if(rst_n | state!=Check) begin
        Ready_Check_state <= CheckWait;
        Find_Check_state <= CheckWait;
        Return_Check_state <= CheckWait;
        Stop_Check_state <= CheckWait;
        CReady_cnt <=0;
        CFind_cnt <=0;
        CReturn_cnt <=0;
        CStop_cnt<=0;
    end else begin
        Ready_Check_state <= NRC;
        Find_Check_state <= NFC;
        Return_Check_state <= NREC;
        Stop_Check_state <= NSC;
        CReady_cnt <=Next_CReady_cnt;
        CFind_cnt <=Next_CFind_cnt;
        CReturn_cnt <=Next_CReturn_cnt;
        CStop_cnt<=Next_CStop_cnt;
    end
end
wire [3:0] inuprange,indownrange;
always @(*) begin
    case (Ready_Check_state)
        CheckWait: begin
            Next_CReady_cnt=0;
            NRC = (state==Check)? Checking:CheckWait; 
            tmp1=0;
        end
        Checking: begin
            if(f) begin
                if(inuprange[0] && indownrange[0]) begin
                    Next_CReady_cnt= CReady_cnt+1; //檢測到正確節奏，記錄+1
                    tmp1 = Checking;
                end
                else begin
                    Next_CReady_cnt = CReady_cnt;
                    tmp1= Checking;
                end
            end
            else begin
                Next_CReady_cnt = CReady_cnt;
                tmp1 = Checking;
            end
            if(cnt==255) NRC=Done;
            else NRC = tmp1;
        end
        Done: begin
            NRC = CheckWait;
            tmp1=0;
            Next_CReady_cnt = CReady_cnt;
        end
        default: begin
            
        end
    endcase
    Check_Signal[0]=Ready_Check_state==Done &&CReady_cnt==Ready_cnt && Ready_cnt!=0; //Done時輸出Check結果

    case (Find_Check_state)
        CheckWait: begin
            Next_CFind_cnt=0;
            NFC = (state==Check)? Checking:CheckWait;
            tmp2=0;
        end
        Checking: begin
            if(f) begin
                if(inuprange[1] && indownrange[1]) begin
                    Next_CFind_cnt= CFind_cnt+1;
                    tmp2 = Checking;
                end
                else begin
                    Next_CFind_cnt = CFind_cnt;
                    tmp2= Checking;
                end
            end
            else begin
                Next_CFind_cnt = CFind_cnt;
                tmp2 = Checking;
            end
            if(cnt==255) NFC=Done;
            else NFC = tmp2;
        end
        Done: begin
            NFC = CheckWait;
            tmp2=0;
            Next_CFind_cnt = CFind_cnt;
        end
        default: begin
            
        end
    endcase
    Check_Signal[1]=Find_Check_state==Done &&CFind_cnt==Find_cnt && Find_cnt!=0;

    case (Return_Check_state)
        CheckWait: begin
            Next_CReturn_cnt=0;
            NREC = (state==Check)? Checking:CheckWait;
            tmp3=0;
        end
        Checking: begin
            if(f) begin
                if(inuprange[2] && indownrange[2]) begin
                    Next_CReturn_cnt= CReturn_cnt+1;
                    tmp3 = Checking;
                end
                else begin
                    Next_CReturn_cnt = CReturn_cnt;
                    tmp3= Checking;
                end
            end
            else begin
                Next_CReturn_cnt = CReturn_cnt;
                tmp3 = Checking;
            end
            if(cnt==255) NRC=Done;
            else NREC = tmp3;
        end
        Done: begin
            NREC = CheckWait;
            tmp3=0;
            Next_CReturn_cnt = CReturn_cnt;
        end
        default: begin
            
        end
    endcase
    Check_Signal[2]=Return_Check_state==Done &&CReturn_cnt==Return_cnt && Return_cnt!=0;

    case (Stop_Check_state)
        CheckWait: begin
            Next_CStop_cnt=0;
            NSC = (state==Check)? Checking:CheckWait;
            tmp4=0;
        end
        Checking: begin
            if(f) begin
                if(inuprange[3] && indownrange[3]) begin
                    Next_CStop_cnt= CStop_cnt+1;
                    tmp4 = Checking;
                end
                else begin
                    Next_CStop_cnt = CStop_cnt;
                    tmp4= Checking;
                end
            end
            else begin
                Next_CStop_cnt = CStop_cnt;
                tmp4 = Checking;
            end
            if(cnt==255) NSC=Done;
            else NSC = tmp4;
        end
        Done: begin
            NSC = CheckWait;
            tmp4=0;
            Next_CStop_cnt = CStop_cnt;
        end
        default: begin
            
        end
    endcase
    Check_Signal[3]=Stop_Check_state==Done &&CStop_cnt==Stop_cnt && Stop_cnt!=0;
end

//-----------------------------------------------
always @(posedge clk ) begin
    if(rst_n) state <=Check;
    else state <=next_state;
end

always @(posedge clk ) begin
    if(rst_n)begin
        Ready_cnt<=0;
        Find_cnt<=0;
        Return_cnt<=0;
        Stop_cnt<=0;
        cnt<=0;
        Display_cnt<=0;
        Right <=0;
    end 
    else begin
        Ready_cnt<= Next_Ready_cnt;
        Find_cnt<= Next_Find_cnt;
        Return_cnt<= Next_Return_cnt;
        Stop_cnt<= Next_Stop_cnt;
        cnt<=ncnt;
        Display_cnt <= ndc;
        Right <= right;
    end
    ReadyRecorder[Ready_cnt] <= newReady;
    FindRecorder[Find_cnt] <= newFind;
    ReturnRecorder[Return_cnt] <= newReturn;
    StopRecorder[Stop_cnt] <= newStop;
end

always @(*) begin
    newReady =ReadyRecorder[Ready_cnt];
    newFind =FindRecorder[Find_cnt];
    newReturn =ReturnRecorder[Return_cnt];
    newStop=StopRecorder[Stop_cnt];
    Next_Ready_cnt =Ready_cnt;
    Next_Find_cnt = Find_cnt;
    Next_Return_cnt = Return_cnt;
    Next_Stop_cnt = Stop_cnt;
    right=Right;
    ndc = (state==Display)?clk19?Display_cnt+1:Display_cnt:0;
    case (state)
        Record: begin
                if(clk19 && f && cmd==Ready & !ReadyDone) begin
                    Next_Ready_cnt =  (Ready_cnt ==0 | cnt>ReadyRecorder[Ready_cnt-1]+5)?Ready_cnt+1:Ready_cnt; //與前一個記錄值須相差五單位以上
                    newReady = (Ready_cnt ==0 | cnt>ReadyRecorder[Ready_cnt-1]+5)? cnt:ReadyRecorder[Ready_cnt];
                end else begin
                    Next_Ready_cnt = Ready_cnt;
                    newReady = ReadyRecorder[Ready_cnt];
                end
                if(clk19 && f && cmd==Find & !FindDone) begin
                    Next_Find_cnt = (FindRecorder[Find_cnt]==0 | cnt>FindRecorder[Find_cnt-1]+5)? Find_cnt+1:Find_cnt;
                    newFind = (FindRecorder[Find_cnt]==0 | cnt>FindRecorder[Find_cnt-1]+5)? cnt:FindRecorder[Find_cnt];
                end else begin
                    Next_Find_cnt = Find_cnt;
                    newFind = FindRecorder[Find_cnt];
                end
                if(clk19 && f && cmd==Return & !ReturnDone) begin
                    Next_Return_cnt = (ReturnRecorder[Return_cnt]==0 | cnt>ReturnRecorder[Return_cnt-1]+5)? Return_cnt+1:Return_cnt;
                    newReturn = (ReturnRecorder[Return_cnt]==0 | cnt>ReturnRecorder[Return_cnt-1]+5)? cnt:ReturnRecorder[Return_cnt];
                end else begin
                    Next_Return_cnt = Return_cnt;
                    newReturn = ReturnRecorder[Return_cnt];
                end
                if(clk19 && f && cmd==Stop & !StopDone) begin
                    Next_Stop_cnt = (StopRecorder[Stop_cnt]==0 | cnt>StopRecorder[Stop_cnt-1]+5)? Stop_cnt+1:Stop_cnt;
                    newStop = (StopRecorder[Stop_cnt]==0 | cnt>StopRecorder[Stop_cnt-1]+5)? cnt:StopRecorder[Stop_cnt];
                end else begin
                    Next_Stop_cnt = Stop_cnt;
                    newStop = StopRecorder[Stop_cnt];
                end
                if(cnt==255 | cmd==Ready&ReadyDone | cmd==Find& FindDone | cmd==Return& ReturnDone | cmd==Stop& StopDone)begin //記錄結束
                     next_state = Check;
                     ncnt=0; 
                end
                else begin 
                    next_state = Record;
                    ncnt = clk19 &(f | cnt>0)? cnt+1:cnt; //拍手開始計時
                end
        end
        Check: begin //常態state
            ncnt = S?0:clk19 & (f | cnt>0)? cnt+1:cnt; //拍手開始計時
            if(cnt==0) begin //切換state
                case (mode)
                    3'b001: next_state = Display;
                    3'b100: next_state = Record;
                    default: next_state = Check;
                endcase
            end else begin
                if(Ready_Check_state == Done) begin //檢查完成，判斷是否有正確的訊號
                    case(Check_Signal)
                        4'b0001: right = Ready;
                        4'b0010: right = Find;
                        4'b0100: right = Return;
                        4'b1000: right = Stop;
                        default: right = NOCOMMAND;
                    endcase
                    ncnt=0;
                    next_state = Check;
                    end
                else begin
                    right = NOCOMMAND;
                    next_state = Check;
                end
            end
            Next_Ready_cnt = (mode==3'd4 & cmd == Ready)?0: Ready_cnt; //開始記錄時初始化記錄結果
            Next_Find_cnt = (mode==3'd4 & cmd == Find)?0: Find_cnt;
            Next_Return_cnt = (mode==3'd4 & cmd == Return)?0: Return_cnt;
            Next_Stop_cnt = (mode==3'd4 & cmd == Stop)?0: Stop_cnt;
        end 
        Display: begin //顯示記錄結果
            next_state = (Display_cnt >=256 | cmd==Ready & Dc == Ready_cnt+1 | cmd==Find & Dc == Find_cnt+1 | cmd==Return & Dc==Return_cnt+1 | cmd==Stop & Dc==Stop_cnt+1 )? Check:Display;
            case (cmd)
                Ready: ncnt =ReadyRecorder[Dc];
                Find:  ncnt =FindRecorder[Dc];
                Return:ncnt =ReturnRecorder[Dc];
                Stop:  ncnt =StopRecorder[Dc]; 
                default: ncnt=0;
            endcase
        end
        default:begin
            next_state = Check;
            ncnt=0;
        end 
    endcase
end
//允許拍的節奏與記錄有誤差，需處理上下界
assign inuprange[0] = ReadyRecorder[CReady_cnt]>235? cnt<=255 : cnt <=ReadyRecorder[CReady_cnt] +20;
assign inuprange[1] = FindRecorder[CFind_cnt]>235? cnt<=255 : cnt <=FindRecorder[CFind_cnt] +20;
assign inuprange[2] = ReturnRecorder[CReturn_cnt]>235? cnt<=255 : cnt <=ReturnRecorder[CReturn_cnt] +20;
assign inuprange[3] = StopRecorder[CStop_cnt]>235? cnt<=255 : cnt <=StopRecorder[CStop_cnt] +20;
assign indownrange[0] = ReadyRecorder[CReady_cnt]<25? cnt>=0 : cnt >=ReadyRecorder[CReady_cnt] -20;
assign indownrange[1] = FindRecorder[CFind_cnt]<25? cnt>=0 : cnt >=FindRecorder[CFind_cnt]-20;
assign indownrange[2] = ReturnRecorder[CReturn_cnt]<25? cnt>=0  : cnt >=ReturnRecorder[CReturn_cnt] -20;
assign indownrange[3] = StopRecorder[CStop_cnt]<25? cnt>=0  : cnt >=StopRecorder[CStop_cnt] -20;
endmodule
