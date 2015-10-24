`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.10.2015 16:57:15
// Design Name: 
// Module Name: Display_conv
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


module Display_conv(
    //input clk,
    input [4:0] digit,
    input [11:0] hc,
    input [11:0] vc,
    input [11:0] hs,
    input [11:0] vs,
    
    output reg label
    );
    
    //reg label;
    
    always @ (digit) begin
        case (digit)
            5'd0 : label = (((vc == (vs+2) || vc == (vs+11)) && ( hc > (hs) && hc < (hs+6))) ||
                                ((vc == (vs+3) || vc == (vs+4) || vc == (vs+9) || vc == (vs+10)) 
                                && (hc == hs || hc == (hs+1) || hc == (hs+5) || hc == (hs+6))) ||
                            ((vc == (vs+5)) && ((hc == hs || hc == (hs+1)) || (hc > (hs+3) && hc < (hs+7)))) ||
                            ((vc == (vs+6)) && ((hc == hs || hc == (hs+1)) || (hc > (hs+2) && hc < (hs+7)))) ||
                            ((vc == (vs+7)) && ((hc == (hs+5) || hc == (hs+6)) || (hc > (hs-1) && hc < (hs+4)))) ||
                            ((vc == (vs+8)) && ((hc == (hs+5) || hc == (hs+6)) || (hc > (hs-1) && hc < (hs+3))))
                            );
                            
            5'd1 : label = (((vc == (vs+2) || ((vc > (vs+4)) && (vc < (vs+11)))) && (hc == (hs+3) || hc == (hs+4))) ||
                            ((vc == (vs+3)) && (hc > (hs+1) && hc < (hs+5))) ||
                            ((vc == (vs+4)) && (hc > hs+1 && hc < (hs+5))) ||
                            ((vc == (vs+11)) && (hc > hs && hc < (hs+7)))
                            );
                            
            5'd2 : label = (((vc == (vs+2)) && ( hc > hs && hc < (hs+6))) ||
                            ((vc == (vs+3) || vc == (vs+10)) && ( hc == hs || hc == (hs+1)|| hc == (hs+5) || hc == (hs+6))) ||
                            ((vc == (vs+4)) && ( hc == (hs+5) || hc == (hs+6))) ||
                            ((vc == (vs+5)) && ( hc == (hs+4) || hc == (hs+5))) ||
                            ((vc == (vs+6)) && ( hc == (hs+3) || hc == (hs+4))) ||
                            ((vc == (vs+7)) && ( hc == (hs+2) || hc == (hs+3))) ||
                            ((vc == (vs+8)) && ( hc == (hs+1) || hc == (hs+2))) ||
                            ((vc == (vs+9)) && ( hc == hs || hc == (hs+1))) ||
                            ((vc == (vs+11)) && ( hc > (hs-1) && hc < (hs+7)))
                            );
            
            5'd3 : label = (((vc == (vs+2) || vc == (vs+11)) && ( hc > hs && hc < (hs+6))) ||
                            ((vc == (vs+3) || vc == (vs+10)) && ( hc == hs || hc == (hs+1)|| hc == (hs+5) || hc == (hs+6))) ||
                            ((vc == (vs+4) || vc == (vs+5) || (vc > (vs+6) && vc < (vs+10))) && ( hc == (hs+5) || hc == (hs+6))) ||
                            ((vc == (vs+6)) && ( hc > (hs+1) && hc < (hs+6)))
                            );
            
            5'd4 : label = (((vc == (vs+2) || ((vc > (vs+7)) && (vc < (vs+11)))) && ( hc == (hs+4) || hc == (hs+5))) ||
                            ((vc == (vs+3)) && (hc > (hs+2) && hc < (hs+6))) ||
                            ((vc == (vs+4)) && (hc > (hs+1) && hc < (hs+6))) ||
                            ((vc == (vs+5)) && (hc == (hs+1) || hc == (hs+2) || hc == (hs+4) || hc == (hs+5))) ||
                            ((vc == (vs+6)) && (hc == hs || hc == (hs+1) || hc == (hs+4) || hc == (hs+5))) ||
                            ((vc == (vs+7)) && (hc > (hs-1) && hc < (hs+7))) ||
                            ((vc == (vs+11)) && (hc > (hs+2) && hc < (hs+7)))
                            );
        
            5'd5 : label = (((vc == (vs+2)) && (hc > (hs-1) && hc < (hs+7))) ||
                            ((vc > (vs+2) && vc < (vs+6)) && ( hc == hs || hc == (hs+1))) ||
                            ((vc == (vs+6)) && (hc > (hs-1) && hc < (hs+6))) ||
                            ((vc > (vs+6) && vc < (vs+10)) && ( hc == (hs+5) || hc == (hs+6))) ||
                            ((vc == (vs+10)) && (hc == hs || hc == (hs+1) || hc == (hs+5) || hc == (hs+6))) ||
                            ((vc == (vs+11)) && (hc > hs && hc < (hs+6)))
                            );
        
            5'd6 : label = (((vc == (vs+2)) && (hc > (hs+1) && hc < (hs+5))) ||
                            ((vc == (vs+3)) && (hc == (hs+1) || hc == (hs+2))) ||
                            ((vc == (vs+4) || vc == (vs+5)) && (hc == hs || hc == (hs+1))) ||
                            ((vc == (vs+6)) && (hc > (hs-1) && hc < (hs+6))) ||
                            ((vc > (vs+6) && vc < (vs+11)) && ( hc == hs || hc == (hs+1) || hc == (hs+5) || hc == (hs+6))) ||
                            ((vc == (vs+11)) && (hc > hs && hc < (hs+6)))
                            );
        
            5'd7 : label = (((vc == (vs+2)) && (hc > (hs-1) && hc < (hs+7))) ||
                            ((vc == (vs+3)) && (hc == hs || hc == (hs+1)|| hc == (hs+5) || hc == (hs+6))) ||
                            ((vc == (vs+4) || vc == (vs+5)) && (hc == (hs+5) || hc == (hs+6))) ||
                            ((vc == (vs+6)) && (hc == (hs+4) || hc == (hs+5))) ||
                            ((vc == (vs+7)) && (hc == (hs+3) || hc == (hs+4))) ||
                            ((vc > (vs+7) && vc < (vs+12)) && (hc == (hs+2) || hc == (hs+3)))
                            );
        
            5'd8 : label = (((vc == (vs+2) || vc == (vs+6) || vc == (vs+11)) && (hc > hs && hc < (hs+6))) ||
                            (((vc > (vs+2) && vc < (vs+6)) || (vc > (vs+6) && vc < (vs+11))) 
                                && (hc == hs || hc == (hs+1) || hc == (hs+5) || hc == (hs+6)))
                            );
            
            5'd9 : label = (((vc == (vs+2)) && (hc > hs && hc < (hs+6))) ||
                            ((vc > (vs+2) && vc < (vs+6)) && ( hc == hs || hc == (hs+1) || hc == (hs+5) || hc == (hs+6))) ||
                            ((vc == (vs+6)) && (hc > hs && hc < (hs+7))) ||
                            ((vc > (vs+6) && vc < (vs+10)) && (hc == (hs+5) || hc == (hs+6))) ||
                            ((vc == (vs+10)) && (hc == (hs+4) || hc == (hs+5))) ||
                            ((vc == (vs+11)) && (hc > hs && hc < (hs+5)))
                            );
            5'd10 : label = (((vc == (vs+5) || vc == (vs+8)) && (hc > hs && hc < (hs+7)))
                          ); // =
                            
            5'd11 : label = (((vc == (vs+10) || vc ==(vs+11)) && (hc == (hs+3) || hc == (hs+4)))
                             );//dot
            
            5'd12 : label = (((vc == (vs+5)) && ((hc == (hs+5) || hc == (hs+6)) || (hc > (hs-1) && hc < (hs+3)))) ||
                             ((vc == (vs+6)) && (hc > (hs-1) && hc < (hs+8))) ||
                             ((vc > (vs+6) && vc < (vs+12)) && (hc == hs || hc == (hs+1) || hc == (hs+3) 
                                || hc == (hs+5) || hc == (hs+6)))    
                            );//milli's small m 
            5'd14 : label = (((vc > (vs+1) && vc < (vs+9)) && ( hc == hs || hc == (hs+1) || hc == (hs+6) || hc == (hs+7))) ||
                          ((vc == (vs+9)) && ( hc == (hs+1) || hc == (hs+2) || hc == (hs+5) || hc == (hs+6))) || 
                          ((vc == (vs+10)) && (hc > (hs+1) && hc < (hs+6))) ||
                          ((vc == (vs+11)) && (hc == (hs+3) || hc == (hs+4)))
                            ); // Volts

            5'd15 : label = (((vc == (vs+2)) && (hc == (hs+3))) ||
                          ((vc == (vs+3) || vc ==(vs+4) || (vc > (vs+5) && vc < (vs+10))) 
                            && (hc == (hs+2) || hc == (hs+3))) ||
                           ((vc == (vs+5)) && (hc > (hs-1) && hc < (hs+6))) ||
                           ((vc == (vs+10)) && (hc == (hs+2) || hc == (hs+3) || hc == (hs+5)|| hc == (hs+6))) ||
                           ((vc == (vs+11)) && (hc > (hs+2) && hc < (hs+6)))
                            ); // t
            5'd16 : label = (((vc == (vs+5) || vc == (vs+11)) && (hc > hs && hc < (hs+6))) ||
                          ((vc == (vs+6) || vc == (vs+10)) 
                            && (hc == hs || hc == (hs+1) || hc == (hs+5)|| hc == (hs+6))) ||
                          ((vc == (vs+7)) && (hc == (hs+1) || hc == (hs+2))) ||
                          ((vc == (vs+8)) && (hc > (hs+1) && hc < (hs+5))) ||
                          ((vc == (vs+9)) && (hc == (hs+4) || hc == (hs+5)))
                           );// s   
        endcase
    end  
    
    
    
    
endmodule
