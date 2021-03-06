`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: NUS ECE
// Engineer: Shahzor Ahmad
// 
// Create Date: 02.10.2015 14:31:19
// Design Name: 
// Module Name: SCOPE_TOP
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


module SCOPE_TOP(

    input CLK,                  // main system clock, 100MHz
        
    input btnL,                 // pushbuttons
    input btnR,
    input btnU,
    input btnD,    
    
    input TRIGGER,              // trigger toggle
    input TRIGGER_TYPE,         // switches between square or non square waves
    input SINGLE_ADJUST,        // adjust between singlepulse or hold output for fsm
    input CURSOR_SELECT,        // select which cursor to move
    input CURSOR_1,             // toggle view/hide yellow cursor
    input CURSOR_2,             // toggle view/hide green cursor
    
    input ADC_IN_P,             // differential +ve & -ve analog inputs to ADC
    input ADC_IN_N,  
        
    output reg[3:0] VGA_RED,    // RGB outputs to VGA connector (4 bits per channel gives 4096 possible colors)
    output reg[3:0] VGA_GREEN,
    output reg[3:0] VGA_BLUE,
    output reg VGA_VS,          // horizontal & vertical sync outputs to VGA connector
    output reg VGA_HS,
    
    output [11:0] led           // debug LEDs    
    
    );   
         
    //-------------------------------------------------------------------------
    
    wire CLK_MAIN = CLK ;   // this is just a renaming (simply a short-circuit, or two names for the same trace/route)           
       
        
    //-------------------------------------------------------------------------
    
    //         INSTANTITATE EXTERNAL MODULES FOR VGA CONTROL
    
    // Note the VGA controller is configured to produce a 1024 x 1280 pixel resolution
    //-------------------------------------------------------------------------
    
    // PIXEL CLOCK GENERATOR 
    wire CLK_VGA ;          // pixel/VGA clock is generated by MMCM/PLL via external VHDL code (108MHz)    
    clk_wiz_0 PIXEL_CLOCK_GENERATOR( 
            CLK_MAIN,   // 100 MHz
            CLK_VGA     // 108 MHz
        ) ;     
    
    
    // VGA SIGNALS (as output by VGA controller (vga_ctrl.vhd))
    wire VGA_horzSync ;
    wire VGA_vertSync ;
    wire VGA_active ;
    wire[11:0] VGA_horzCoord ;
    wire[11:0] VGA_vertCoord ;
        // it is not required but good practice to declare single-bit wires
        // it is required to declare multi-bit wires (bus) before use    
    
    // VGA CONTROLLER    
    vga_ctrl VGA_CONTROLLER(
            CLK_VGA,
            VGA_horzSync,
            VGA_vertSync,
            VGA_active,  
            VGA_horzCoord,  
            VGA_vertCoord  
        ) ; 
        // - VGA_horzCoord changes at a rate of 108 MHz (CLK_VGA) to traverse each pixel in a row, while VGA_vertCoord changes at a rate of ~63.98 KHz to 
        // scan each row one by one and back to the top. These tech details are handled by vga_ctrl.vhd. One only needs to make use of these coordinates 
        // to output whatever they want at desired pixel locations. 
        // 
        // - VGA_active is a binary indicator specifying when VGA_horzCoord, VGA_vertCoord are valid (i.e., with the 1024 x 1280 pixel screen). For technical 
        // reasons the said coordinates do go outside this screen area for a short while and no VGA signal should be output during this time (it will and does
        // mess up the display). 
        //
        // - hence, VGA_active, VGA_horzCoord and VGA_vertCoord may be used in conjunction with each other to generate VGA_RED, VGA_GREEN, VGA_BLUE. The Sync
        // signals should be output to the VGA port as well, and are responsible to generate the raster scan on the screen       


    //-------------------------------------------------------------------------
                                    
    //                      SAMPLING VIA ADC 
    
    // On-chip ADC is clocked at [ inv(inv(CLK_ADC/4)*26) = 961.538 KHZ ], 
    // where CLK_ADC is the clock passed to ADC (in this case CLK_ADC = CLK_MAIN = 100MHz)
    
    // The on-chip ADC is 12-bit. We employ the most significant 8 bits to keep things simple
    
    //-------------------------------------------------------------------------
    
//    wire [7:0] ADC_SAMPLE ; // the latest value as sampled via ADC
//    ADC_sampler SAMPLER( CLK_MAIN, ADC_IN_P, ADC_IN_N, ADC_SAMPLE ) ; // sampling at 961.538 KHZ
        // Either lines # 104-105 OR lines # 129-136 should be used at a time

    assign led[7:0] = ADC_SAMPLE ; 
        // the sampled 8-bit value reflects on 8 LEDs. Every time ADC_SAMPLE changes 
        // (and that happens at 961.538KHz!), this assignment is triggered again 
      
    
    //-------------------------------------------------------------------------
                                        
    //                  SIMULATE SAMPLING VIA ADC 
    
    // In the absence of a signal generator (e.g., when working at home), you may use 
    // the following code instead of the above, i.e., COMMENT out lines # 104-105, 
    // UN-COMMENT lines # 129-136
    
    // A square wave at 1Hz is generated via a clock-divider module, and serves as our 
    // 'analog' signal to be sampled.
    //-------------------------------------------------------------------------
    
    wire CLK_SYNTH_SQUARE ; 
    clock_divider GEN_CLK_SYNTH_SQUARE( CLK_MAIN, 1'b0, 28'H2FAF080, CLK_SYNTH_SQUARE ) ; 
        // Synthesize a 1Hz waveform given 100MHz clock          

    reg [7:0] ADC_SAMPLE ; // the latest value as sampled via ADC
    always@(posedge CLK_MAIN) // sample the synthesized waveform at 100 MHz
        begin
            if( CLK_SYNTH_SQUARE )
                ADC_SAMPLE <= 255 ;
            else
                ADC_SAMPLE <= 0 ;        
        end   
        

     // this LED blinks at 1 Hz (just for visualization)
     reg LED_DEBUG = 0 ;
        // signals on LHS of assignments in 'always' blocks must be declared as reg before use
     always@(posedge CLK_SYNTH_SQUARE)
        begin
            LED_DEBUG <= !LED_DEBUG ;
        end
     assign led[8] = LED_DEBUG ; 
        
               
    //-------------------------------------------------------------------------
                                    
    //        SELECTING SAMPLING FREQUENCY (ESSENTIALLY, TIME/DIV)
    
    // this configures the CLK_SUBSAMPLE (fs)
    
    // NOTE: currently CLK_SUBSAMPLE_ID has been hard-coded to 0, and no provision
    // is made to modify it at FPGA run-time
    //-------------------------------------------------------------------------
    
    // default sampling at 100Hz
    reg [2:0] CLK_SUBSAMPLE_ID = 0; 
        
    reg [27:0] LOAD_VALUE_SUBSAMPLE ;
        // we generate CLK_SUBSAMPLE from CLK_MAIN 
    
    always@(posedge CLK_MAIN)
        case(CLK_SUBSAMPLE_ID)
            0:  LOAD_VALUE_SUBSAMPLE <= 28'd500000 ;    // CLK_SUBSAMPLE = 100 Hz => TIME/DIV = 0.8 sec/div
            1:  LOAD_VALUE_SUBSAMPLE <= 28'd125000 ;    // CLK_SUBSAMPLE = 400 Hz => TIME/DIV = 0.2 sec/div 
            2:  LOAD_VALUE_SUBSAMPLE <= 28'd62500 ;     // CLK_SUBSAMPLE = 800 Hz => TIME/DIV = 0.1 sec/div
            3:  LOAD_VALUE_SUBSAMPLE <= 28'd50000 ;     // CLK_SUBSAMPLE = 1 KHz => TIME/DIV = 
            4:  LOAD_VALUE_SUBSAMPLE <= 28'd31250 ;     // CLK_SUBSAMPLE = 1600 Hz => TIME/DIV = 50 ms/div 
            5:  LOAD_VALUE_SUBSAMPLE <= 28'd6250 ;      // CLK_SUBSAMPLE = 8 KHz => TIME/DIV = 10 ms/div 
            6:  LOAD_VALUE_SUBSAMPLE <= 28'd625 ;       // CLK_SUBSAMPLE = 80 KHz => TIME/DIV = 1 ms/div      
            7:  LOAD_VALUE_SUBSAMPLE <= 28'd62 ;        // CLK_SUBSAMPLE = 806.451 KHz => TIME/DIV = 0.0992 ms/div 
        endcase
            // Each LOAD_VALUE_SUBSAMPLE defines the stated CLK_SUBSAMPLE (sampling frequency fs). 
            // The TIME/DIV values, however, assume the 1280 horizontal pixels on the screen are divided into 16 equal DIVISIONS of 80 px each 
                      
    
    wire CLK_SUBSAMPLE ;    // sub-sampling rate for ADC output samples
                            // It essentially defines time/div 
                            
                            // Use CLK_SUBSAMPLE to clock your bank of shift registers below
                            // Use CLK_SUBSAMPLE to clock your trigger process if you implement one   
                            
                            // For all practical purposes, this can be taken to be our fs (sampling frequency) as described in the manual
                            // We could have modified ADC sampling frequency, but give the long formula to dervie it from CLK_MAIN (see line 96),
                            // we're better off sub-sampling to achieve flexible sampling frequencies and corresponding time/div configurations
                                                        
                                                     
    clock_divider GEN_CLK_SUBSAMPLE( CLK_MAIN, 1'b0, LOAD_VALUE_SUBSAMPLE, CLK_SUBSAMPLE ) ;
    clock_divider GEN_CLK_SUBSAMPLE1( CLK_MAIN, 1'b0, 28'd2500000, CLK_SCROLL ) ;
    
        // note as many times you instantiate a module in HDL, that many times it will replicate the actual hardware on the FPGA 
        // so there are two physical clock_divider circuits in our design    
    
    // debouncing all day err' day
    switch_debouncer BTNL_DEBOUNCER( CLK_MAIN, btnL, btnL_DB ) ;
    switch_debouncer BTNR_DEBOUNCER( CLK_MAIN, btnR, btnR_DB ) ;
    switch_debouncer BTNU_DEBOUNCER( CLK_MAIN, btnU, btnU_DB ) ;
    switch_debouncer BTND_DEBOUNCER( CLK_MAIN, btnD, btnD_DB ) ;   
    
    switch_debouncer TRIG_DEBOUNCER( CLK_MAIN, TRIGGER, TRIGGER_DB ) ;
    switch_debouncer TRIG_TYPE_DEBOUNCER (CLK_MAIN, TRIGGER_TYPE, TRIGGER_TYPE_DB);    
    switch_debouncer CURSOR (CLK_MAIN, CURSOR_SELECT, CURSOR_SELECT_DB);
    
    switch_debouncer ADJUST_DEBOUNCER( CLK_MAIN, SINGLE_ADJUST, SINGLE_ADJUST_DB ) ;    
    switch_debouncer CURSOR1 (CLK_MAIN, CURSOR_1, CURSOR_1_DB);
    switch_debouncer CURSOR2 (CLK_MAIN, CURSOR_2, CURSOR_2_DB);
        // you may implement debounce in switch_debouncer.vhd as an extension feature
    
    
    wire [1:0] ctrl;
    wire [1:0] ctrl2; 
    reg [1:0] VOLT_FACTOR = 0;
    reg [11:0] SHIFT_VER_REG_YELLOW = 511;
    reg [11:0] SHIFT_HOR_REG_YELLOW = 639;    
    reg [11:0] SHIFT_VER_REG_GREEN = 511;
    reg [11:0] SHIFT_HOR_REG_GREEN = 639;
    
        
    FSM_inc_dec FSM1( CLK_MAIN, btnL_DB, btnR_DB, SINGLE_ADJUST_DB , ctrl ) ;  // use if you've implemented debounce, and now would also like to implement FSM
    FSM_inc_dec FSM2( CLK_MAIN, btnU_DB, btnD_DB, SINGLE_ADJUST_DB, ctrl2 ) ;
        // you may implement a FSM in FSM_inc_dec.vhd as an extension feature
        // This FSM should output a 2-bit control signal
        //      00 -- do nothing
        //      01 -- increment CLK_SUBSAMPLE_ID
        //      10 -- decrement CLK_SUBSAMPLE_ID

    // this process increments / decrements CLK_SUBSAMPLE_ID depending on ctrl
    // increments other things too... mhmm        
    always@(posedge CLK_MAIN) begin
        if (SINGLE_ADJUST_DB)
            if( ctrl == 2'b01 && CLK_SUBSAMPLE_ID < 7 )
                CLK_SUBSAMPLE_ID <= CLK_SUBSAMPLE_ID + 1 ;
            else if (ctrl == 2'b10 && CLK_SUBSAMPLE_ID > 0)
                CLK_SUBSAMPLE_ID <= CLK_SUBSAMPLE_ID - 1 ;
    end
    always@(posedge CLK_SCROLL) begin
        if (~SINGLE_ADJUST_DB)
            if (ctrl == 2'b10 && CURSOR_SELECT_DB && SHIFT_HOR_REG_YELLOW < 1279)
                SHIFT_HOR_REG_YELLOW <= SHIFT_HOR_REG_YELLOW + 1'b1 ;
            else if (ctrl == 2'b01 && CURSOR_SELECT_DB && SHIFT_HOR_REG_YELLOW > 0)
                SHIFT_HOR_REG_YELLOW <= SHIFT_HOR_REG_YELLOW - 1'b1 ;
            else if (ctrl == 2'b10 && ~CURSOR_SELECT_DB && SHIFT_HOR_REG_GREEN < 1279)
                SHIFT_HOR_REG_GREEN <= SHIFT_HOR_REG_GREEN + 1'b1 ;
            else if (ctrl == 2'b01 && ~CURSOR_SELECT_DB && SHIFT_HOR_REG_GREEN > 0)
                SHIFT_HOR_REG_GREEN <= SHIFT_HOR_REG_GREEN - 1'b1 ;
    end

    always@(posedge CLK_MAIN) begin
        if (SINGLE_ADJUST_DB)
            if (ctrl2 == 2'b10 && VOLT_FACTOR < 3)
                VOLT_FACTOR <= VOLT_FACTOR + 1 ;
            else if (ctrl2 == 2'b01 && VOLT_FACTOR > 0)
                VOLT_FACTOR <= VOLT_FACTOR - 1 ;
    end    

    always@(posedge CLK_SCROLL) begin
        if (~SINGLE_ADJUST_DB)
            if (ctrl2 == 2'b10 && CURSOR_SELECT_DB && SHIFT_VER_REG_YELLOW < 1023)
                SHIFT_VER_REG_YELLOW <= SHIFT_VER_REG_YELLOW + 1'b1 ;
            else if (ctrl2 == 2'b01 && CURSOR_SELECT_DB && SHIFT_VER_REG_YELLOW > 0)
                SHIFT_VER_REG_YELLOW <= SHIFT_VER_REG_YELLOW - 1'b1 ;
            else if (ctrl2 == 2'b10 && ~CURSOR_SELECT_DB && SHIFT_VER_REG_GREEN < 1023)
                SHIFT_VER_REG_GREEN <= SHIFT_VER_REG_GREEN + 1'b1 ;
            else if (ctrl2 == 2'b01 && ~CURSOR_SELECT_DB && SHIFT_VER_REG_GREEN > 0)
                SHIFT_VER_REG_GREEN <= SHIFT_VER_REG_GREEN - 1'b1 ;
    end        
 
    assign led[11:9] = CLK_SUBSAMPLE_ID ;  
        // leds[11:9] provide a visual indication of CLK_SUBSAMPLE_ID at all times    
  
    
    //-------------------------------------------------------------------------
                                    
    //               UPDATE DISPLAY_MEM @ CLK_SUBSAMPLE
    
    // DISPLAY_MEM is a bank of 1280 shift registers
    //
    // shift all samples one position to the left in memory, and  
    // store the latest ADC sample in the right/left most position    
    //-------------------------------------------------------------------------

    reg [7:0] DISPLAY_MEM[0:1279]; 
        // display memory - store samples here and output them on screen
        
    // TOOD:    implement Verilog here that treats DISPLAY_MEM as a bank of 
    //          1280 shift registers, each 8-bit wide. The latest sample should 
    //          be stored in the right (or left)-most register, while contents of
    //          all the other registers should be shifted to the neighboring register
    //          on the right (respectively, left). 
    //          
    //          This process of bringing in a new sample from the right/left while 
    //          shifting all the other samples should be done in a single clock cycle 
    //          (use CLK_SUBSAMPLE)

    integer i;
    integer j;
    reg [7:0] TEMP[0:1279];
    
    always @ (posedge CLK_SUBSAMPLE) begin
        for( i = 0; i<1279 ; i = i+1 ) begin
            TEMP[i+1] <= TEMP[i];
        end
        TEMP[0] <= ADC_SAMPLE;
    end
    
    always @ (posedge CLK_SUBSAMPLE) begin
        if ((ADC_SAMPLE >= 20 && ADC_SAMPLE > TEMP[1] && TRIGGER_DB && TRIGGER_TYPE_DB) ||
        (ADC_SAMPLE == 20 && ADC_SAMPLE > TEMP[1] && TRIGGER_DB && ~TRIGGER_TYPE_DB) || ~TRIGGER_DB ) begin
        
            for( j = 0; j<1280 ; j = j+1 ) begin
                DISPLAY_MEM[j] <= TEMP[j];
            end
        end
    end    
        
    
    //-------------------------------------------------------------------------
                
    //                  DRAWING WAVEFORM ON SCREEN
    
    // waveform is drawn using its samples from display memory
    //-------------------------------------------------------------------------       
   
           
    wire[3:0] VGA_RED_WAVEFORM = 
                ((VGA_horzCoord < 1280) & 
                (VGA_vertCoord == ((511 + ((VOLT_FACTOR+1) *128)) - (VOLT_FACTOR+1)*(DISPLAY_MEM[VGA_horzCoord])))) 
                    ? 4'hF : 0 ;
            
                  
        
    //-------------------------------------------------------------------------
        
    //                  DRAWING GRID LINES ON SCREEN
    
    // Grid lines are drawn at pixels # 320, 640, 960 along the x-axis, and
    // pixels # 256, 512, 768 along the y-axis
    
    // Note the VGA controller is configured to produce a 1024 x 1280 pixel resolution
    //-------------------------------------------------------------------------
            

     
    wire CONDITION_FOR_GRID = (VGA_horzCoord%80 == 79) || (VGA_vertCoord%64 == 63) || 
                              (VGA_horzCoord > 635 && VGA_horzCoord < 643 && VGA_vertCoord%8 == 7) ||
                              (VGA_vertCoord > 507 && VGA_vertCoord < 515 && VGA_horzCoord%16 == 15);
                              
    wire label_t = ((VGA_vertCoord == (16+2) && VGA_horzCoord == (1128+3)) ||
                    (VGA_vertCoord == (16+3) && (VGA_horzCoord > (1127+2) && VGA_horzCoord < (1129+3))) ||
                    (VGA_vertCoord == (16+4) && (VGA_horzCoord > (1127+2) && VGA_horzCoord < (1129+3))) ||
                    (VGA_vertCoord == (16+5) && (VGA_horzCoord > (1127) && VGA_horzCoord < (1129+5))) ||
                    (VGA_vertCoord == (16+6) && (VGA_horzCoord > (1127+2) && VGA_horzCoord < (1129+3))) ||
                    (VGA_vertCoord == (16+7) && (VGA_horzCoord > (1127+2) && VGA_horzCoord < (1129+3))) ||
                    (VGA_vertCoord == (16+8) && (VGA_horzCoord > (1127+2) && VGA_horzCoord < (1129+3))) ||
                    (VGA_vertCoord == (16+9) && (VGA_horzCoord > (1127+2) && VGA_horzCoord < (1129+3))) ||
                    (VGA_vertCoord == (16+10) && ((VGA_horzCoord > (1127+2) && VGA_horzCoord < (1129+3))
                        || (VGA_horzCoord >(1127+5) && VGA_horzCoord < (1129+6)))) ||
                   (VGA_vertCoord == (16+11) && (VGA_horzCoord > (1127+3) && VGA_horzCoord < (1129+5)))  
                    );
    
    wire label_divt = (((VGA_vertCoord == (16+4) || VGA_vertCoord == (32+4)) && VGA_horzCoord == (1136+6)) || //slash letter
                       ((VGA_vertCoord == (16+5) || VGA_vertCoord == (32+5)) &&  (VGA_horzCoord == (1136+5) || VGA_horzCoord == (1136+6))) ||
                       ((VGA_vertCoord == (16+6) || VGA_vertCoord == (32+6)) &&  (VGA_horzCoord == (1136+4) || VGA_horzCoord == (1136+5))) ||
                       ((VGA_vertCoord == (16+7) || VGA_vertCoord == (32+7)) &&  (VGA_horzCoord == (1136+3) || VGA_horzCoord == (1136+4))) ||
                       ((VGA_vertCoord == (16+8) || VGA_vertCoord == (32+8)) &&  (VGA_horzCoord == (1136+2) || VGA_horzCoord == (1136+3))) ||
                       ((VGA_vertCoord == (16+9) || VGA_vertCoord == (32+9)) &&  (VGA_horzCoord == (1136+1) || VGA_horzCoord == (1136+2))) ||
                       ((VGA_vertCoord == (16+10)|| VGA_vertCoord == (32+10)) &&  (VGA_horzCoord == (1136) || VGA_horzCoord == (1136+1))) ||
                       ((VGA_vertCoord == (16+11) || VGA_vertCoord == (32+11)) &&  VGA_horzCoord == (1136)) || 
                       // letter D
                       ((VGA_vertCoord == (16+2) || VGA_vertCoord == (16+11) || VGA_vertCoord == (32+2)|| VGA_vertCoord == (32+11)) 
                            && (VGA_horzCoord > (1143+0) && VGA_horzCoord < (1145+4))) ||
                       ((VGA_vertCoord == (16+3) || VGA_vertCoord == (16+10) || VGA_vertCoord == (32+3) || VGA_vertCoord == (32+10)) 
                            && ((VGA_horzCoord > (1143+1) && VGA_horzCoord < (1145+2)) || (VGA_horzCoord > (1143+4) && VGA_horzCoord < (1145+5)))) || 
                       (((VGA_vertCoord > (15+4) && VGA_vertCoord < (17+9)) || (VGA_vertCoord > (31+4) && VGA_vertCoord < (33+9))) 
                            && ((VGA_horzCoord > (1143+1) && VGA_horzCoord < (1145+2)) || (VGA_horzCoord > (1143+5) && VGA_horzCoord < (1145+6)))) ||
                        // letter I
                        ((VGA_vertCoord == (16+2) || VGA_vertCoord == (16+11) || VGA_vertCoord == (32+2) || VGA_vertCoord == (32+11)) 
                            && ( VGA_horzCoord > (1151+2) && VGA_horzCoord < (1153+5))) ||
                        (((VGA_vertCoord > (15+3) && VGA_vertCoord < (17+10)) || (VGA_vertCoord > (31+3) && VGA_vertCoord < (33+10)))
                            && ( VGA_horzCoord == (1152+3) || VGA_horzCoord == (1152+4))) ||
                        // letter V
                        (((VGA_vertCoord > (15+2) && VGA_vertCoord < (17+8)) || (VGA_vertCoord > (31+2) && VGA_vertCoord < (33+8)))
                            && (VGA_horzCoord == (1160) || VGA_horzCoord == (1161) 
                            || VGA_horzCoord == (1166) || VGA_horzCoord == (1167))) ||
                        ((VGA_vertCoord == (16+9) || VGA_vertCoord == (32+9)) && (VGA_horzCoord == (1161) || VGA_horzCoord == (1162) 
                            || VGA_horzCoord == (1165) || VGA_horzCoord == (1166))) ||
                        ((VGA_vertCoord == (16+10) || VGA_vertCoord == (32+10)) && (VGA_horzCoord > (1159 + 2) && VGA_horzCoord < (1161 + 5))) ||
                        ((VGA_vertCoord == (16+11) || VGA_vertCoord == (32+11)) && (VGA_horzCoord > (1159 + 3) && VGA_horzCoord < (1161 + 4))) ||
                        // letter =
                        ((VGA_vertCoord == (16+5) || VGA_vertCoord == (16+8) || VGA_vertCoord == (32+5) || VGA_vertCoord == (32+8)) 
                            && (VGA_horzCoord > (1167+1) && VGA_horzCoord < (1169+6)))
                        );
                        
    wire label_V = (((VGA_vertCoord > (31+2) && VGA_vertCoord < (33+8)) && (VGA_horzCoord == (1128) || VGA_horzCoord == (1129) 
                        || VGA_horzCoord == (1134) || VGA_horzCoord == (1135))) ||
                    ((VGA_vertCoord == (32+9)) && (VGA_horzCoord == (1129) || VGA_horzCoord == (1130) 
                        || VGA_horzCoord == (1133) || VGA_horzCoord == (1134))) ||
                    ((VGA_vertCoord == (32+10)) && (VGA_horzCoord > (1127 + 2) && VGA_horzCoord < (1129 + 5))) ||
                    ((VGA_vertCoord == (32+11)) && (VGA_horzCoord > (1127 + 3) && VGA_horzCoord < (1129 + 4))));
    
    wire label_s = (((VGA_vertCoord == (16+5) || VGA_vertCoord == (16+11)) && (VGA_horzCoord > (1207+1) && VGA_horzCoord < (1209+5))) ||     
                      ((VGA_vertCoord == (16+6) || VGA_vertCoord == (16+10)) && (VGA_horzCoord == (1208) || VGA_horzCoord == (1209)
                       || VGA_horzCoord == (1213) || VGA_horzCoord == (1214))) ||
                     ((VGA_vertCoord == (16+7)) && (VGA_horzCoord == (1209) || VGA_horzCoord == (1210))) ||
                     ((VGA_vertCoord == (16+8)) && (VGA_horzCoord > (1207+2) && VGA_horzCoord < (1209+4))) ||
                     ((VGA_vertCoord == (16+9)) && (VGA_horzCoord == (1212) || VGA_horzCoord == (1213))) 
                    );
    
    wire label_V2 = (((VGA_vertCoord > (31+2) && VGA_vertCoord < (33+8)) && (VGA_horzCoord == (1208) || VGA_horzCoord == (1209) 
                        || VGA_horzCoord == (1214) || VGA_horzCoord == (1215))) ||
                    ((VGA_vertCoord == (32+9)) && (VGA_horzCoord == (1209) || VGA_horzCoord == (1210) 
                        || VGA_horzCoord == (1213) || VGA_horzCoord == (1214))) ||
                    ((VGA_vertCoord == (32+10)) && (VGA_horzCoord > (1207 + 2) && VGA_horzCoord < (1209 + 5))) ||
                    ((VGA_vertCoord == (32+11)) && (VGA_horzCoord > (1207 + 3) && VGA_horzCoord < (1209 + 4))));
    
    reg [3:0]volt1d;
    reg [3:0]volt2d;
    reg [3:0]volt3d;                   

    reg [3:0]factor1d;
    reg [3:0]factor2d;
    reg [3:0]factor3d;
    reg [3:0]factor4d;
    
    always @ (CLK_SUBSAMPLE_ID) begin
       factor1d = (CLK_SUBSAMPLE_ID > 2 && CLK_SUBSAMPLE_ID < 7) ? 13 : 0;
    end
    
    always @ (CLK_SUBSAMPLE_ID) begin
            case (CLK_SUBSAMPLE_ID)
                0: factor2d = 11;
                1: factor2d = 11;
                2: factor2d = 11;             
                3: factor2d = 8;               
                4: factor2d = 5;
                5: factor2d = 1;
                6: factor2d = 13;
                7: factor2d = 11;
            endcase
        end
        
    always @ (CLK_SUBSAMPLE_ID) begin
            case (CLK_SUBSAMPLE_ID)
                0: factor3d = 8;
                1: factor3d = 2;
                2: factor3d = 1;               
                3: factor3d = 0;               
                4: factor3d = 0;
                5: factor3d = 0;
                6: factor3d = 1;
                7: factor3d = 1;
            endcase
        end
            
    always @ (CLK_SUBSAMPLE_ID) begin
        factor4d = (CLK_SUBSAMPLE_ID < 3)? 0 : 12;
    end

   
   always @ (VOLT_FACTOR) begin
        case (VOLT_FACTOR)
            0: volt1d = 2;
            1: volt1d = 1;
            2: volt1d = 13;
            3: volt1d = 13;
        endcase
   end
   
   always @ (VOLT_FACTOR) begin
       case (VOLT_FACTOR)
           0: volt2d = 5;
           1: volt2d = 2;
           2: volt2d = 8;
           3: volt2d = 6;
       endcase
   end
    
   always @ (VOLT_FACTOR) begin
      case (VOLT_FACTOR)
          0: volt3d = 0;
          1: volt3d = 5;
          2: volt3d = 3;
          3: volt3d = 3;
      endcase
   end
   
      
   wire label_td_1d;
   wire label_td_2d;
   wire label_td_3d;
   wire label_td_4d;
   
   wire label_vd_1d;
   wire label_vd_2d;
   wire label_vd_3d;
   wire label_vd_4d;
   
   Display_conv disp1td ( factor1d, VGA_horzCoord, VGA_vertCoord, 1176, 16 ,label_td_1d);
   Display_conv disp2td ( factor2d, VGA_horzCoord, VGA_vertCoord, 1184, 16 ,label_td_2d);
   Display_conv disp3td ( factor3d, VGA_horzCoord, VGA_vertCoord, 1192, 16 ,label_td_3d);
   Display_conv disp4td ( factor4d, VGA_horzCoord, VGA_vertCoord, 1200, 16 ,label_td_4d);
   
   Display_conv disp1vd ( volt1d, VGA_horzCoord, VGA_vertCoord, 1176, 32 ,label_vd_1d);
   Display_conv disp2vd ( volt2d, VGA_horzCoord, VGA_vertCoord, 1184, 32 ,label_vd_2d);
   Display_conv disp3vd ( volt3d, VGA_horzCoord, VGA_vertCoord, 1192, 32 ,label_vd_3d);
   Display_conv disp4vd ( 12, VGA_horzCoord, VGA_vertCoord, 1200, 32 ,label_vd_4d); 
    

    wire[27:0]t1;
    reg [27:0]tfactor;
    wire [15:0]v1;
    
    //always @ (*) begin
     assign v1 = (SHIFT_VER_REG_YELLOW > SHIFT_VER_REG_GREEN) ?  ((SHIFT_VER_REG_YELLOW - SHIFT_VER_REG_GREEN) 
            * 10000)/(((VOLT_FACTOR+1)*256)-1) : ((SHIFT_VER_REG_GREEN- SHIFT_VER_REG_YELLOW) 
                    * 10000)/(((VOLT_FACTOR+1)*256)-1);
    //end

    always @ (CLK_SUBSAMPLE_ID) begin
        case (CLK_SUBSAMPLE_ID)
            0: tfactor = 100000;
            1: tfactor = 25000;
            2: tfactor = 12500;               
            3: tfactor = 10000;               
            4: tfactor = 6250;
            5: tfactor = 1250;
            6: tfactor = 125;
            7: tfactor = 13;
        endcase 
    end

    //always @ (SHIFT_HOR_REG_YELLOW or SHIFT_HOR_REG_GREEN) begin
        assign t1 = (SHIFT_HOR_REG_YELLOW > SHIFT_HOR_REG_GREEN) ? (SHIFT_HOR_REG_YELLOW - SHIFT_HOR_REG_GREEN)*tfactor 
            : (SHIFT_HOR_REG_GREEN - SHIFT_HOR_REG_YELLOW)*tfactor;    
    //end
     
     reg [27:0] t1d1;
     reg [27:0] t1d2;
     reg [27:0] t1d3;
     reg [27:0] t1d4;
     reg [27:0] t1d5;
     reg [27:0] t1d7;
     reg [27:0] t1d8;
     reg [27:0] t1d9;
     reg [27:0] t1d10;
     
     always @ (negedge CLK_MAIN) begin
        t1d1 <= (t1 > 99999999) ? t1/100000000 : 13;
        t1d2 <= (t1 > 9999999) ? (t1/10000000)%10 : 13; 
        t1d3 <= (t1 > 999999) ? (t1/1000000)%10 : 13;
        t1d4 <= (t1 > 99999) ? (t1/100000)%10 : 13;
        t1d5 <= (t1/10000)%10;
        t1d7 <= (t1/1000)%10;
        t1d8 <= (t1/100)%10;
        t1d9 <= (t1/10)%10;
     end
    
     wire label_t1_1d;
     wire label_t1_2d;
     wire label_t1_3d;
     wire label_t1_4d;
     wire label_t1_5d;
     wire label_t1_6d;
     wire label_t1_7d;
     wire label_t1_8d;
     wire label_t1_9d;
     wire label_t1_11d;
     wire label_t1_12d;
     wire label_t1_t;
     wire label_t1_teq;
    
     Display_conv disptt1 (15, VGA_horzCoord, VGA_vertCoord, 20, 80 ,label_t1_t);
     Display_conv dispeqt1 (10, VGA_horzCoord, VGA_vertCoord, 30, 80 ,label_t1_teq);
     Display_conv disp1t1 (t1d1, VGA_horzCoord, VGA_vertCoord, 40, 80 ,label_t1_1d);
     Display_conv disp2t1 (t1d2, VGA_horzCoord, VGA_vertCoord, 50, 80 ,label_t1_2d);
     Display_conv disp3t1 (t1d3, VGA_horzCoord, VGA_vertCoord, 60, 80 ,label_t1_3d);
     Display_conv disp4t1 (t1d4, VGA_horzCoord, VGA_vertCoord, 70, 80 ,label_t1_4d);
     Display_conv disp5t1 (t1d5, VGA_horzCoord, VGA_vertCoord, 80, 80 ,label_t1_5d);
     Display_conv disp6t1 (11, VGA_horzCoord, VGA_vertCoord, 90, 80 ,label_t1_6d);
     Display_conv disp7t1 (t1d7, VGA_horzCoord, VGA_vertCoord, 100, 80 ,label_t1_7d);
     Display_conv disp8t1 (t1d8, VGA_horzCoord, VGA_vertCoord, 110, 80 ,label_t1_8d);
     Display_conv disp9t1 (t1d9, VGA_horzCoord, VGA_vertCoord, 120, 80 ,label_t1_9d);
     Display_conv disp11t1 (12, VGA_horzCoord, VGA_vertCoord, 130, 80 ,label_t1_11d);
     Display_conv disp12t1 (16, VGA_horzCoord, VGA_vertCoord, 140, 80 ,label_t1_12d); 
    
    reg [15:0] v1d1;
    reg [15:0] v1d2;
    reg [15:0] v1d3;
    reg [15:0] v1d4;
    reg [15:0] v1d6;
    
    always @ (posedge CLK_MAIN) begin
        v1d1 <= (v1 > 9999) ? v1/10000 : 13 ; 
        v1d2 <= (v1 > 999) ? (v1/1000)%10 : 13;
        v1d3 <= (v1 > 99) ? (v1/100)%10 : 13;
        v1d4 <= (v1/10)%10;
        v1d6 <= v1%10;
    end
  
    wire label_v1_1d;
    wire label_v1_2d;
    wire label_v1_3d;
    wire label_v1_4d;
    wire label_v1_5d;
    wire label_v1_6d;
    wire label_v1_7d;
    wire label_v1_8d;
    wire label_v1_v;
    wire label_v1_eq;
    
    Display_conv dispvv1 (14, VGA_horzCoord, VGA_vertCoord, 20, 96 ,label_v1_v);
    Display_conv dispeqv1 (10, VGA_horzCoord, VGA_vertCoord, 30, 96 ,label_v1_eq);
    Display_conv disp1v1 ( v1d1, VGA_horzCoord, VGA_vertCoord, 70, 96 ,label_v1_1d);
    Display_conv disp2v1 ( v1d2, VGA_horzCoord, VGA_vertCoord, 80, 96 ,label_v1_2d);
    Display_conv disp3v1 ( v1d3, VGA_horzCoord, VGA_vertCoord, 90, 96 ,label_v1_3d);
    Display_conv disp4v1 ( v1d4, VGA_horzCoord, VGA_vertCoord, 100, 96 ,label_v1_4d);
    Display_conv disp5v1 ( 11, VGA_horzCoord, VGA_vertCoord, 110, 96 ,label_v1_5d);
    Display_conv disp6v1 ( v1d6, VGA_horzCoord, VGA_vertCoord, 120, 96 ,label_v1_6d);
    Display_conv disp7v1 ( 12, VGA_horzCoord, VGA_vertCoord, 130, 96 ,label_v1_7d);
    Display_conv disp8v1 ( 14, VGA_horzCoord, VGA_vertCoord, 140, 96 ,label_v1_8d); 
    
    wire[3:0] VGA_VOLT = ((label_v1_1d || label_v1_2d || label_v1_3d || label_v1_4d
                                || label_v1_5d || label_v1_6d || label_v1_7d || label_v1_8d
                                || label_v1_v || label_v1_eq) && (CURSOR_1_DB && CURSOR_2_DB)) ? 4'hf : 0;
   
    wire[3:0] VGA_TIME = ((label_t1_1d || label_t1_2d
                            || label_t1_3d || label_t1_4d || label_t1_5d || label_t1_6d
                            || label_t1_7d || label_t1_8d || label_t1_9d
                            || label_t1_11d || label_t1_12d || label_t1_t || label_t1_teq
                            ) && (CURSOR_1_DB && CURSOR_2_DB)) ? 4'hf : 0;
        
    wire[3:0] VGA_TEXT = (label_t || label_divt || label_V || label_V2 || label_s 
        || label_td_1d || label_td_2d || label_td_3d || label_td_4d
        || label_vd_1d || label_vd_2d || label_vd_3d || label_vd_4d
        ) ? 4'hff : 0;               
    
    wire[3:0] VGA_RED_GRID = CONDITION_FOR_GRID ? 0 : 0 ;
    wire[3:0] VGA_GREEN_GRID = CONDITION_FOR_GRID ? 4'h1 : 0 ;
    wire[3:0] VGA_BLUE_GRID = CONDITION_FOR_GRID ? 4'h3 : 0 ;
        // if true, a black pixel is put at coordinates (VGA_horzCoord, VGA_vertCoord), 
        // else a cyan background is generated, characteristic of oscilloscopes! 
        
    // TOOD:    Draw grid lines at every 80-th pixel along the horizontal axis, and every 64th pixel
    //          along the vertical axis. This gives us a 16x16 grid on screen. 
    //          
    //          Further draw ticks on the central x and y grid lines spaced 16 and 8 pixels apart in the 
    //          horizontal and vertical directions respectively. This gives us 5 sub-divisions per division 
    //          in the horizontal and 8 sub-divisions per divsion in the vertical direction   
    
    wire CONDITION_FOR_HORZ_CURSOR = (VGA_vertCoord == SHIFT_VER_REG_YELLOW && CURSOR_1_DB);
    wire CONDITION_FOR_VERT_CURSOR = (VGA_horzCoord == SHIFT_HOR_REG_YELLOW && CURSOR_1_DB);
    
    wire CONDITION_FOR_HORZ_CURSOR_2 = (VGA_vertCoord == SHIFT_VER_REG_GREEN && CURSOR_2_DB);
    wire CONDITION_FOR_VERT_CURSOR_2 = (VGA_horzCoord == SHIFT_HOR_REG_GREEN && CURSOR_2_DB);
    
    wire[3:0] VGA_CURSOR_YELLOW = (CONDITION_FOR_HORZ_CURSOR || CONDITION_FOR_VERT_CURSOR) ? 4'hf :0;
    wire[3:0] VGA_CURSOR_GREEN = (CONDITION_FOR_HORZ_CURSOR_2 || CONDITION_FOR_VERT_CURSOR_2) ? 4'hF :0;  
    

    
    //-------------------------------------------------------------------------
    
    //              SYNCHRONOUS OUTPUT OF VGA SIGNALS
    
    //-------------------------------------------------------------------------
    
    // COMBINE ALL OUTPUTS ON EACH CHANNEL
    wire[3:0] VGA_RED_CHAN = VGA_RED_GRID | VGA_RED_WAVEFORM | VGA_CURSOR_YELLOW | VGA_TEXT | VGA_VOLT | VGA_TIME;
    wire[3:0] VGA_GREEN_CHAN = VGA_GREEN_GRID | VGA_CURSOR_YELLOW | VGA_CURSOR_GREEN | VGA_TEXT | VGA_VOLT | VGA_TIME; 
    wire[3:0] VGA_BLUE_CHAN = VGA_BLUE_GRID | VGA_TEXT | VGA_VOLT | VGA_TIME;  


    // CLOCK THEM OUT
    always@(posedge CLK_VGA)
        begin      
        
            VGA_RED <= {VGA_active, VGA_active, VGA_active, VGA_active} & VGA_RED_CHAN ;  
            VGA_GREEN <= {VGA_active, VGA_active, VGA_active, VGA_active} & VGA_GREEN_CHAN ; 
            VGA_BLUE <= {VGA_active, VGA_active, VGA_active, VGA_active} & VGA_BLUE_CHAN ; 
                // VGA_active turns off output to screen if scan lines are outside the active screen area
            
            VGA_HS <= VGA_horzSync ;
            VGA_VS <= VGA_vertSync ;
            
        end

    
endmodule
