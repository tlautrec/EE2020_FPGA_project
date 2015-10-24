`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: NUS ECE
// Engineer: Shahzor Ahmad
// 
// Create Date: 24.09.2015 21:24:46
// Design Name: 
// Module Name: switch_debouncer
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


module switch_debouncer(
    
    input CLK,
    input BTN_IN,    // input button status
    
    output BTN_DB    // debounced button status
    
    );

    reg [23:0] counter;
    reg stable;
    
    always @ (posedge CLK) begin
        if (BTN_IN) begin
            counter <= counter + 1;
        end
        else
            counter <= 0; 
    end
    
    always @ (posedge CLK) begin
        if (counter == 6'hffffff)
            stable <= 1;
        else if (~BTN_IN)
            stable <= 0;
    end
    
    assign BTN_DB  = stable ? 1 : 0;
    
    // TODO: implement debounce here (a potential extension feature for your scope)
     

    
endmodule














