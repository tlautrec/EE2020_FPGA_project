`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.10.2015 02:47:37
// Design Name: 
// Module Name: test_fsm
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


module test_fsm(

    );
    
    reg clk;
    reg lb;
    reg rb;
    reg mode;
    
    wire [1:0] ctrl;
    
    FSM_inc_dec dut(clk, lb, rb, mode, ctrl);
    
    always
            begin
                clk = 1 ; #5 ; // CLK is then inv(2 * 5 * 1ns) = 100MHz
                clk = 0 ; #5 ;        
            end
            
    initial 
       begin
        mode = 0;
        rb = 0; lb = 0; #100;
        rb = 0; lb = 1;#100 ; // wait for 10 clock cycles
        rb = 0; lb = 0;#100 ; 
        rb = 1; lb = 0 ; #100 ;
        rb = 0; lb = 0; #100;
        
        mode = 1;
        rb = 0; lb = 0; #100;
                rb = 0; lb = 1;#100 ; // wait for 10 clock cycles
                rb = 0; lb = 0;#100 ; 
                rb = 1; lb = 0 ; #100 ;
                rb = 0; lb = 0; #100; 
        $finish ;
         // now let it run to debounce the input
        end    
    
endmodule
