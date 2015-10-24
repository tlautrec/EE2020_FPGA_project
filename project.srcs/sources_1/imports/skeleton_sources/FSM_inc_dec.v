`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: NUS ECE
// Engineer: Shahzor Ahmad
// 
// Create Date: 02.10.2015 14:41:24
// Design Name: 
// Module Name: FSM_inc_dec
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module FSM_inc_dec(
    
    input CLK_MAIN,

    input inc,                  // debounced inputs
    input dec,
    input mode,

    output reg [1:0] ctrl            
        // FSM outputs a 2-bit control signal
        //      00 -- do nothing
        //      01 -- increment CLK_SUBSAMPLE_ID
        //      10 -- decrement CLK_SUBSAMPLE_ID

    );
    
    reg[1:0] state = 0; 
    reg[1:0] nextstate;
//    reg[1:0] nextctrl = 0;
//    reg[1:0] count;
    
    parameter S0 = 2'b00;
    parameter S1 = 2'b01;
    parameter S2 = 2'b10;
    
    always @ (*) begin
            case(state)
                S0: 
                    if (inc)
                        nextstate = dec ? S0 : S1;
                    else 
                        nextstate = dec ? S2 : S0;
                S1: 
                    if (inc && ~dec)
                        nextstate =  S1;
                     else
                        nextstate = S0;
                S2: 
                    if (dec && ~inc)
                        nextstate =  S2;
                    else
                        nextstate = S0;
            endcase
    end
    
    always @ (posedge CLK_MAIN) begin
        state <= nextstate;
        if (mode)
            if (nextstate == S0)
                ctrl <= nextstate;
            else 
                ctrl <= state ^ nextstate;
        else
            ctrl <= nextstate;
    end
    
    
    
      
endmodule





