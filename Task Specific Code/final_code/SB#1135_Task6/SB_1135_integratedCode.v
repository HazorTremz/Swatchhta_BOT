/* 

    Team Id     :   1135 
    Author List :   Jayesh Chaudhary ,
                    Himanshu Singh Rawat ,
                    Parth Sharma 
    
    Filename   :    SB_1135_integratedCode 

    Theme      :    Swatchhta Bot (SB)

    Functions  :    Line Following , 
                    Colour Detection , 
                    UART communication with Xbee 
                    Arm Movement 

    Global variable : clk (50 MHz Clock ) 
*/





module SB_1135_integratedCode (

    
    // Global clock ( 50 MHz )
    input clk ,
    
    // Line Sensor I/O declaration   
    input  adc_data    , 
    output adc_chip_select , output adc_address , output adc_clk ,
	
    // Colour Sensor I/0 declaration  
	input colour_freq,
	output red_led, output blue_led,
	output s2,      output s3,
	output green_led ,

    // Arm port declaration 
    output UP_Down_Servo ,  output Gripper_servo ,

    // Motor Port declaration 
    output RW_F ,  // Right Front movement   
    output RW_B ,  // Right Back  movement 
    output LW_F ,  // Left  Front movement 
    output LW_B ,  // Left  Back  movement  
 
    // LED on Fpga to debug    
    output LEDL ,  // To indicate Left   Line sensor   
    output LEDC ,  // To indicate Centre Line sensor 
    output LEDR ,  // To indicate Right  Line sensor 

    output BIT0 ,
    output BIT1 ,  // To indicate which case is on depending on  
    output BIT2 ,  // line Sensor value 
    output BIT3 , 
    
    // Port declaration for UART communication with xbee
    output TX  

) ;




//                       ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~  Arena Important Parameter List   ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ 


/*
    Function : This section is used to store data of arena , so that it can be use to plan path 
               Data is store in the form array  
*/

// Parameters to map diffrent numbers with directions and turns  
localparam 
				north        = 3'b000 ,        
				east         = 3'b001 ,   
				south        = 3'b010 ,   
				west         = 3'b011 ,   
                northeast    = 3'b100 ,                    
				southwest    = 3'b100 ,                
				no_direction = 3'b111 ,   
				
				straight     =  4'b1000 , 
				left         =  4'b1001 , 
			    right        =  4'b1010 , 
			    dgr_180_R    =  4'b1011 , 
				dgr_180_L    =  4'b1100 ; 


 
reg [10:0]  inf = 100 ;               // infinity taken as 100                 
				

 // arrays to store maps Details  
reg [10:0] adjacent_nodes[25:0][3:0] ;           // to store data of adjacent node  - which node is connected  
reg [10:0] path_of_adjacent_nodes[25:0][3:0] ;   // to store distance between two adjacent nodes 
reg [10:0] final_heading [25:0][3:0] ;           // to store direction of one node with respect to another 
reg [10:0] turn_to_reach [25:0][3:0] ;	          // to store direction which will be needed by bot to turn to it adjacent node  
reg [10:0] turns_map [6:0][6:0]  ;               // to map direction with turns  
	
 
reg flag_initalize_map  = 1 ;                    // flag to initialize map only one time 
	          

always @ ( posedge clk )
begin

	if (flag_initalize_map == 1 )
	begin
	
    // Node Name 

	// node 0 : 

	adjacent_nodes         [0][0] = 1            ; adjacent_nodes         [0][1] = 26           ; adjacent_nodes         [0][2] = 26           ; adjacent_nodes         [0][3] = 26;
    path_of_adjacent_nodes [0][0] = 3            ; path_of_adjacent_nodes [0][1] = inf          ; path_of_adjacent_nodes [0][2] = inf          ; path_of_adjacent_nodes [0][3] = inf ;
	final_heading          [0][0] = east         ; final_heading          [0][1] = no_direction ; final_heading          [0][2] = no_direction ; final_heading          [0][3] = no_direction ; 
	turn_to_reach          [0][0] = south        ; turn_to_reach          [0][1] = no_direction ; turn_to_reach          [0][2] = no_direction ; turn_to_reach          [0][3] = no_direction ; 

   // node 1 : 
	
	adjacent_nodes         [1][0] = 0             ; adjacent_nodes         [1][1] = 2            ; adjacent_nodes         [1][2] = 13           ; adjacent_nodes         [1][3] = 26;
    path_of_adjacent_nodes [1][0] = 3             ; path_of_adjacent_nodes [1][1] = 3            ; path_of_adjacent_nodes [1][2] = 3            ; path_of_adjacent_nodes [1][3] = inf ;
	final_heading          [1][0] = north         ; final_heading          [1][1] = south        ; final_heading          [1][2] = east         ; final_heading          [1][3] = no_direction ; 
	turn_to_reach          [1][0] = west          ; turn_to_reach          [1][1] = south        ; turn_to_reach          [1][2] = east         ; turn_to_reach          [1][3] = no_direction ; 

	// node 2 : 
	
	adjacent_nodes         [2][0] = 1             ; adjacent_nodes         [2][1] = 3            ; adjacent_nodes         [2][2] = 5            ; adjacent_nodes         [2][3] = 26;
    path_of_adjacent_nodes [2][0] = 3             ; path_of_adjacent_nodes [2][1] = 1            ; path_of_adjacent_nodes [2][2] = 3            ; path_of_adjacent_nodes [2][3] = inf ;
	final_heading          [2][0] = north         ; final_heading          [2][1] = east         ; final_heading          [2][2] = south        ; final_heading          [2][3] = no_direction ; 
	turn_to_reach          [2][0] = north         ; turn_to_reach          [2][1] = east         ; turn_to_reach          [2][2] = south        ; turn_to_reach          [2][3] = no_direction ; 

	// node 3 : 
	
	adjacent_nodes         [3][0] = 2             ; adjacent_nodes         [3][1] = 26           ; adjacent_nodes         [3][2] = 26           ; adjacent_nodes         [3][3] = 26;
    path_of_adjacent_nodes [3][0] = 1             ; path_of_adjacent_nodes [3][1] = inf          ; path_of_adjacent_nodes [3][2] = inf          ; path_of_adjacent_nodes [3][3] = inf ;
	final_heading          [3][0] = west          ; final_heading          [3][1] = no_direction ; final_heading          [3][2] = no_direction ; final_heading          [3][3] = no_direction ; 
	turn_to_reach          [3][0] = west          ; turn_to_reach          [3][1] = no_direction ; turn_to_reach          [3][2] = no_direction ; turn_to_reach          [3][3] = no_direction ; 

	// node 4 : 
	
	adjacent_nodes         [4][0] = 6             ; adjacent_nodes         [4][1] = 26           ; adjacent_nodes         [4][2] = 26           ; adjacent_nodes         [4][3] = 26;
    path_of_adjacent_nodes [4][0] = 3             ; path_of_adjacent_nodes [4][1] = inf          ; path_of_adjacent_nodes [4][2] = inf          ; path_of_adjacent_nodes [4][3] = inf ;
	final_heading          [4][0] = northeast     ; final_heading          [4][1] = no_direction ; final_heading          [4][2] = no_direction ; final_heading          [4][3] = no_direction ; 
	turn_to_reach          [4][0] = south         ; turn_to_reach          [4][1] = no_direction ; turn_to_reach          [4][2] = no_direction ; turn_to_reach          [4][3] = no_direction ; 

	// node 5 : 
	
	adjacent_nodes         [5][0] = 2             ; adjacent_nodes         [5][1] =  6           ; adjacent_nodes         [5][2] = 9            ; adjacent_nodes         [5][3] = 26;
    path_of_adjacent_nodes [5][0] = 3             ; path_of_adjacent_nodes [5][1] =  1           ; path_of_adjacent_nodes [5][2] = 2            ; path_of_adjacent_nodes [5][3] = inf ;
	final_heading          [5][0] = north         ; final_heading          [5][1] = south        ; final_heading          [5][2] = east         ; final_heading          [5][3] = no_direction ; 
	turn_to_reach          [5][0] = north         ; turn_to_reach          [5][1] = south        ; turn_to_reach          [5][2] = east         ; turn_to_reach          [5][3] = no_direction ; 

	// node 6 : 
	
	adjacent_nodes         [6][0] = 4             ; adjacent_nodes         [6][1] = 5            ; adjacent_nodes         [6][2] =  16          ; adjacent_nodes         [6][3] = 26;
    path_of_adjacent_nodes [6][0] = 3             ; path_of_adjacent_nodes [6][1] = 1            ; path_of_adjacent_nodes [6][2] =  3           ; path_of_adjacent_nodes [6][3] = inf ;
	final_heading          [6][0] = north         ; final_heading          [6][1] = north        ; final_heading          [6][2] = east         ; final_heading          [6][3] = no_direction ; 
	turn_to_reach          [6][0] = southwest     ; turn_to_reach          [6][1] = north        ; turn_to_reach          [6][2] = east         ; turn_to_reach          [6][3] = no_direction ; 

	// node 7 : 
	
	adjacent_nodes         [7][0] = 12            ; adjacent_nodes         [7][1] = 26           ; adjacent_nodes         [7][2] = 26           ; adjacent_nodes         [7][3] = 26;
    path_of_adjacent_nodes [7][0] = 2             ; path_of_adjacent_nodes [7][1] = inf          ; path_of_adjacent_nodes [7][2] = inf          ; path_of_adjacent_nodes [7][3] = inf ;
	final_heading          [7][0] = east          ; final_heading          [7][1] = no_direction ; final_heading          [7][2] = no_direction ; final_heading          [7][3] = no_direction ; 
	turn_to_reach          [7][0] = south         ; turn_to_reach          [7][1] = no_direction ; turn_to_reach          [7][2] = no_direction ; turn_to_reach          [7][3] = no_direction ; 

	// node 8 : 
	
	adjacent_nodes         [8][0] = 9             ; adjacent_nodes         [8][1] = 26           ; adjacent_nodes         [8][2] = 26           ; adjacent_nodes         [8][3] = 26;
    path_of_adjacent_nodes [8][0] = 1             ; path_of_adjacent_nodes [8][1] = inf          ; path_of_adjacent_nodes [8][2] = inf          ; path_of_adjacent_nodes [8][3] = inf ;
	final_heading          [8][0] = south         ; final_heading          [8][1] = no_direction ; final_heading          [8][2] = no_direction ; final_heading          [8][3] = no_direction ; 
	turn_to_reach          [8][0] = south         ; turn_to_reach          [8][1] = no_direction ; turn_to_reach          [8][2] = no_direction ; turn_to_reach          [8][3] = no_direction ; 

	// node 9 : 
	
	adjacent_nodes         [9][0] = 8             ; adjacent_nodes         [9][1] = 5            ; adjacent_nodes         [9][2] = 15           ; adjacent_nodes         [9][3] = 26;
    path_of_adjacent_nodes [9][0] = 1             ; path_of_adjacent_nodes [9][1] = 2            ; path_of_adjacent_nodes [9][2] = 1            ; path_of_adjacent_nodes [9][3] = inf ;
	final_heading          [9][0] = north         ; final_heading          [9][1] = west         ; final_heading          [9][2] = east         ; final_heading          [9][3] = no_direction ; 
	turn_to_reach          [9][0] = north         ; turn_to_reach          [9][1] = west         ; turn_to_reach          [9][2] = east         ; turn_to_reach          [9][3] = no_direction ; 

	// node 10 : 
	
	adjacent_nodes         [10][0] = 16            ; adjacent_nodes         [10][1] = 26           ; adjacent_nodes         [10][2] = 26           ; adjacent_nodes         [10][3] = 26;
    path_of_adjacent_nodes [10][0] = 2             ; path_of_adjacent_nodes [10][1] = inf          ; path_of_adjacent_nodes [10][2] = inf          ; path_of_adjacent_nodes [10][3] = inf ;
	final_heading          [10][0] = south         ; final_heading          [10][1] = no_direction ; final_heading          [10][2] = no_direction ; final_heading          [10][3] = no_direction ; 
	turn_to_reach          [10][0] = east          ; turn_to_reach          [10][1] = no_direction ; turn_to_reach          [10][2] = no_direction ; turn_to_reach          [10][3] = no_direction ; 

	// node 11 : 
	
	adjacent_nodes         [11][0] = 12            ; adjacent_nodes         [11][1] = 26           ; adjacent_nodes         [11][2] = 26           ; adjacent_nodes         [11][3] = 26;
    path_of_adjacent_nodes [11][0] = 3             ; path_of_adjacent_nodes [11][1] = inf          ; path_of_adjacent_nodes [11][2] = inf          ; path_of_adjacent_nodes [11][3] = inf ;
	final_heading          [11][0] = south         ; final_heading          [11][1] = no_direction ; final_heading          [11][2] = no_direction ; final_heading          [11][3] = no_direction ; 
	turn_to_reach          [11][0] = west          ; turn_to_reach          [11][1] = no_direction ; turn_to_reach          [11][2] = no_direction ; turn_to_reach          [11][3] = no_direction ; 

	// node 12 : 
	
	adjacent_nodes         [12][0] = 7             ; adjacent_nodes         [12][1] = 11           ; adjacent_nodes         [12][2] = 17           ; adjacent_nodes         [12][3] = 13;
    path_of_adjacent_nodes [12][0] = 2             ; path_of_adjacent_nodes [12][1] = 3            ; path_of_adjacent_nodes [12][2] = 3            ; path_of_adjacent_nodes [12][3] = 1 ;
	final_heading          [12][0] = north         ; final_heading          [12][1] = east         ; final_heading          [12][2] = east         ; final_heading          [12][3] = south ; 
	turn_to_reach          [12][0] = west          ; turn_to_reach          [12][1] = north        ; turn_to_reach          [12][2] = east         ; turn_to_reach          [12][3] = south ; 

	// node 13 : 
	
	adjacent_nodes         [13][0] = 1             ; adjacent_nodes         [13][1] = 18           ; adjacent_nodes         [13][2] = 12           ; adjacent_nodes         [13][3] = 26;
    path_of_adjacent_nodes [13][0] = 3             ; path_of_adjacent_nodes [13][1] = 2            ; path_of_adjacent_nodes [13][2] = 1            ; path_of_adjacent_nodes [13][3] = inf ;
	final_heading          [13][0] = west          ; final_heading          [13][1] = east         ; final_heading          [13][2] = north        ; final_heading          [13][3] = no_direction ; 
	turn_to_reach          [13][0] = west          ; turn_to_reach          [13][1] = east         ; turn_to_reach          [13][2] = north        ; turn_to_reach          [13][3] = no_direction ; 

	// node 14 : 
	
	adjacent_nodes         [14][0] = 15            ; adjacent_nodes         [14][1] = 26           ; adjacent_nodes         [14][2] = 26           ; adjacent_nodes         [14][3] = 26;
    path_of_adjacent_nodes [14][0] = 1             ; path_of_adjacent_nodes [14][1] = inf          ; path_of_adjacent_nodes [14][2] = inf          ; path_of_adjacent_nodes [14][3] = inf ;
	final_heading          [14][0] = south         ; final_heading          [14][1] = no_direction ; final_heading          [14][2] = no_direction ; final_heading          [14][3] = no_direction ; 
	turn_to_reach          [14][0] = south         ; turn_to_reach          [14][1] = no_direction ; turn_to_reach          [14][2] = no_direction ; turn_to_reach          [14][3] = no_direction ; 

	// node 15 : 
	
	adjacent_nodes         [15][0] = 22            ; adjacent_nodes         [15][1] = 9            ; adjacent_nodes         [15][2] = 14           ; adjacent_nodes         [15][3] = 26;
    path_of_adjacent_nodes [15][0] = 1             ; path_of_adjacent_nodes [15][1] = 1            ; path_of_adjacent_nodes [15][2] = 1            ; path_of_adjacent_nodes [15][3] = inf ;
	final_heading          [15][0] = east          ; final_heading          [15][1] = west         ; final_heading          [15][2] = north        ; final_heading          [15][3] = no_direction ; 
	turn_to_reach          [15][0] = east          ; turn_to_reach          [15][1] = west         ; turn_to_reach          [15][2] = north        ; turn_to_reach          [15][3] = no_direction ; 

	// node 16 : 
	
	adjacent_nodes         [16][0] = 10            ; adjacent_nodes         [16][1] = 23           ; adjacent_nodes         [16][2] =  6           ; adjacent_nodes         [16][3] = 26;
    path_of_adjacent_nodes [16][0] = 2             ; path_of_adjacent_nodes [16][1] = 2            ; path_of_adjacent_nodes [16][2] = 3            ; path_of_adjacent_nodes [16][3] = inf ;
	final_heading          [16][0] = west          ; final_heading          [16][1] = north        ; final_heading          [16][2] = north        ; final_heading          [16][3] = no_direction ; 
	turn_to_reach          [16][0] = north         ; turn_to_reach          [16][1] = east         ; turn_to_reach          [16][2] = west         ; turn_to_reach          [16][3] = no_direction ; 

	// node 17 : 
	
	adjacent_nodes         [17][0] = 12            ; adjacent_nodes         [17][1] = 26           ; adjacent_nodes         [17][2] = 26           ; adjacent_nodes         [17][3] = 26;
    path_of_adjacent_nodes [17][0] = 3             ; path_of_adjacent_nodes [17][1] = inf          ; path_of_adjacent_nodes [17][2] = inf          ; path_of_adjacent_nodes [17][3] = inf ;
	final_heading          [17][0] = west          ; final_heading          [17][1] = no_direction ; final_heading          [17][2] = no_direction ; final_heading          [17][3] = no_direction ; 
	turn_to_reach          [17][0] = west          ; turn_to_reach          [17][1] = no_direction ; turn_to_reach          [17][2] = no_direction ; turn_to_reach          [17][3] = no_direction ; 

	// node 18 : 
	
	adjacent_nodes         [18][0] = 19            ; adjacent_nodes         [18][1] = 13           ; adjacent_nodes         [18][2] = 20           ; adjacent_nodes         [18][3] = 26;
    path_of_adjacent_nodes [18][0] = 1             ; path_of_adjacent_nodes [18][1] = 2            ; path_of_adjacent_nodes [18][2] = 1            ; path_of_adjacent_nodes [18][3] = inf ;
	final_heading          [18][0] = east          ; final_heading          [18][1] = west         ; final_heading          [18][2] = south		  ; final_heading          [18][3] = no_direction ; 
	turn_to_reach          [18][0] = east          ; turn_to_reach          [18][1] = west         ; turn_to_reach          [18][2] = south        ; turn_to_reach          [18][3] = no_direction ; 

	// node 19 : 
	
	adjacent_nodes         [19][0] = 18            ; adjacent_nodes         [19][1] = 26           ; adjacent_nodes         [19][2] = 26           ; adjacent_nodes         [19][3] = 26;
    path_of_adjacent_nodes [19][0] = 1             ; path_of_adjacent_nodes [19][1] = inf          ; path_of_adjacent_nodes [19][2] = inf          ; path_of_adjacent_nodes [19][3] = inf ;
	final_heading          [19][0] = west          ; final_heading          [19][1] = no_direction ; final_heading          [19][2] = no_direction ; final_heading          [19][3] = no_direction ; 
	turn_to_reach          [19][0] = west          ; turn_to_reach          [19][1] = no_direction ; turn_to_reach          [19][2] = no_direction ; turn_to_reach          [19][3] = no_direction ; 

	// node 20 : 
	
	adjacent_nodes         [20][0] = 21            ; adjacent_nodes         [20][1] = 18           ; adjacent_nodes         [20][2] = 22           ; adjacent_nodes         [20][3] = 26;
    path_of_adjacent_nodes [20][0] = 1             ; path_of_adjacent_nodes [20][1] = 1            ; path_of_adjacent_nodes [20][2] = 2            ; path_of_adjacent_nodes [20][3] = inf ;
	final_heading          [20][0] = east          ; final_heading          [20][1] = north        ; final_heading          [20][2] = south        ; final_heading          [20][3] = no_direction ; 
	turn_to_reach          [20][0] = east          ; turn_to_reach          [20][1] = north        ; turn_to_reach          [20][2] = south        ; turn_to_reach          [20][3] = no_direction ; 


	// node 21 : 
	
	adjacent_nodes         [21][0] = 20            ; adjacent_nodes         [21][1] = 26           ; adjacent_nodes         [21][2] = 26           ; adjacent_nodes         [21][3] = 26;
    path_of_adjacent_nodes [21][0] = 1             ; path_of_adjacent_nodes [21][1] = inf          ; path_of_adjacent_nodes [21][2] = inf          ; path_of_adjacent_nodes [21][3] = inf ;
	final_heading          [21][0] = west          ; final_heading          [21][1] = no_direction ; final_heading          [21][2] = no_direction ; final_heading          [21][3] = no_direction ; 
	turn_to_reach          [21][0] = west          ; turn_to_reach          [21][1] = no_direction ; turn_to_reach          [21][2] = no_direction ; turn_to_reach          [21][3] = no_direction ; 

	// node 22 : 
	
	adjacent_nodes         [22][0] = 15            ; adjacent_nodes         [22][1] = 20           ; adjacent_nodes         [22][2] = 25           ; adjacent_nodes         [22][3] = 23;
    path_of_adjacent_nodes [22][0] = 1             ; path_of_adjacent_nodes [22][1] = 2            ; path_of_adjacent_nodes [22][2] = 3            ; path_of_adjacent_nodes [22][3] = 1 ;
	final_heading          [22][0] = west          ; final_heading          [22][1] = north        ; final_heading          [22][2] = south        ; final_heading          [22][3] = south ; 
	turn_to_reach          [22][0] = west          ; turn_to_reach          [22][1] = north        ; turn_to_reach          [22][2] = east         ; turn_to_reach          [22][3] = south ; 

	// node 23 : 
	
	adjacent_nodes         [23][0] = 24            ; adjacent_nodes         [23][1] = 22           ; adjacent_nodes         [23][2] = 16           ; adjacent_nodes         [23][3] = 26;
    path_of_adjacent_nodes [23][0] = 2             ; path_of_adjacent_nodes [23][1] = 1            ; path_of_adjacent_nodes [23][2] = 2            ; path_of_adjacent_nodes [23][3] = inf ;
	final_heading          [23][0] = south         ; final_heading          [23][1] = north        ; final_heading          [23][2] = west         ; final_heading          [23][3] = no_direction ; 
	turn_to_reach          [23][0] = west          ; turn_to_reach          [23][1] = north        ; turn_to_reach          [23][2] = south        ; turn_to_reach          [23][3] = no_direction ; 

	// node 24 : 
	
	adjacent_nodes         [24][0] = 23            ; adjacent_nodes         [24][1] = 26           ; adjacent_nodes         [24][2] = 26           ; adjacent_nodes         [24][3] = 26;
    path_of_adjacent_nodes [24][0] = 2             ; path_of_adjacent_nodes [24][1] = inf          ; path_of_adjacent_nodes [24][2] = inf          ; path_of_adjacent_nodes [24][3] = inf ;
	final_heading          [24][0] = west          ; final_heading          [24][1] = no_direction ; final_heading          [24][2] = no_direction ; final_heading          [24][3] = no_direction ; 
	turn_to_reach          [24][0] = north         ; turn_to_reach          [24][1] = no_direction ; turn_to_reach          [24][2] = no_direction ; turn_to_reach          [24][3] = no_direction ; 

	// node 25 : 
	
	adjacent_nodes         [25][0] = 22            ; adjacent_nodes         [25][1] = 26           ; adjacent_nodes         [25][2] = 26           ; adjacent_nodes         [25][3] = 26;
    path_of_adjacent_nodes [25][0] = 3             ; path_of_adjacent_nodes [25][1] = inf          ; path_of_adjacent_nodes [25][2] = inf          ; path_of_adjacent_nodes [25][3] = inf ;
	final_heading          [25][0] = west          ; final_heading          [25][1] = no_direction ; final_heading          [25][2] = no_direction ; final_heading          [25][3] = no_direction ; 
	turn_to_reach          [25][0] = north         ; turn_to_reach          [25][1] = no_direction ; turn_to_reach          [25][2] = no_direction ; turn_to_reach          [25][3] = no_direction ; 
   
	
	
	// north
	
	turns_map [north][north]         = straight  ; turns_map [north][east]          = right     ; turns_map [north][west]     = left      ; turns_map [north][south]     = dgr_180_R ;
	turns_map [north][northeast]     = right     ; turns_map [north][southwest]     = dgr_180_L ;
	
	
	// south
	
	turns_map [east][north]          = left      ; turns_map [east][east]           = straight  ; turns_map [east][west]      = dgr_180_R ; turns_map [east][south]      = right     ; 
	turns_map [east][northeast]      = left      ; turns_map [east][southwest]      = dgr_180_R ;
	
	
	// west
	
	turns_map [west][north]          = right     ; turns_map [west][east]           = dgr_180_R ; turns_map [west][west]      = straight  ; turns_map [west][south]      = left      ; 
   turns_map [west][northeast]      = dgr_180_R ; turns_map [west][southwest]      = left      ;   

	// south
	
	turns_map [south][north]         = dgr_180_R ; turns_map [south][east]          = left      ; turns_map [south][west]     = right     ; turns_map [south][south]     = straight  ;
   turns_map [south][northeast]     = dgr_180_L ; turns_map [south][southwest]     = right     ;
	
	// northeast
	
	turns_map [northeast][north]     = left      ; turns_map [northeast][east]      = right     ; turns_map [northeast][west] = dgr_180_L ; turns_map [northeast][south] = dgr_180_R ; 
   turns_map [northeast][northeast] = straight  ; turns_map [northeast][southwest] = dgr_180_R ;
	
	// southwest
	
	turns_map [southwest][north]     = dgr_180_R ; turns_map [southwest][east]      = dgr_180_L ; turns_map [southwest][west] = right     ; turns_map [southwest][south] = left      ;
   turns_map [southwest][northeast] = dgr_180_R ; turns_map [southwest][southwest] = straight  ;

	
   flag_initalize_map = 0 ;

	end
end





//                   ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~   Line Sensor Communication ( via in built ADC on FPGA )   ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ 	


// register declarations to run 2.5 MHz clock  
reg    [4:0]counter_25  = 5'b0 ;
reg    clk_adc          = 0    ;
assign adc_clk          = clk_adc   ;


// register declarations for chip select   
reg    [1:0] chip_select_adc  = 2'b0 ;
assign adc_chip_select        = chip_select_adc ;


// register declarations to send address of channel   
reg    address_adc            = 0 ;
assign adc_address            = address_adc ;
reg    [4:0] adc_bit_counter  = 5'b00 ;         // count bit in a 16 cycle frame 


localparam 
			df_1 = 2'b01 ,    // dataframe for channel 1  --- 16 bit 
			df_2 = 2'b10 ,    // dataframe for channel 2  --- 16 bit 
			df_3 = 2'b11 ;    // dataframe for channel 3  --- 16 bit 
				

reg [1:0] adc_sm_address  = df_1 ;         // initalizing state machine with df_1 


localparam 
            channel_1 = 2'b01 ,
			channel_2 = 2'b10 ,
			channel_3 = 2'b11 ;

reg [4:0] adc_sm_channel_data  = channel_1 ;   // ADC state machine channel 


//  register declarations for data receiving and storage  
reg [11:0] L_linesensor = 0 ; 		  
reg [11:0] C_linesensor = 0 ;         	
reg [11:0] R_linesensor = 0 ;         

reg [11:0]Data_1 = 0; 
reg [11:0]Data_2 = 0;
reg [11:0]Data_3 = 0;

localparam 
            data_1 = 2'b01 ,
			data_2 = 2'b10 ,
			data_3 = 2'b11 ;


reg [1:0] adc_sm_data  = data_1 ;



// register declaration to find average value  
reg [8:0]  counter_avg = 0 ;

reg [15:0] inter_L_value = 0 ;
reg [15:0] inter_C_value = 0 ;
reg [15:0] inter_R_value = 0 ;
 
reg [11:0] avg_L_value = 0 ;
reg [11:0] avg_C_value = 0 ;
reg [11:0] avg_R_value = 0 ;





                                             
always @ (negedge clk )
begin	
       
  /* 
            Function : 2.5 MHz CLOCK FOR ADC  
            
            Description : This section is use to convert 50 MHz to 2.5 MHz clock so that it can be provided to adc clock  
				        : As 50 / 2.5 = 20 & 20/2 = 10 ,  so after every 10 clock cycle of 50 MHz a high or low signal is generated to form 2.5 MHz clock 
   */

		if ( counter_25 == 5'b0 | counter_25 == 5'b10100)
		begin
   		    clk_adc     = 0    ;
			counter_25  = 5'b0 ;
		end 
		
		else if ( counter_25 == 5'b01010) 
		begin
      	    clk_adc = 1 ;
		end
		
		counter_25 = 5'b1 + counter_25 ;
end





//                                        
always @ (negedge clk_adc)
begin

   /* 
            Function     :  DATA COLLECTION AND MANIPULATION FOR ADC 

            Description  : This state machine is used to sequentially address data to adc chip
                          so that in next cycle frame data from this channel can be obtain . 

                         : It get triggered when adc_bit_counter reaches count 01 , 02 and 03 .  

   				         : Highly count sensitive change parameter with caution . 

				         : df - data frame 
				           address_adc - output pin connected to adc address pin 
				           adc_sm_address  - state machine select input .  

   */

	if (adc_bit_counter == 5'b01 | adc_bit_counter == 5'b10 | adc_bit_counter == 5'b011)
	begin                                                          
		case (adc_sm_address )
			
			df_1 : begin
			if      (adc_bit_counter == 5'b01)  begin address_adc = 1 ; end 
			else if (adc_bit_counter == 5'b10)  begin address_adc = 0 ; end 
			else if (adc_bit_counter == 5'b011) begin address_adc = 1 ; adc_sm_address  = df_2; end 
			       end 
					 
			df_2 : begin
			if      (adc_bit_counter == 5'b01)  begin address_adc = 1 ; end 
			else if (adc_bit_counter == 5'b10)  begin address_adc = 1 ; end 
			else if (adc_bit_counter == 5'b011) begin address_adc = 0 ; adc_sm_address  = df_3 ; end 
			       end 
					 
			df_3 : begin
			if      (adc_bit_counter == 5'b01)  begin address_adc = 1 ; end 
			else if (adc_bit_counter == 5'b10)  begin address_adc = 1 ; end 
			else if (adc_bit_counter == 5'b011) begin address_adc = 1 ; adc_sm_address  = df_1 ;end 
			      end
	endcase 
	end
	


    /* Description :
	            : This state machine get triggered when adc_bit_countre reaches count 04

				: Data 1 - Variable to store data of channel 1 - Left line sensor  
				  Data 2 - Variable to store data of channel 2 - Centre line sensor
				  Data 3 - Variable to store data of channel 3 - Right line sensor      
                  adc_data -  input pin connected with adc output 

				: Right shift fn is performed so to clear out previous data and to store new data bit wise 
                
				: count sensitive change parameter with caution . 
    */
	if (adc_bit_counter >= 5'b100)
	begin
		case (adc_sm_data )
			
			data_1 : begin	
						Data_1 = Data_1 << 1 ;
						Data_1 = Data_1 + adc_data ;
			         end
			
			
			data_2 : begin	
						Data_2 = Data_2 << 1 ;
						Data_2 = Data_2 + adc_data ;
			         end
			
			data_3 : begin	
						Data_3 = Data_3 << 1 ;
						Data_3 = Data_3 + adc_data ;
			         end
	endcase 	
	end
	
	


   /*  Description :   
                : This section is used to store data of respective channel  
   */
	if (adc_bit_counter == 5'b00 | adc_bit_counter == 5'b10000 )
	begin
		case (adc_sm_channel_data)
		
		channel_1 : 
		            begin
					L_linesensor         = Data_1  ;
					adc_sm_channel_data  = channel_2 ;
					adc_sm_data          = data_2 ;
					end
						
						
		channel_2 :
					begin 
					C_linesensor         = Data_2  ;
					adc_sm_channel_data  = channel_3 ;
					adc_sm_data          = data_3 ;
					end 
						
						
		channel_3 : 
					begin 
					R_linesensor         = Data_3 ;
					adc_sm_channel_data  = channel_1 ;
					adc_sm_data          = data_1 ;
				    end 				
						
		endcase
	 end
	



   /*  Description :   
                : This section is used to  add data from consecutive channel values . 
   */
    if ( counter_avg == 10 ) begin inter_L_value = 0 ; inter_C_value = 0 ; inter_R_value = 0 ;  end
    if ( counter_avg == 16 | counter_avg == 64 | counter_avg == 112 | counter_avg == 160  ) begin inter_L_value = inter_L_value + L_linesensor ; end
	if ( counter_avg == 32 | counter_avg == 80 | counter_avg == 128 | counter_avg == 176  ) begin inter_C_value = inter_C_value + C_linesensor ; end
	if ( counter_avg == 48 | counter_avg == 96 | counter_avg == 144 | counter_avg == 192  ) begin inter_R_value = inter_R_value + R_linesensor ; end
	


   /*  Description :   
                : This section is used to  manipulate data by taking mean of value  .
				: And to reset counter 
   */
    if (counter_avg == 192 )
	begin
		avg_L_value = inter_L_value >> 2 ;
		avg_C_value = inter_C_value >> 2 ;
		avg_R_value = inter_R_value >> 2 ;

        if (avg_L_value <= white_threshold ) begin ledl = 1 ;  end
        if (avg_L_value > white_threshold )  begin ledl = 0 ;  end

        if (avg_C_value <= white_threshold ) begin ledc = 1 ; end
        if (avg_C_value > white_threshold )  begin ledc = 0 ; end

        if (avg_R_value <= white_threshold ) begin ledr = 1 ; end
        if (avg_R_value > white_threshold )  begin ledr = 0 ; end

		counter_avg = 0 ;
	end
   



   /*  Description :   
                : This section is used to to reset all adc counters and parameters .
   */
	if (adc_bit_counter == 5'b101)    
	begin
	   address_adc = 0 ;
	end 
	

	if (adc_bit_counter == 5'b10000)
	begin 
		adc_bit_counter = 0 ;		
	end
	



   /*  Description :   
                : This section is used to increase counter by value of 1  .
   */
	adc_bit_counter = adc_bit_counter + 1 ;
	counter_avg = counter_avg + 1 ;

end



//                   ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~   Path Planning     ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ 
//                   ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~   Line Following    ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ 
//                   ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~   Colour Detection  ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ 
//                   ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~   PWM Motor         ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ 
//                   ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~   Arm Movement      ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ 



// Registers and Variable Declarations 


// __ PATH PLANNING __  // 

// arrays to store Path plannning value and manipulate data 
reg [10:0] distance_from_starting_node[26:0] ;    // to store distance of node from starting node 
reg [1:0]  status_flag[26:0] ;	                  // to store whether particular node has been visited or not
reg [10:0] previous_node[26:0] ;                  // to store node from which was previously visited 
reg [10:0] dirn_turns_list[26:0] ;                // to store direction bot will move to visit particular node
reg [10:0] currt_heading[26:0] ;                  // to store current heading of bot 


// flags to start and stop path palnning function   
reg flag_reset_list = 1 ;
reg flag_main_loop  = 0 ; 


// flag to toggle between path planning and Line following  
reg map_setup = 1 ;


// internal flags to start and stop used in path planning  
reg flag_sub_node = 0 ;
reg flag_update_startDistance = 1 ;
reg flag_trace_node = 0 ;


// registers to store values used in path planning  
reg [10:0] pth_pln_cnt = 1 ;
reg [10:0] cumt_dis = 0 ;          // cummulative distance from starting node  
reg [10:0] least_value = 100  ;   


// 50 bit node to store turns and directions needed by bot to reach particular node from start 
reg [49:0]node_string  = 50'b11111111111111111111111111111111111111111111111111 ;
reg [49:0]string_turns = 50'b11111111111111111111111111111111111111111111111111 ;


// register to store start and end point 
///////////////////////////////////// |I|
                                   // |M| 
reg [10:0] strt_node    = 0  ;     // |P|  ---\ keep value of both
reg [10:0] current_node = 0  ;     // |o|  ---/ variable same 
                                   // |R| 
reg [4:0]  heading_ptr  = south ;  // |T|  ----> orientation of bot in physical world
reg [10:0] end_node  ;             // |A|  ----> it will take end node as last node define in string_point_to_visit   
                                   // |N| 
///////////////////////////////////// |T| 

// string to store nodes that are needed to visit 

//                        node10 -node9 -node 8 -node 7 -node 6 -node 5 -node 4 -node 3 -node 2 -node 1 ( 5 bit each )  
reg [49:0]string_point_to_visit  = 50'b11111100111010111001110000101001110010000010000011 ; // change bit to change destination bits     

// output string from path plannning which store turns for bot 
reg [49:0] turns = 50'b11111111111111111111111111111111111111111111111111 ;






// __ LINE FOLLOWING __  // 

// threshold to differentiate between black and white 
reg [11:0] white_threshold =  1900 ; 


// various flag to activate and deactivate part of a code  
reg flag_decision  = 0 ;    // flag to activate case section of line following 
reg flag_pwm       = 0 ;    // flag to activate pwm  section of line following 
reg flag_reset     = 1 ;    // flag to reset all parameter of line sensor  
reg flag_wait      = 0 ;    // flag to activate section of code to read turns from "turns" string and provide corresponding value to motor   
reg flag_search    = 0 ;    // flag to activate search and move functionality in which bot search for WBW condition and follow path  



// various counter to count number of time a particular case is encountered  
reg [8:0] cnt_case1 = 0 ;
reg [8:0] cnt_case2 = 0 ;  
reg [8:0] cnt_case3 = 0 ; 
reg [8:0] cnt_case4 = 0 ; 
reg [8:0] cnt_case5 = 0 ; 
reg [8:0] cnt_case6 = 0 ; 
reg [8:0] cnt_case7 = 0 ; 
reg [8:0] cnt_case8 = 0 ;

// threshold for case 
reg [8:0] cnt_caseX_thres = 50 ;


// various counter used in different functions
reg [8:0]  cnt_search = 0 ;
reg [30:0] cnt_slight = 0 ;
reg [30:0] cnt_force = 0 ;
reg [25:0] cnt_wait  = 0 ;


// flag to activate segment of code which  process the string and put new destination and source in path planning code   
reg flag_string_preprocessing = 0;

// counter to detect which color is detected 
reg [25:0] cnt_confirmation_color_detection = 0 ;

// counter to  count number of times a particular  colour is detected 
reg [10:0] blue_color_cnt   = 0  ;    // for blue  colour detection
reg [10:0] red_color_cnt    = 0  ;    // for red   colour detection
reg [10:0] green_color_cnt  = 0  ;    // for green colour detection 


// to store current turn given to bot 
reg [5:0] current_turns = 0 ;




// __ PWM __ //

// flag to select which condition is high 
reg flag_forward_mvt = 0 ;    // it is high when forward  movement is given 
reg flag_back_mvt    = 0 ;    // it is high when backward movement is given
reg flag_left_mvt    = 0 ;    // it is high when left     movement is given
reg flag_right_mvt   = 0 ;    // it is high when right    movement is given
reg flag_force_mvt   = 0 ;    // it is high when forceful movement is given

reg flag_slight_forward_mvt  = 0 ;  // it is high when slight forward movement is given 
reg flag_rotate_left         = 0 ;  // it is high when rotate movement is given 
reg flag_rotate_right        = 0 ;  // it is high when rotate movement is given 
reg flag_dgr_180_l           = 0 ;  // it is high when 180 degree turn is given 
reg flag_dgr_180_r           = 0 ;  // it is high when 180 degree turn is given 
reg flag_straight_turn       = 0 ;  // same as forward movement but with less pwm value  



// PWM counter for different wheels  
reg [25:0] cnt_pwm_str  =  0 ;  // for staight motion 
reg [25:0] cnt_pwm_rl   =  0 ;  // for right turn , left wheel 
reg [25:0] cnt_pwm_rr   =  0 ;  // for right turn , right wheel
reg [25:0] cnt_pwm_lr   =  0 ;  // for left  turn , left wheel  
reg [25:0] cnt_pwm_ll   =  0 ;  // for left  turn , left wheel 
reg [25:0] cnt_pwm_b    =  0 ;  // for back movement 


// assigning variables to output    
reg rw_f  = 0;   
reg rw_b  = 0;
reg lw_f  = 0;
reg lw_b  = 0;

assign RW_F = rw_f ;  // for Right Wheel Front 
assign RW_B = rw_b ;  // for Right Wheel Back
assign LW_F = lw_f ;  // for Left Wheel Front
assign LW_B = lw_b ;  // for Left Wheel Back




// __ COLOUR SENSOR __ //

reg temp_col_freq;                       // temperorary colour storage

reg [50:0] act_freq_cnt1 = 0;           // final frequency of 1st filter  
reg [50:0] cnt_freq_str1 = 0;           // count of frequency of 1st filte
reg [50:0] act_freq_cnt2 = 0;           // final frequency of 2nd filter  
reg [50:0] cnt_freq_str2 = 0;           // count of frequency of 2nd filte
reg [50:0] act_freq_cnt3 = 0;           // final  frequency of 3rd filter 
reg [50:0] cnt_freq_str3 = 0;           // count of frequency of 3rd filte
reg [50:0] act_freq_cnt4 = 0;           // final  frequency of 4th filter 
reg [50:0] cnt_freq_str4 = 0;           // count of frequency of 4th filte


// register to store temporary frequency count 
reg [50:0] new_act_freq_cnt1 = 0;
reg [50:0] new_act_freq_cnt2 = 0;
reg [50:0] new_act_freq_cnt3 = 0;
reg [50:0] new_act_freq_cnt4 = 0;

// use to sum all frequency 
reg [50:0] sum = 0;

// use to find average of frequency 
reg [50:0] avg = 0;


// filter selection lines 
reg s2f = 0;
reg s3f = 0;
assign s2 = s2f;
assign s3 = s3f;

reg rled = 0;    // red led 
reg gled = 0;    // green le
reg bled = 0;    // blue led

assign red_led   = rled;
assign green_led = gled;
assign blue_led  = bled;

// register to count respective colour signal 
reg [50:0] COUNT_RED   = 0;  // count red   frequency  signal
reg [50:0] COUNT_GREEN = 0;  // count green frequency  signal
reg [50:0] COUNT_BLUE  = 0;  // count blue  frequency  signal


// intermediate register to detect colour 
reg [50:0] count_1 = 0;
reg [50:0] count_2 = 0;
reg [50:0] count_3 = 0;
reg [50:0] count_4 = 0;

reg [50:0] final_val1 =  0;
reg [50:0] final_val2 =  0;
reg [50:0] final_val3 =  0;
reg [50:0] final_val4 =  0;

// for red 
reg [50:0] check_counter1r = 0;
reg [50:0] check_counter2r = 0;
reg [50:0] check_counter3r = 0;
reg [50:0] check_counter4r = 0;

// for green 
reg [50:0] check_counter1g = 0;
reg [50:0] check_counter2g = 0;
reg [50:0] check_counter3g = 0;
reg [50:0] check_counter4g = 0;

// for blue 
reg [50:0] check_counter1b = 0;
reg [50:0] check_counter2b = 0;
reg [50:0] check_counter3b = 0;
reg [50:0] check_counter4b = 0;

reg [50:0] red_delay    = 0;
reg [50:0] blue_delay   = 0;
reg [50:0] green_delay  = 0;
reg [50:0] global_count = 0;




// __SERVO __ //


// flag to move arm up & down & close & open 
reg flag_close_servo = 1 ;   // to close gripper 
reg flag_up_servo    = 0 ;   // to move arm up 
reg flag_down_servo  = 1 ;   // to move arm down 
reg flag_open_servo  = 0 ;   // to open gripper 



//  various counter to provide PWM to Servo motor     
reg [20:0] pwm_counter = 0 ;

// used to proveide delay motion to servo 
reg [20:0] delay_count = 0 ;

// flags to switch between different motion up and close & down and open
reg flag_one_up_close_servo  = 0 ;
reg flag_one_down_open_servo = 0 ;


// to assign variable to ouput of servo
reg up_down_servo = 0 ;
reg gripper_servo = 0 ;

assign UP_Down_Servo = up_down_servo ;
assign Gripper_servo = gripper_servo ;


// various flag to run arm mechanism 
reg flag_one_time_servo = 0 ;
reg flag_servo_position = 0 ;
reg flag_wait_counter  = 0 ;




// assigning variable to test cases through on board LEDS  
reg ledl = 0 ;
reg ledc = 0 ;
reg ledr = 0 ;

assign LEDL =  ledl ;   //  for left   line sensor data 
assign LEDC =  ledc ;   //  for centre line sensor data  
assign LEDR =  ledr ;   //  for right  line sensor data 


reg bit0 = 0 ;
reg bit1 = 0 ;
reg bit2 = 0 ;
reg bit3 = 0 ;

assign BIT0 =  bit0 ;   
assign BIT1 =  bit1 ;    // to detect which case of line sensor is working 
assign BIT2 =  bit2 ;
assign BIT3 =  bit3 ;


// __ UART __ //

reg Tx = 0 ;
assign TX = Tx ;


// parameters declare which will be used in state machine 
localparam 
				idle            =  1 ,
				start           =  2 ,
				stop            =  3 ,
				terminate       =  4 ,

// Identification  Pattern 

				G_letter1       =  5  ,             
                B_letter1       =  6  ,              
                I_letter1       =  7  ,             
                Block_number_1  =  8  ,             
                Dash_1          =  9  ,         
                Waste_type_1    =  10 ,             
                Dash_2          =  11 ,         
                Hash_1          =  12 ,
                Null_1          =  13 ,         

// Pick  Message Pattern 
               
               G_letter2        = 14 ,
               B_letter2        = 15 ,
               Block_number_2   = 16 , 
               Dash_3           = 17 ,
               Waste_type_2     = 18 ,
               Dash_4           = 19 ,
               P_letter2        = 20 ,
               I_letter2        = 21 ,
               C_letter2        = 22 ,
               K_letter2        = 23 ,
               Dash_5           = 24 ,
               Hash_2           = 25 ,
               Null_2           = 26 ,


// Dump  Message  Pattern 

                G_letter31       =  27 ,
                B_letter3        =  28 ,
			    Block_number_3   =  29 ,
			    Dash_6           =  30 ,
                Waste_type_3     =  31 ,				
				Dash_7           =  32 ,
                G_letter32       =  33 ,
                D_letter31       =  34 ,
			    Z_letter3        =  35 ,
                Dump_zone_1      =  36 ,
				Dash_8           =  37 ,
                D_letter32       =  38 ,
                U_letter3        =  39 ,
			    M_letter3        =  40 ,
                P_letter3        =  41 ,
                Dash_9           =  42 , 
                Hash_3           =  43 ,
                Null_3           =  42 ;



// registers declaration which will be used in changing state 
reg [8:0] identification_cnt  = idle ;
reg [8:0] pick_cnt            = idle ;
reg [8:0] dump_cnt            = idle ; 

reg [8:0] identification_data  =  5 ;
reg [8:0] pick_data            = 14 ;
reg [8:0] dump_data            = 27 ; 
 
// counters to declare 
reg [10:0] counter   = 0 ;
reg [8:0]bit_counter = 0 ;

// registers to hold binary data 
reg [7:0] g_letter       = 8'b01000111 ;   
reg [7:0] b_letter       = 8'b01000010 ;      
reg [7:0] i_letter       = 8'b01001001 ;    
reg [7:0] dash_letter    = 8'b00101101 ; 
reg [7:0] hash_letter    = 8'b00100011 ; 
reg [7:0] p_letter       = 8'b01010000 ; 
reg [7:0] c_letter       = 8'b01000011 ; 
reg [7:0] k_letter       = 8'b01001011 ; 
reg [7:0] d_letter       = 8'b01000100 ; 
reg [7:0] z_letter       = 8'b01011010 ; 
reg [7:0] u_letter       = 8'b01010101 ; 
reg [7:0] m_letter       = 8'b01001101 ; 
reg [7:0] null_letter    = 8'b00000000 ;   

// array ot store ascii character in respect with colour detected 
reg [7:0] waste_type   [2:0] ;
reg [7:0] block_number [8:0] ;
reg [7:0] dump_zone    [2:0] ;

reg block_select = 0 ;
reg waste_select = 0 ;
reg dump_select  = 0 ; 

// flag become high or low following action 
reg flag_uart_pick = 0 ;            //  when bot pick the block 
reg flag_uart_identification = 0 ;  //  when bot identified the block
reg flag_dump  = 0 ;                //  when bot dump the block  


reg flag_uart_intialize = 1 ;
reg flag_uart_message   = 1 ;








always @ ( posedge clk )
begin


if (map_setup == 0 )
begin

/* Function : Path Planning  
   
   Description : Path planning is based Dijkstra Algorithm 
*/

// open and close list to store data 
    if (flag_reset_list == 1 )
    	begin
        
       //node 0 : 
     	distance_from_starting_node [0]  = inf ; status_flag [0]  = 0 ;  previous_node [0]  = 27 ;   dirn_turns_list[0] = 0 ;   currt_heading[0] = 0 ;  

    	//node 1 :	
       distance_from_starting_node [1]  = inf ; status_flag [1]  = 0 ;  previous_node [1]  = 27 ;   dirn_turns_list[1] = 0 ;   currt_heading[1] = 0 ;
    
    	//node 2 :
    	distance_from_starting_node [2]  = inf ; status_flag [2]  = 0 ;  previous_node [2]  = 27 ;   dirn_turns_list[2] = 0 ;   currt_heading[2] = 0 ;
    
    	//node 3 :
    	distance_from_starting_node [3]  = inf ; status_flag [3]  = 0 ;  previous_node [3]  = 27 ;   dirn_turns_list[3] = 0 ;   currt_heading[3] = 0 ;
    
    	//node 4 :
    	distance_from_starting_node [4]  = inf ; status_flag [4]  = 0 ;  previous_node [4]  = 27 ;   dirn_turns_list[4] = 0 ;   currt_heading[4] = 0 ;
    
    	//node 5 :
    	distance_from_starting_node [5]  = inf ; status_flag [5]  = 0 ;  previous_node [5]  = 27 ;   dirn_turns_list[5] = 0 ;   currt_heading[5] = 0 ;
    
    	//node 6 :
    	distance_from_starting_node [6]  = inf ; status_flag [6]  = 0 ;  previous_node [6]  = 27 ;   dirn_turns_list[6] = 0 ;   currt_heading[6] = 0 ;
    
    	//node 7 :
    	distance_from_starting_node [7]  = inf ; status_flag [7]  = 0 ;  previous_node [7]  = 27 ;   dirn_turns_list[7] = 0 ;   currt_heading[7] = 0 ;
    
    	//node 8 :
    	distance_from_starting_node [8]  = inf ; status_flag [8]  = 0 ;  previous_node [8]  = 27 ;   dirn_turns_list[8] = 0 ;   currt_heading[8] = 0 ;
    
    	//node 9 :
    	distance_from_starting_node [9]  = inf ; status_flag [9]  = 0 ;  previous_node [9]  = 27 ;   dirn_turns_list[9] = 0 ;   currt_heading[9] = 0 ; 
    
    	//node 10 :
    	distance_from_starting_node [10] = inf ; status_flag [10] = 0 ;  previous_node [10] = 27 ;   dirn_turns_list[10] = 0 ;  currt_heading[10] = 0 ; 
    
    	//node 11 :
    	distance_from_starting_node [11] = inf ; status_flag [11] = 0 ;  previous_node [11] = 27 ;   dirn_turns_list[11] = 0 ;  currt_heading[11] = 0 ; 
    
    	//node 12 :
    	distance_from_starting_node [12] = inf ; status_flag [12] = 0 ;  previous_node [12] = 27 ;   dirn_turns_list[12] = 0 ;  currt_heading[12] = 0 ;
    
    	//node 13 :
    	distance_from_starting_node [13] = inf ; status_flag [13] = 0 ;  previous_node [13] = 27 ;   dirn_turns_list[13] = 0 ;  currt_heading[13] = 0 ;
    
    	//node 14 :
    	distance_from_starting_node [14] = inf ; status_flag [14] = 0 ;  previous_node [14] = 27 ;   dirn_turns_list[14] = 0 ;  currt_heading[14] = 0 ;
    
    	//node 15 :
    	distance_from_starting_node [15] = inf ; status_flag [15] = 0 ;  previous_node [15] = 27 ;   dirn_turns_list[15] = 0 ;  currt_heading[15] = 0 ;
    
    	//node 16 :
    	distance_from_starting_node [16] = inf ; status_flag [16] = 0 ;  previous_node [16] = 27 ;   dirn_turns_list[16] = 0 ;  currt_heading[16] = 0 ;
    
    	//node 17 :
    	distance_from_starting_node [17] = inf ; status_flag [17] = 0 ;  previous_node [17] = 27 ;   dirn_turns_list[17] = 0 ;  currt_heading[17] = 0 ;
    
    	//node 18 :
    	distance_from_starting_node [18] = inf ; status_flag [18] = 0 ;  previous_node [18] = 27 ;   dirn_turns_list[18] = 0 ;  currt_heading[18] = 0 ;
    
    	//node 19 :
    	distance_from_starting_node [19] = inf ; status_flag [19] = 0 ;  previous_node [19] = 27 ;   dirn_turns_list[19] = 0 ;  currt_heading[19] = 0 ;
    
    	//node 20 :
    	distance_from_starting_node [20] = inf ; status_flag [20] = 0 ;  previous_node [20] = 27 ;   dirn_turns_list[20] = 0 ;  currt_heading[20] = 0 ;
    
    	//node 21 :
    	distance_from_starting_node [21] = inf ; status_flag [21] = 0 ;  previous_node [21] = 27 ;   dirn_turns_list[21] = 0 ;  currt_heading[21] = 0 ;
    
    	//node 22 :
    	distance_from_starting_node [22] = inf ; status_flag [22] = 0 ;  previous_node [22] = 27 ;   dirn_turns_list[22] = 0 ;  currt_heading[22] = 0 ;
    
    	//node 23 :
    	distance_from_starting_node [23] = inf ; status_flag [23] = 0 ;  previous_node [23] = 27 ;   dirn_turns_list[23] = 0 ;  currt_heading[23] = 0 ;
    
    	//node 24 :
    	distance_from_starting_node [24] = inf ; status_flag [24] = 0 ;  previous_node [24] = 27 ;   dirn_turns_list[24] = 0 ;  currt_heading[24] = 0 ;
    
    	//node 25 :
    	distance_from_starting_node [25] = inf ; status_flag [25] = 0 ;  previous_node [25] = 27 ;   dirn_turns_list[25] = 0 ;  currt_heading[25] = 0 ;
    
    	//node 26 :
    	distance_from_starting_node [26] = inf ; status_flag [26] = 1 ;  previous_node [26] = 27 ;   dirn_turns_list[26] = 0 ;  currt_heading[26] = 0 ;

    	flag_reset_list = 0 ;
        flag_main_loop =  1 ; 
    
    
    
    end
    
    
    // Path planning main loop 
    if (flag_main_loop == 1 )
    begin


    // updating start node inital distance ( one time call  )
     if ( flag_update_startDistance == 1 )
     begin
    	distance_from_starting_node[strt_node] = 0 ; 
    	currt_heading[strt_node] = heading_ptr ; 
    	node_string  = 50'b11111111111111111111111111111111111111111111111111 ;
		string_turns  = 50'b11111111111111111111111111111111111111111111111111 ;
    	flag_update_startDistance = 0 ;
    	flag_sub_node = 1 ;
     end


    
    // updating  "current" node and changing values of parameter      
     if ( pth_pln_cnt == 2 && flag_sub_node == 1  )
     begin
    	status_flag[current_node] = 1 ; 
    	least_value = 100 ;
     end



    /// update sub node values 
     if (pth_pln_cnt > 2  && pth_pln_cnt <= 6 && flag_sub_node == 1 )
     begin
    	if ( distance_from_starting_node[adjacent_nodes[current_node][pth_pln_cnt-3]]  > distance_from_starting_node[current_node] + path_of_adjacent_nodes[current_node][pth_pln_cnt-3] ) 
    	begin
    		distance_from_starting_node[adjacent_nodes[current_node][pth_pln_cnt-3]] = distance_from_starting_node[current_node] + path_of_adjacent_nodes[current_node][pth_pln_cnt-3] ;
    		previous_node[adjacent_nodes[current_node][pth_pln_cnt-3]] = current_node ;
    
    		currt_heading[adjacent_nodes[current_node][pth_pln_cnt-3]]   = final_heading[current_node][pth_pln_cnt-3] ;
    		dirn_turns_list[adjacent_nodes[current_node][pth_pln_cnt-3]] = turns_map [currt_heading[current_node]][turn_to_reach[current_node][pth_pln_cnt - 3]] ;
    	end 
     end
    
    
    /// next  " current " node selection from list 
     if ( pth_pln_cnt > 6 && pth_pln_cnt <= 32 && flag_sub_node == 1 )
     begin 
    	if ( distance_from_starting_node[pth_pln_cnt - 7] < least_value && status_flag[pth_pln_cnt - 7] == 0 )
    	begin
    		least_value = distance_from_starting_node[pth_pln_cnt - 7] ;
    		current_node = pth_pln_cnt - 7 ; 
        end 
     end
    

    
    /// Interrupt when end NODE == CURRENT NODE 
     if (end_node == current_node && flag_sub_node == 1 )
     begin
    	flag_sub_node = 0 ; 
    	pth_pln_cnt = 0 ;
    	flag_trace_node = 1 ;
     end  
    
    
    
    /// trace back all nodes to find path 
     if (flag_trace_node == 1 )
     begin
       node_string = node_string << 5 ;
    	node_string = node_string + current_node ;

    		$display (current_node ) ;
            if      (dirn_turns_list[current_node]  == 8)  begin  string_turns = string_turns << 5 ; string_turns = string_turns + 8  ; end 
    		else if (dirn_turns_list[current_node]  == 9)  begin  string_turns = string_turns << 5 ; string_turns = string_turns + 9  ; end
    		else if (dirn_turns_list[current_node]  == 10) begin  string_turns = string_turns << 5 ; string_turns = string_turns + 10 ; end
    		else if (dirn_turns_list[current_node]  == 11) begin  string_turns = string_turns << 5 ; string_turns = string_turns + 11 ; end
    		else if (dirn_turns_list[current_node]  == 12) begin  string_turns = string_turns << 5 ; string_turns = string_turns + 12 ; end
    
    	current_node = previous_node[current_node] ;
       if ( current_node == 27 ) begin flag_trace_node = 0 ;heading_ptr = currt_heading[end_node]; flag_main_loop = 0 ; flag_reset_list = 1 ; strt_node = end_node ; map_setup = 1 ; flag_reset = 1 ; end
     end


    /// reset pth_pln_cnt after 34 clock 
     if ( pth_pln_cnt == 34 )
     begin
    	pth_pln_cnt = 0 ;
     end

    
    pth_pln_cnt = pth_pln_cnt + 1 ;	
    end


end



/*
    Function :  Line Following 

    Description : This section of code is used to follow line by using values from line sensor  
*/

if (map_setup == 1 )
begin

    // section of code to reset all parameters 
    if ( flag_reset == 1 )  
    begin

        // resetting case counters 
        cnt_case1 = 0 ; cnt_case2 = 0 ; cnt_case3 = 0 ;
        cnt_case4 = 0 ; cnt_case5 = 0 ; cnt_case6 = 0 ;
        cnt_case7 = 0 ; cnt_case8 = 0 ;

        // resetting various flag of movement 
        flag_forward_mvt  = 0 ; flag_back_mvt     = 0 ;
        flag_left_mvt     = 0 ; flag_right_mvt    = 0 ;

        flag_rotate_left  = 0 ; flag_rotate_right = 0 ;
        flag_dgr_180_r    = 0 ; flag_dgr_180_l    = 0 ;

        flag_pwm    = 0 ; flag_decision   = 1 ;  
        flag_reset  = 0 ; flag_search     = 0 ;


        // resetting different counters 
        red_color_cnt     = 0 ; green_color_cnt   = 0 ; blue_color_cnt    = 0 ;
		cnt_force         = 0 ; cnt_slight        = 0 ;
        cnt_pwm_str       = 0 ; cnt_pwm_b         = 0 ; cnt_pwm_lr      = 0 ;
        cnt_pwm_ll        = 0 ; cnt_pwm_rl        = 0 ; cnt_pwm_rr      = 0 ;

        cnt_confirmation_color_detection = 0 ;

    end


    // part of code which process the string and send command to motors whether to turn left or right 
    if ( flag_string_preprocessing == 1)
    begin

		rw_f = 0 ;
        rw_b = 0 ;
        lw_f = 0 ;
        lw_b = 0 ;

        // detecting current turn 
        current_turns = string_turns[4:0];

        // if current turn is 31 
        if ( current_turns == 31 )
        begin

            // detecting whether any colour is detected or not  				
			if (cnt_confirmation_color_detection < 100000 )
            begin 

            cnt_confirmation_color_detection  =  cnt_confirmation_color_detection + 1  ;

            if (cnt_confirmation_color_detection == 20000 | cnt_confirmation_color_detection == 40000 | cnt_confirmation_color_detection == 60000 | cnt_confirmation_color_detection == 80000 | cnt_confirmation_color_detection == 100000  ) 
            begin 
                // if detected then respective count will get high 
                if (bled  == 1) begin blue_color_cnt  = blue_color_cnt + 1   ;  red_color_cnt   = 0  ; green_color_cnt  = 0 ; end
                if (rled  == 1) begin red_color_cnt   = red_color_cnt + 1    ;  blue_color_cnt  = 0  ; green_color_cnt  = 0 ; end
                if (gled  == 1) begin green_color_cnt = green_color_cnt + 1  ;  red_color_cnt   = 0  ; blue_color_cnt   = 0 ; end
            end
            
            end

            
            // if number of count is higher than 2 than dump end point is set as end node  
            if (( blue_color_cnt > 2 | red_color_cnt > 2 | green_color_cnt > 2 ) & cnt_confirmation_color_detection >= 100000 )
            begin
                    if      (blue_color_cnt  > 2 ) begin end_node = 17 ; block_select = end_node ; waste_select = 0 ; dump_select = 0 ; end
                    else if (green_color_cnt > 2 ) begin end_node = 11 ; block_select = end_node ; waste_select = 1 ; dump_select = 1 ; end
                    else if (red_color_cnt   > 2 ) begin end_node = 7  ; block_select = end_node ; waste_select = 2 ; dump_select = 2 ; end

                    flag_reset_list            = 1 ;
                    flag_update_startDistance  = 1 ;
                    current_node               = strt_node ; 
                    map_setup                  = 0 ;
                    flag_string_preprocessing  = 0 ;
                    flag_servo_position        = 1 ;
                    flag_close_servo           = 1 ;
                    cnt_confirmation_color_detection = 0 ;
                    flag_one_down_open_servo   = 0 ;
                    flag_one_up_close_servo    = 0 ;
     
            end 
            
            
            if (strt_node == 17 | strt_node == 11 | strt_node == 7 )
            begin
                bled = 0 ;
                gled = 0 ;
                rled = 0 ;
                if (strt_node == 17 ) begin end
                if (strt_node == 17 ) begin end
                if (strt_node == 17 ) begin end
            end 

            // if number of count is less than 2 then end node is obtain from string point to visit 
            if ( (blue_color_cnt < 2 & red_color_cnt < 2 & green_color_cnt < 2) & cnt_confirmation_color_detection >= 100000 )
            begin
                    flag_reset_list               = 1 ;
                    flag_update_startDistance     = 1 ;
                    current_node                  = strt_node ; 
                    end_node                      = string_point_to_visit[4:0] ;
                    string_point_to_visit         = string_point_to_visit >> 5 ;
                    map_setup                     = 0 ;
                    flag_string_preprocessing     = 0 ;
                    cnt_confirmation_color_detection = 0 ;
                    flag_servo_position           = 0 ;
                    flag_down_servo               = 1 ;
                    flag_one_down_open_servo      = 0 ;
                    flag_one_up_close_servo       = 0 ;
            end             
        end

       // if current turn is not 31 
        if ( current_turns != 31 )
        begin
            flag_wait = 1 ;
            flag_string_preprocessing = 0 ;
        end
    end  

    // turns from string is determined 
    if (flag_wait == 1 )
    begin
        
        cnt_wait = cnt_wait + 1 ;
        
        rw_f = 0 ;
        rw_b = 0 ;
        lw_f = 0 ;
        lw_b = 0 ;
        flag_pwm = 0 ; 

            
        if (cnt_wait == 500 )
        begin
                
            // if current turn is 8 then forward movement 
            if (current_turns == 8  ) begin flag_straight_turn  = 1 ; flag_slight_forward_mvt  = 1 ; end
           
            // if current turn is 9 then rotate left 
            if (current_turns == 9  ) begin flag_rotate_left    = 1 ; flag_slight_forward_mvt  = 1 ; end
            
            // if current turn is 10 then rotate right 
            if (current_turns == 10 ) begin flag_rotate_right   = 1 ; flag_slight_forward_mvt  = 1 ; end
            
            // if current turn is 11 then 180 degree right turn  
            if (current_turns == 11 ) begin flag_dgr_180_r      = 1 ; flag_slight_forward_mvt  = 1 ; end
           
            // if current turn is 12 then 180 degree left turn  
            if (current_turns == 12 ) begin flag_dgr_180_l      = 1 ; flag_slight_forward_mvt  = 1 ; end

                string_turns = string_turns >> 5 ;   // right shift string 5 times 
				flag_wait = 0;                       // low wait flag 
                cnt_wait  = 0 ;                      // reset cnt flag 
                flag_pwm  = 1 ;                      // high pwm flag 
                flag_string_preprocessing = 0 ;      // low string pre processing flag 
			    flag_reset = 0 ;                     // low reset flag 
        end 
    end



    if ( flag_decision == 1 )
    begin
 

/*                                         __CASES__
                         __CONDITION__                   __ACTION__ 
                             W W W                          stop         
                             W W B                          right mvt 
                             W B W                          forward mvt
                             W B B                          right mvt
                             B W W                          left mvt
                             B W B                          -- no action --
                             B B W                          left mvt
                             B B B                          node detected - string precprocessing
*/


 //     case 1 : ( W W W)       
        if ( avg_L_value <= white_threshold & avg_C_value <= white_threshold & avg_R_value <= white_threshold   )
        begin
            cnt_case1 = cnt_case1 + 1 ;

            cnt_case2 = 0 ;
            cnt_case3 = 0 ;
            cnt_case4 = 0 ;
            cnt_case5 = 0 ;
            cnt_case6 = 0 ;
            cnt_case7 = 0 ;
            cnt_case8 = 0 ;

            if (cnt_case1 == 500 )
            begin

               // using on board led of Fpga as debug mechanism 
                bit0 = 1  ;
                bit1 = 0  ;
                bit2 = 0  ;
                bit3 = 0  ;

               // stopping bot 
                rw_f = 0 ;
                rw_b = 0 ;
                lw_f = 0 ;
                lw_b = 0 ;
                
                // setting flags for various condition 
                flag_reset   = 0 ; flag_decision  = 0 ;
                flag_pwm     = 1 ; flag_back_mvt  = 1 ;

                flag_forward_mvt   = 0 ;  flag_left_mvt       = 0 ; 
                flag_right_mvt     = 0 ;  flag_straight_turn  = 0 ; 
                flag_rotate_left   = 0 ;  flag_rotate_right   = 0 ; 
                flag_dgr_180_l     = 0 ;  flag_dgr_180_r      = 0 ;

                cnt_pwm_str   = 0 ; cnt_pwm_b       = 0 ;
                cnt_pwm_lr    = 0 ; cnt_pwm_ll      = 0 ;
                cnt_pwm_rl    = 0 ; cnt_pwm_rr      = 0 ;
                cnt_slight    = 0 ; cnt_force       = 0 ;


                flag_wait = 0 ; flag_string_preprocessing = 0 ;

                
            end
        end


 //     case 2 : ( W W B)       
        if ( avg_L_value <= white_threshold & avg_C_value <= white_threshold & avg_R_value > white_threshold   )
        begin
            cnt_case2 = cnt_case2 + 1 ;

            cnt_case1 = 0 ;
            cnt_case3 = 0 ;
            cnt_case4 = 0 ;
            cnt_case5 = 0 ;
            cnt_case6 = 0 ;
            cnt_case7 = 0 ;
            cnt_case8 = 0 ;

            if (cnt_case2 == 100)
            begin

                // using on board led of Fpga as debug mechanism 
                bit0 = 0  ;
                bit1 = 1  ;
                bit2 = 0  ;
                bit3 = 0  ;


                flag_forward_mvt = 0 ; flag_back_mvt    = 0 ;
                flag_left_mvt    = 0 ; flag_right_mvt   = 1 ;
                flag_pwm         = 1 ; flag_decision    = 0 ;


                 // setting flags for various condition
                flag_straight_turn   = 0 ;  flag_rotate_left     = 0 ; 
                flag_rotate_right    = 0 ;  flag_dgr_180_l       = 0 ; 
                flag_dgr_180_r       = 0 ;

                cnt_pwm_str     = 0 ;  cnt_pwm_b       = 0 ;
                cnt_pwm_lr      = 0 ;  cnt_pwm_ll      = 0 ;
                cnt_pwm_rl      = 0 ;  cnt_pwm_rr      = 0 ;
                cnt_slight      = 0 ;  cnt_force       = 0 ;

                
                flag_wait = 0 ; flag_reset = 0 ;
                flag_string_preprocessing = 0 ;
               
            end
        end


 //     case 3 : ( W B W)       
        if ( avg_L_value <= white_threshold & avg_C_value > white_threshold & avg_R_value <= white_threshold   )
        begin

            cnt_case3 = cnt_case3 + 1 ;

            cnt_case2 = 0 ;
            cnt_case1 = 0 ;
            cnt_case4 = 0 ;
            cnt_case5 = 0 ;
            cnt_case6 = 0 ;
            cnt_case7 = 0 ;
            cnt_case8 = 0 ;

            if (cnt_case3 == 100 )
            begin

                // using on board led of Fpga as debug mechanism 
                bit0 = 1  ;
                bit1 = 1  ;
                bit2 = 0  ;
                bit3 = 0  ;

                flag_forward_mvt = 1 ;
                flag_back_mvt    = 0 ;
                flag_left_mvt    = 0 ;
                flag_right_mvt   = 0 ;
                flag_pwm         = 1 ;
                flag_decision    = 0 ;

              
                 
                // setting flags for various condition
                flag_straight_turn   = 0 ;  flag_rotate_left     = 0 ; 
                flag_rotate_right    = 0 ;  flag_dgr_180_l       = 0 ; 
                flag_dgr_180_r       = 0 ;

                cnt_pwm_str     = 0 ;  cnt_pwm_b       = 0 ;
                cnt_pwm_lr      = 0 ;  cnt_pwm_ll      = 0 ;
                cnt_pwm_rl      = 0 ;  cnt_pwm_rr      = 0 ;
                cnt_slight      = 0 ;  cnt_force       = 0 ;

                flag_wait = 0 ;
                flag_string_preprocessing = 0 ;
                flag_reset = 0 ;

            end
        end


 //     case 4 : ( W B B)       
        if ( avg_L_value <= white_threshold & avg_C_value > white_threshold & avg_R_value > white_threshold   )
        begin
            cnt_case4 = cnt_case4 + 1 ;

            cnt_case2 = 0 ;
            cnt_case3 = 0 ;
            cnt_case1 = 0 ;
            cnt_case5 = 0 ;
            cnt_case6 = 0 ;
            cnt_case7 = 0 ;
            cnt_case8 = 0 ;

            if (cnt_case4 == 100 )
            begin

                // using on board led of Fpga as debug mechanism 
                bit0 = 0  ;
                bit1 = 0  ;
                bit2 = 1  ;
                bit3 = 0  ;


                // setting flags for various condition
                flag_forward_mvt = 0 ; flag_back_mvt    = 0 ;
                flag_left_mvt    = 0 ; flag_right_mvt   = 1 ;
                flag_pwm         = 1 ; flag_decision    = 0 ;
 
                flag_straight_turn  = 0 ;  flag_rotate_left    = 0 ; 
                flag_rotate_right   = 0 ;  flag_dgr_180_l      = 0 ; 
                flag_dgr_180_r      = 0 ;

                cnt_pwm_str     = 0 ;  cnt_pwm_b       = 0 ;
                cnt_pwm_lr      = 0 ;  cnt_pwm_ll      = 0 ;
                cnt_pwm_rl      = 0 ;  cnt_pwm_rr      = 0 ;
                cnt_slight      = 0 ;  cnt_force       = 0 ;


                flag_wait = 0 ; flag_reset = 0 ;
                flag_string_preprocessing = 0 ;

            end
        end


 //     case 5 : ( B W W)       
        if ( avg_L_value > white_threshold & avg_C_value <= white_threshold & avg_R_value <= white_threshold   )
        begin
            cnt_case5 = cnt_case5 + 1 ;

            cnt_case2 = 0 ;
            cnt_case3 = 0 ;
            cnt_case4 = 0 ;
            cnt_case1 = 0 ;
            cnt_case6 = 0 ;
            cnt_case7 = 0 ;
            cnt_case8 = 0 ;

            if (cnt_case5 == 100 )
            begin

                // using on board led of Fpga as debug mechanism 
                bit0 = 1  ;
                bit1 = 0  ;
                bit2 = 1  ;
                bit3 = 0  ;


                // setting flags for various condition
                flag_forward_mvt = 0 ; flag_back_mvt    = 0 ;
                flag_left_mvt    = 1 ; flag_right_mvt   = 0 ;
                flag_pwm         = 1 ; flag_decision    = 0 ;

                        
                flag_straight_turn  = 0 ;  flag_rotate_left    = 0 ; 
                flag_rotate_right   = 0 ;  flag_dgr_180_l      = 0 ; 
                flag_dgr_180_r      = 0 ;

                cnt_pwm_str     = 0 ;  cnt_pwm_b       = 0 ;
                cnt_pwm_lr      = 0 ;  cnt_pwm_ll      = 0 ;
                cnt_pwm_rl      = 0 ;  cnt_pwm_rr      = 0 ;
                cnt_slight      = 0 ;  cnt_force       = 0 ;

                flag_wait = 0 ;
                flag_string_preprocessing = 0 ;
                flag_reset = 0 ;

            end
        end



 //     case 6 : ( B W B)       
        if ( avg_L_value > white_threshold & avg_C_value <= white_threshold & avg_R_value > white_threshold  )
        begin
            cnt_case6 = cnt_case6 + 1 ;

            cnt_case2 = 0 ;
            cnt_case3 = 0 ;
            cnt_case4 = 0 ;
            cnt_case5 = 0 ;
            cnt_case1 = 0 ;
            cnt_case7 = 0 ;
            cnt_case8 = 0 ;

            if (cnt_case6 == 100 )
            begin

                // using on board led of Fpga as debug mechanism                
                bit0 = 0  ;
                bit1 = 1  ;
                bit2 = 1  ;
                bit3 = 0  ;

                rw_f = 0 ;
                rw_b = 0 ;
                lw_f = 0 ;
                lw_b = 0 ;


                flag_reset = 1 ;
                flag_pwm   = 0 ;
                flag_decision  = 0 ;
 

                // setting flags for various condition
                flag_forward_mvt    = 0 ;  flag_left_mvt       = 0 ; 
                flag_back_mvt       = 0 ;  flag_right_mvt      = 0 ; 
                flag_straight_turn  = 0 ;  flag_rotate_left    = 0 ; 
                flag_rotate_right   = 0 ;  flag_dgr_180_l      = 0 ; 
                flag_dgr_180_r      = 0 ;

                cnt_pwm_str     = 0 ;  cnt_pwm_b       = 0 ;
                cnt_pwm_lr      = 0 ;  cnt_pwm_ll      = 0 ;
                cnt_pwm_rl      = 0 ;  cnt_pwm_rr      = 0 ;
                cnt_slight      = 0 ;  cnt_force       = 0 ;



                flag_wait = 0 ;
                flag_string_preprocessing = 0 ;
            end
        end



 //     case 7 : ( B B W)       
        if ( avg_L_value > white_threshold & avg_C_value > white_threshold & avg_R_value <= white_threshold   )
        begin
            cnt_case7 = cnt_case7 + 1 ;

            cnt_case2 = 0 ;
            cnt_case3 = 0 ;
            cnt_case4 = 0 ;
            cnt_case5 = 0 ;
            cnt_case6 = 0 ;
            cnt_case1 = 0 ;
            cnt_case8 = 0 ;

            if (cnt_case7 == 100 )
            begin

                // using on board led of Fpga as debug mechanism 
                bit0 = 1  ;
                bit1 = 1  ;
                bit2 = 1  ;
                bit3 = 0  ;

                flag_forward_mvt = 0 ;
                flag_back_mvt    = 0 ;
                flag_left_mvt    = 1 ;
                flag_right_mvt   = 0 ;
                flag_pwm         = 1 ;
                flag_decision    = 0 ;

                // setting flags for various condition
                flag_straight_turn  = 0 ;  flag_rotate_left    = 0 ; 
                flag_rotate_right   = 0 ;  flag_dgr_180_l      = 0 ; 
                flag_dgr_180_r      = 0 ;


                cnt_pwm_str     = 0 ;  cnt_pwm_b       = 0 ;
                cnt_pwm_lr      = 0 ;  cnt_pwm_ll      = 0 ;
                cnt_pwm_rl      = 0 ;  cnt_pwm_rr      = 0 ;
                cnt_slight      = 0 ;  cnt_force       = 0 ;

                flag_wait = 0 ;
                flag_string_preprocessing = 0 ;
            end
        end



 //     case 8 : ( B B B)       
        if ( avg_L_value > white_threshold & avg_C_value > white_threshold & avg_R_value > white_threshold   )
        begin
            cnt_case8 = cnt_case8 + 1 ;

            cnt_case2 = 0 ;
            cnt_case3 = 0 ;
            cnt_case4 = 0 ;
            cnt_case5 = 0 ;
            cnt_case6 = 0 ;
            cnt_case7 = 0 ;
            cnt_case1 = 0 ;

            if (cnt_case8 == 500 )
            begin

                // using on board led of Fpga as debug mechanism 
                bit0 = 0  ;
                bit1 = 0  ;
                bit2 = 0  ;
                bit3 = 1  ;

                flag_string_preprocessing  = 1 ;
                flag_reset = 0 ;
                flag_pwm   = 0 ;
                flag_decision  = 0 ;


                // setting flags for various condition
                flag_forward_mvt    = 0 ;  flag_left_mvt       = 0 ; 
                flag_back_mvt       = 0 ;  flag_right_mvt      = 0 ; 
                flag_straight_turn  = 0 ;  flag_rotate_left    = 0 ; 
                flag_rotate_right   = 0 ;  flag_dgr_180_l      = 0 ; 
                flag_dgr_180_r      = 0 ;

                cnt_pwm_str     = 0 ;  cnt_pwm_b       = 0 ;
                cnt_pwm_lr      = 0 ;  cnt_pwm_ll      = 0 ;
                cnt_pwm_rl      = 0 ;  cnt_pwm_rr      = 0 ;
                cnt_slight      = 0 ;  cnt_force       = 0 ;
                

                flag_wait = 0 ;

            end
        end
    end 

    // flag to start search and find mechanism 
    if (flag_search == 1)
    begin
        if ( avg_L_value <= white_threshold & avg_C_value > white_threshold & avg_R_value <= white_threshold  )
        begin

            cnt_search = cnt_search + 1 ;
            if (cnt_search == 50 )
            begin
                cnt_search = 0 ;
                flag_reset = 1 ;
                flag_pwm = 0 ;
                flag_search = 0 ;
            end 

        end
    end






// PWM of Motor 



    if (flag_pwm == 1)
    begin

/*   Function :  PWM of Motor 
     Description : This section of code is used to provide PWM value to motor so to control
                    there direction and speed 
*/


// PWM for forward motion  
        if (flag_forward_mvt == 1 )
        begin

            // for high cycle
            if (cnt_pwm_str <= 100 )      
            begin
                rw_f = 0 ;
                rw_b = 1 ;                     
                lw_f = 0 ;
                lw_b = 1 ;
            end

            // for low cycle
            if (cnt_pwm_str > 110)      
            begin
                rw_f = 0 ;
                rw_b = 0 ;
                lw_f = 0 ;
                lw_b = 0 ;
            end

            // overall time period
            if (cnt_pwm_str == 120 )    
            begin
                cnt_pwm_str     = 0 ;  flag_reset      = 1 ;
                flag_pwm        = 0 ;  flag_force_mvt  = 0 ;
            end

            // pwm counter 
            cnt_pwm_str = cnt_pwm_str + 1 ;     
        end



// for backward motion 
        if (flag_back_mvt == 1 )
        begin
            
            // for up cycle 
            if (cnt_pwm_b <= 100000 )
            begin
                rw_f = 1 ;
                rw_b = 0 ;
                lw_f = 1 ;
                lw_b = 0 ;
            end
 
            // for low cycle 
            if (cnt_pwm_b > 100000)
            begin
                rw_f = 0 ;
                rw_b = 0 ;
                lw_f = 0 ;
                lw_b = 0 ;
            end

            // overall time period 
            if (cnt_pwm_b == 100000 )
            begin
                cnt_pwm_b      = 0 ;
                flag_reset    = 1 ;
                flag_pwm      = 0 ;
                flag_back_mvt = 0 ;
            end

            cnt_pwm_b = cnt_pwm_b + 1 ;         
        end


        // for left movement  
        if (flag_left_mvt == 1 )
        begin
             
            // right wheel up cycle 
            if (cnt_pwm_lr <= 150000)
            begin
                rw_f = 0 ;
                rw_b = 1 ;
            end
             
            // right wheel low cycle 
            if (cnt_pwm_lr > 150000)
            begin
                rw_f = 0 ;
                rw_b = 0 ;
            end

            // overall time period 
            if (cnt_pwm_lr == 150000)
            begin
                cnt_pwm_lr       = 0 ;
                flag_reset    = 1 ;
                flag_pwm      = 0 ;
                flag_left_mvt = 0 ;
            end
				
            // counter of pwm 
            cnt_pwm_lr = cnt_pwm_lr + 1 ;
			
            // left wheel up cycle 
            if (cnt_pwm_ll <= 130000 )
            begin
                lw_f = 1 ;
                lw_b = 0;
            end

            // left wheel down cycle 
            if (cnt_pwm_ll > 130000 )
            begin
                lw_f = 0 ;
                lw_b = 0 ;
            end
            
            // overall time period 
            if (cnt_pwm_ll == 130000 )
            begin
                cnt_pwm_ll  = 0 ;
            end
		    
            // counter of pwm 
            cnt_pwm_ll = cnt_pwm_ll + 1 ;                
				
        end





        // for right movement 
        if (flag_right_mvt == 1 )
        begin
            
            // right wheel , high cycle 
            if (cnt_pwm_rl <= 150000 )
            begin
                lw_f = 0 ;
                lw_b = 1 ;
            end

            // right wheel , low cycle 
            if (cnt_pwm_rl > 150000 )
            begin
                lw_f = 0 ;
                lw_b = 0 ;
            end

            // overall time period 
            if (cnt_pwm_rl == 150000 )
            begin
                cnt_pwm_rl       = 0 ;
                flag_reset    = 1 ;
                flag_pwm      = 0 ;
                flag_right_mvt = 0 ;
            end

            // counter of pwm 
            cnt_pwm_rl = cnt_pwm_rl + 1 ;

            // left wheel , high cycle 
			if (cnt_pwm_rr <= 130000 )
            begin
                rw_f = 1 ;
                rw_b = 0 ;
            end

            // left wheel , low cycle 
            if (cnt_pwm_rr > 130000 )
            begin
                rw_f = 0 ;
                rw_b = 0 ;
            end
 
            // overall time period 
            if (cnt_pwm_rr == 130000 )
            begin
                cnt_pwm_rr       = 0 ;
            end
            
            // counter of pwm 
            cnt_pwm_rr = cnt_pwm_rr + 1 ;
        end




        // pwm for forward movement 
        if ( flag_straight_turn == 1 )
        begin
     
            // for slight forward movemnt 
            if ( flag_slight_forward_mvt == 1 )
            begin
                
                rw_f = 0 ;
                rw_b = 1 ;
                lw_f = 0 ;
                lw_b = 1 ;

                cnt_slight = cnt_slight + 1;

                // counter 
                if (cnt_slight == 2000)
                begin
                    cnt_slight = 0 ;
                    flag_slight_forward_mvt = 0 ;
                    flag_force_mvt = 1 ;
                end
            end
 
            // force mvt of wheel to run straight 
            if ( flag_force_mvt == 1 )
            begin
                
                rw_f = 0 ;
                rw_b = 1 ;
                lw_f = 0 ;
                lw_b = 1 ;

                cnt_force = cnt_force + 1 ;

                if (cnt_force == 2000)
                begin
                    flag_force_mvt = 0 ;
                    cnt_force = 0 ;
                    flag_search = 1 ;
                    flag_straight_turn = 0 ;
                end
            end
			end



        // PWM to rotate left 
        if ( flag_rotate_left == 1 )
        begin
            
            // PWM for slight forward movement 
            if ( flag_slight_forward_mvt == 1 )
            begin
                
                rw_f = 0 ;
                rw_b = 1 ;
                lw_f = 0 ;
                lw_b = 1 ;

                cnt_slight = cnt_slight + 1;

                if (cnt_slight == 4500000)
                begin
                    cnt_slight = 0 ;
                    flag_slight_forward_mvt = 0 ;
                    flag_force_mvt = 1 ;
                end
            end
            
            // PWM for force left movement 
            if ( flag_force_mvt == 1 )
            begin
                
                rw_f = 0 ;
                rw_b = 1 ;
                lw_f = 1 ;
                lw_b = 0 ;

                cnt_force = cnt_force + 1 ;

                if (cnt_force == 10555500)
                begin
                    flag_force_mvt = 0 ;
                    cnt_force = 0 ;
                    flag_search = 1 ;
                    flag_rotate_left = 0 ;
                end
            end

        end


        // PWM for rotate right 
        if ( flag_rotate_right == 1 )
        begin
             
            // PWM for slight forward mvt 
            if ( flag_slight_forward_mvt == 1 )
            begin
                
                rw_f = 0 ;
                rw_b = 1 ;
                lw_f = 0 ;
                lw_b = 1 ;

                cnt_slight = cnt_slight + 1;

                if (cnt_slight == 6500000)
                begin
                    cnt_slight = 0 ;
                    flag_slight_forward_mvt = 0 ;
                    flag_force_mvt = 1 ;
                    
                end
            end
            
            // PWM for force rotate right 
            if ( flag_force_mvt == 1 )
            begin
                
                rw_f = 1 ;
                rw_b = 0 ;
                lw_f = 0 ;
                lw_b = 1 ;

                cnt_force = cnt_force + 1 ;

                if (cnt_force == 9000000)
                begin
                    flag_force_mvt = 0 ;
                    cnt_force = 0 ;
                    flag_search = 1 ;
                    flag_rotate_right = 0 ;
                end
            end
            
        end


        // PWM to rotate 180 degree left 
        if ( flag_dgr_180_l == 1 )
        begin
            
            // PWM for slight forward movement 
            if ( flag_slight_forward_mvt == 1 )
            begin
                
                rw_f = 0 ;
                rw_b = 1 ;
                lw_f = 1 ;
                lw_b = 0 ;

                cnt_slight = cnt_slight + 1;

                if (cnt_slight == 2)
                begin
                    cnt_slight = 0 ;
                    flag_slight_forward_mvt = 0 ;
                    flag_force_mvt = 1 ;
                end
            end

            // PWM for force rotate left 180 degree 
            if ( flag_force_mvt == 1 )
            begin
                
                rw_f = 0 ;
                rw_b = 1 ;
                lw_f = 1 ;
                lw_b = 0 ;

                cnt_force = cnt_force + 1 ;

                if (cnt_force == 60000000 )
                begin
                    flag_force_mvt = 0 ;
                    cnt_force = 0 ;
                    flag_search = 1 ;
                    flag_dgr_180_l = 0 ;
                end
            end
            
        end


        // PWM to rotate right 180 degree 
        if ( flag_dgr_180_r == 1 )
        begin

            // PWM for forward slight movement 
            if ( flag_slight_forward_mvt == 1 )
            begin
                
                rw_f = 0 ;
                rw_b = 1 ;
                lw_f = 1 ;
                lw_b = 0 ;

                cnt_slight = cnt_slight + 1;

                if (cnt_slight == 2)
                begin
                    cnt_slight = 0 ;
                    flag_slight_forward_mvt = 0 ;
                    flag_force_mvt = 1 ;
                end
            end

            // PWM for force rotate right 180 degree 
            if ( flag_force_mvt == 1 )
            begin
               
                rw_f = 0 ;
                rw_b = 1 ;
                lw_f = 1 ;
                lw_b = 0 ;

                cnt_force = cnt_force + 1 ;

                if (cnt_force == 61555000)
                begin
                    flag_force_mvt = 0 ;
                    cnt_force = 0 ;
                    flag_search = 1 ;
                    flag_dgr_180_r = 0 ;
                end
            end  
        end
    end
 end 
	 

// __ COLOUR SENSOR __ //

/*
   Function     :  To detect colour through coclour sensor    
   Description  :  This section of code generate 16 sample values for each filter and checking there 
                   occurances wrt to the given range of each colour
 */
if (global_count <5000000 ) 
begin
            	if (s2f ==0 & s3f == 0 ) 
                begin
            		if (count_1 < 78125)
                    begin
            			temp_col_freq <= colour_freq;
            			if (colour_freq) cnt_freq_str1 <= cnt_freq_str1 + 1;
            			else if (temp_col_freq) 
                        begin
            				act_freq_cnt1 <= cnt_freq_str1;
            				cnt_freq_str1 <= 0;
            			end
            			count_1 = count_1+1;
            		end

    		        else 
                    begin
    		        	count_1 = 0;
    		        	s2f = 1;
    		        	s3f = 1;
    		        	new_act_freq_cnt1 = new_act_freq_cnt1 + act_freq_cnt1;
    		        	final_val1 = new_act_freq_cnt1;
    		        	if (1800 < act_freq_cnt1 &  3000 > act_freq_cnt1)
                        begin
    		        		check_counter1r = check_counter1r+1;
                        end
    		        	if (2500 < act_freq_cnt1 &  4500 > act_freq_cnt1)
                        begin
    		        		check_counter1g = check_counter1g+1;	
                        end
    		        	if (8000 < act_freq_cnt1 &  10000 > act_freq_cnt1)
                        begin
    		        		check_counter1b = check_counter1b+1;	
                        end
    		        end
                end
    


    		    if (s2f ==1 & s3f == 1 ) 
                begin
    		        if (count_2 < 78125)
                    begin
    			        temp_col_freq <= colour_freq;
    			        if (colour_freq)
    				        cnt_freq_str2 <= cnt_freq_str2 + 1;
    			        else if (temp_col_freq) 
                        begin
    				        act_freq_cnt2 <= cnt_freq_str2;
    				        cnt_freq_str2 <= 0;
    			        end
    			        count_2 = count_2+1;
    		        end


    		    else 
                begin
    			    count_2 = 0;
    			    s2f = 1;
    			    s3f = 0;
    			    new_act_freq_cnt2 = new_act_freq_cnt2 + act_freq_cnt2;
    			    final_val2 = new_act_freq_cnt2;
    			    if (8500 < act_freq_cnt2 &  10500 > act_freq_cnt2)
                    begin
    				    check_counter2r = check_counter2r+1;
                    end
    			    if (2000 < act_freq_cnt2 &  3500 > act_freq_cnt2)
                    begin
    				    check_counter2g = check_counter2g+1;	
                    end
    			    if (6000 < act_freq_cnt2 &  7500 > act_freq_cnt2)
                    begin
    				    check_counter2b = check_counter2b+1;	
                    end
    		    end
    	    end
    

    	    if  (s2f ==1 & s3f == 0 ) 
            begin
    		    if (count_3 < 78125)
                begin
    			    temp_col_freq <= colour_freq;
    			    if (colour_freq)
    				    cnt_freq_str3 <= cnt_freq_str3 + 1;
    			    else if (temp_col_freq) 
                    begin
    				    act_freq_cnt3 <= cnt_freq_str3;
    				    cnt_freq_str3 <= 0;
    			    end
    			    count_3 = count_3+1;
    		    end


    		else 
            begin
    			count_3 = 0;
    			s2f = 0;
    			s3f = 1;
    			new_act_freq_cnt3 = new_act_freq_cnt3 + act_freq_cnt3;
    			final_val3 = new_act_freq_cnt3;
    			if (1000 < act_freq_cnt3 &  2000 > act_freq_cnt3)
                begin
    				check_counter3r = check_counter3r+1;
                end
    			if (800 < act_freq_cnt3 &  1400 > act_freq_cnt3)
                begin
    				check_counter3g = check_counter3g+1;	
                end
    			if (1200 < act_freq_cnt3 &  2000 > act_freq_cnt3)
                begin
    				check_counter3b = check_counter3b+1;	
                end
    			end
    	    end
    

    	    if (s2f ==0 & s3f == 1 ) 
            begin
    		    if (count_4 < 78125)
                begin
    			    temp_col_freq <= colour_freq;
    			if (colour_freq)
    				cnt_freq_str4 <= cnt_freq_str4 + 1;
    			else if (temp_col_freq) 
                begin
    				act_freq_cnt4 <= cnt_freq_str4;
    				cnt_freq_str4 <= 0;

    			end
    			count_4 = count_4+1;
    		end


    		else 
            begin
    				count_4 = 0;
    				s2f = 0;
    				s3f = 0;
    				new_act_freq_cnt4 = new_act_freq_cnt4 + act_freq_cnt4;
    				final_val4 = new_act_freq_cnt4;
    			if (5800 < act_freq_cnt4 &  7000 > act_freq_cnt4)
                begin
    					check_counter4r = check_counter4r+1;
                end
    			if (4000 < act_freq_cnt4 &  5500 > act_freq_cnt4)
                begin
    					check_counter4g = check_counter4g+1;	
                end
    			if (2000 < act_freq_cnt4 &  3500 > act_freq_cnt4)
                begin
    					check_counter4b = check_counter4b+1;	
                end
    		end
    	end
    	global_count = global_count +1 ;
end


else 
begin
        sum = (final_val1 >> 4)+(final_val2 >> 4)+(final_val3 >> 4)+(final_val4 >> 4);
        avg = sum >> 2;
        COUNT_RED   = check_counter1r+check_counter2r+check_counter3r+check_counter4r;
        COUNT_GREEN = check_counter1g+check_counter2g+check_counter3g+check_counter4g;
        COUNT_BLUE  = check_counter1b+check_counter2b+check_counter3b+check_counter4b;

        global_count       = 0  ;
        new_act_freq_cnt1  = 0  ;
        new_act_freq_cnt2  = 0  ;
        new_act_freq_cnt3  = 0  ;
        new_act_freq_cnt4  = 0  ;
        check_counter1b    = 0  ;
        check_counter2b    = 0  ;
        check_counter3b    = 0  ;
        check_counter4b    = 0  ;
        check_counter1r    = 0  ;
        check_counter2r    = 0  ;
        check_counter3r    = 0  ;
        check_counter4r    = 0  ;
        check_counter1g    = 0  ;
        check_counter2g    = 0  ;
        check_counter3g    = 0  ;
        check_counter4g    = 0  ;
end


//& (avg>4600 & avg<5200)
if (COUNT_GREEN <25  & COUNT_BLUE< 25 & (COUNT_RED>=25  & COUNT_RED <= 64) )
begin
		red_delay = red_delay+1;
		if (red_delay == 800000) 
        begin
			red_delay = 0;
			rled = 1;
			gled = 0;
			bled = 0;
		end
		end
		
        //& (avg>3100 & avg<3500)
		else if (COUNT_BLUE < 25  &  COUNT_RED < 25 & (COUNT_GREEN>=49  & COUNT_GREEN <= 64))
		begin
		green_delay = green_delay+1;
		if (green_delay == 800000) 
        begin
			green_delay = 0;
			rled = 0;
			gled = 1;
			bled = 0;
		end
		end


	///(avg>5000 & avg<5210)	
		else if (COUNT_GREEN < 25   & COUNT_RED < 25 & (COUNT_BLUE>=28 & COUNT_BLUE <= 64))
		begin
		blue_delay = blue_delay+1;
		if (blue_delay == 800000) 
        begin
			blue_delay = 0;
			rled = 0;
    			gled = 0;
    			bled = 1;
                end 
end


//  SERVO //  

/* Function :   To move arm up and down & open and close 
   Description :  This section is used to manipulate arm to lift cubical block (pick n place mechanism )
*/

// this flag is needed to make arm move down and open 
if (flag_servo_position == 0 )
begin
        

        // PWM to  down arm structure   
        if (flag_down_servo == 1)
        begin
            if (pwm_counter <= 125000 ) 
            begin
                up_down_servo = 1 ;
                flag_one_time_servo = 1 ;
            end

            if (pwm_counter > 125000 ) 
            begin 

                up_down_servo = 0 ;

                if (flag_one_time_servo == 1 )
                begin
                    delay_count = delay_count + 1  ;
                    flag_one_time_servo = 0 ;
                end

                if (delay_count == 10 )
                begin
                    delay_count = 0 ;

                    if ( flag_one_down_open_servo == 0 )
                    begin
                        flag_open_servo = 1 ;
                        flag_one_up_close_servo  = 0 ;
                        flag_one_down_open_servo = 1 ;
                        flag_down_servo = 0 ;
                        flag_close_servo  = 1 ;
						flag_up_servo  = 0 ;
                        flag_wait_counter = 0 ;
                    end

                    else 
                    begin 
                        flag_down_servo = 1 ;
                    end
                end
            end   
        end 
   


        // PWM to open gripper 
        if (flag_open_servo == 1)
            begin
                if (pwm_counter <= 135000) 
                begin
                    
                    flag_one_time_servo = 1 ;
						  gripper_servo = 1;
                end

                if (pwm_counter > 135000) 
                begin 

                    gripper_servo = 0 ;

                    if (flag_one_time_servo == 1 )
                    begin
                        delay_count  = delay_count + 1  ;
                        flag_one_time_servo  = 0 ;
                    end

                    if (delay_count == 10 )
                    begin
                        delay_count       = 0 ;
                        flag_down_servo   = 1 ;
                        flag_open_servo   = 0 ;
                        flag_close_servo  = 1  ;
                        flag_one_up_close_servo  = 0 ;
						flag_up_servo  = 0  ;
                        flag_wait_counter = 0 ;
                    end
                end   
            end 


        if (pwm_counter == 1000000 )
        begin
                pwm_counter = 0 ;
        end

        pwm_counter = pwm_counter + 1 ;       
end 



// this flag is needed to to move arm up and close 
if (flag_servo_position == 1 )
begin


        // PWM to close gripper 
        if (flag_close_servo == 1)
        begin
            if (pwm_counter <= 5000) 
            begin
                gripper_servo = 1 ;
                flag_one_time_servo = 1 ;
            end

            if (pwm_counter > 5000) 
            begin 

                gripper_servo = 0 ;

                if (flag_one_time_servo == 1 )
                begin
                    delay_count = delay_count + 1  ;
                    flag_one_time_servo = 0 ;
                end

                if (delay_count == 10 )
                begin
                    delay_count = 0 ;
                    flag_close_servo = 0 ;

                    if ( flag_one_up_close_servo == 0 )
                    begin
                        flag_up_servo = 0 ;
                        flag_one_up_close_servo = 1 ;
                        flag_one_down_open_servo = 0 ;
                        flag_close_servo = 0 ;
                        flag_down_servo  = 1 ;
                        flag_open_servo = 0 ;
                        flag_wait_counter = 1 ;
                    end

                    else 
                    begin 
                        flag_close_servo = 1 ;
                        flag_down_servo  = 1 ;
                        flag_open_servo = 0 ;
                    end
                end
            end   
        end 
   


        // Wait loop to provide some delay between close and up  
        if (flag_wait_counter == 1)
        begin
        
           if (pwm_counter <= 1000  )
           begin
               flag_one_time_servo = 1 ;
           end
        
           if (pwm_counter > 1000)
           begin
               
               if (flag_one_time_servo == 1)
               begin
                   delay_count = delay_count +1 ;
                   flag_one_time_servo = 0 ;
               end
               
               if (delay_count == 13 )
               begin
                   delay_count = 0 ;
                   flag_wait_counter = 0 ;
                   flag_up_servo = 1; 
               end 
        
           end
        
        end 






        // PWM to up arm mechanism  
         if (flag_up_servo == 1)
            begin
                if (pwm_counter <= 105000) 
                begin
                    up_down_servo = 1 ;
                    flag_one_time_servo = 1 ;
                end

                if (pwm_counter > 105000) 
                begin 

                    up_down_servo = 0 ;

                    if (flag_one_time_servo == 1 )
                    begin
                        delay_count = delay_count + 1  ;
                        flag_one_time_servo = 0 ;
                    end

                    if (delay_count == 10 )
                    begin
                        delay_count = 0 ;
                        flag_close_servo = 1 ;
                        flag_one_down_open_servo = 0 ;
                        flag_up_servo = 0 ;
                        flag_down_servo  = 1 ;
                        flag_open_servo = 0 ;
                        
                    end
                end   
            end 


        if (pwm_counter == 1000000 )
        begin
                pwm_counter = 0 ;
        end

        pwm_counter = pwm_counter + 1 ;
end 


// __ UART__ // 

if (flag_uart_intialize == 1 )
begin

    waste_type [0] = 8'b01010111 ;  //--> W
    waste_type [1] = 8'b01000100 ;  //--> D
    waste_type [2] = 8'b01000111 ;  //--> M

    block_number [0] = 8'b00110001  ;  // --> 1
    block_number [1] = 8'b00110010  ;  // --> 2
    block_number [2] = 8'b00110011  ;  // --> 3
    block_number [3] = 8'b00110100  ;  // --> 4
    block_number [4] = 8'b00110101  ;  // --> 5
    block_number [5] = 8'b00110110  ;  // --> 6
    block_number [6] = 8'b00110111  ;  // --> 7
    block_number [7] = 8'b00111000  ;  // --> 8
    block_number [8] = 8'b00111001  ;  // --> 9

    dump_zone [0] = 8'b01000001 ; //---> A
    dump_zone [1] = 8'b01000010 ; //---> B
    dump_zone [2] = 8'b01000011 ; //---> C

    flag_uart_intialize = 0 ;
end 






if (flag_uart_message == 1 )
begin

// counter to snychronize uart @ 115200 baud rate  
if (counter == 0 || counter == 9'b110110010 )
begin 

    // state machine used when bot identifies the block 
    if ( flag_uart_identification == 1 )
    begin

            case (identification_cnt)

    			idle :
    					begin 
    					Tx = 1 ;
    					identification_cnt = start ;
    					end 
    
    			start : 
    					 begin 
    					 Tx = 0 ;
    					 identification_cnt = identification_data ;
    					 identification_data = identification_data + 1 ;
    					 end 
    
    			stop :
    					 begin 
    					 Tx = 1 ;
    					 identification_cnt = idle ;
    					 end 
    
    			terminate :
    						begin 
    						Tx = 1 ;
    						counter = 9'b00 ; 	
    						identification_cnt = idle ;	
    						identification_data = 5 ;
    						bit_counter = 4'b00 ;
                            flag_uart_pick = 1 ;
                            identification_cnt = 0 ;
    						end 
    
    			G_letter1 :
    						begin 
    						Tx = g_letter[bit_counter] ;
    						bit_counter = bit_counter + 1 ;
    						if (bit_counter == 4'b1000)
    						begin 
    						bit_counter = 0 ;
    						identification_cnt = stop  ;
    						end 
    						end 

                B_letter1 :
    						begin 
    						Tx = b_letter[bit_counter] ;
    						bit_counter = bit_counter + 1 ;
    						if (bit_counter == 4'b1000)
    						begin 
    						bit_counter = 0 ;
    						identification_cnt = stop  ;
    						end 
    						end 

                I_letter1 :
    						begin 
    						Tx = i_letter[bit_counter] ;
    						bit_counter = bit_counter + 1 ;
    						if (bit_counter == 4'b1000)
    						begin 
    						bit_counter = 0 ;
    						identification_cnt = stop  ;
    						end 
    						end 

                Block_number_1 :
    						begin 
    						Tx = block_number [block_select] [bit_counter] ;
    						bit_counter = bit_counter + 1 ;
    						if (bit_counter == 4'b1000)
    						begin 
    						bit_counter = 0 ;
    						identification_cnt = stop  ;
    						end 
    						end 

                Dash_1 :
    						begin 
    						Tx = dash_letter[bit_counter] ;
    						bit_counter = bit_counter + 1 ;
    						if (bit_counter == 4'b1000)
    						begin 
    						bit_counter = 0 ;
    						identification_cnt = stop  ;
    						end 
    						end 

                Waste_type_1 :
    						begin 
    						Tx = waste_type [waste_select] [bit_counter] ;
    						bit_counter = bit_counter + 1 ;
    						if (bit_counter == 4'b1000)
    						begin 
    						bit_counter = 0 ;
    						identification_cnt = stop  ;
    						end 
    						end 

                Dash_2 :
    						begin 
    						Tx = dash_letter[bit_counter] ;
    						bit_counter = bit_counter + 1 ;
    						if (bit_counter == 4'b1000)
    						begin 
    						bit_counter = 0 ;
    						identification_cnt = stop  ;
    						end 
    						end 

                Hash_1 :
    						begin 
    						Tx = hash_letter[bit_counter] ;
    						bit_counter = bit_counter + 1 ;
    						if (bit_counter == 4'b1000)
    						begin 
    						bit_counter = 0 ;
    						identification_cnt = stop  ;
    						end 
    						end 


                Null_1 :
    						begin 
    						Tx = null_letter[bit_counter] ;
    						bit_counter = bit_counter + 1 ;
    						if (bit_counter == 4'b1000)
    						begin 
    						bit_counter = 0 ;
    						identification_cnt = terminate  ;
    						end 
    						end 
          endcase 
    end 

   // state machine used when bot pick up  the block
    if ( flag_uart_pick == 1)
    begin

        case (pick_cnt)

    			idle :
    					begin 
    					Tx = 1 ;
    					pick_cnt = start ;
    					end 
    
    			start : 
    					 begin 
    					 Tx = 0 ;
    					 pick_cnt = pick_data ;
    					 pick_data = pick_data + 1 ;
    					 end 
    

    			stop :
    					 begin 
    					 Tx = 1 ;
    					 pick_cnt = idle ;
    					 end 
    

    			terminate :
    						begin 
    						Tx = 1 ;
    						counter = 9'b00 ; 	
    						pick_cnt = idle ;	
    						pick_data = 14;
    						bit_counter = 4'b00 ;
							flag_uart_pick = 0 ;
    						end 
    

    			G_letter2 :
    						begin 
    						Tx = g_letter[bit_counter] ;
    						bit_counter = bit_counter + 1 ;
    						if (bit_counter == 4'b1000)
    						begin 
    						bit_counter = 0 ;
    						pick_cnt = stop  ;
    						end 
    						end 

                B_letter2 :
    						begin 
    						Tx = b_letter[bit_counter] ;
    						bit_counter = bit_counter + 1 ;
    						if (bit_counter == 4'b1000)
    						begin 
    						bit_counter = 0 ;
    						pick_cnt = stop  ;
    						end 
    						end 


                Block_number_2 :
    						begin 
    						Tx = block_number [block_select] [bit_counter] ;
    						bit_counter = bit_counter + 1 ;
    						if (bit_counter == 4'b1000)
    						begin 
    						bit_counter = 0 ;
    						pick_cnt = stop  ;
    						end 
    						end 

                Dash_3 :
    						begin 
    						Tx = dash_letter[bit_counter] ;
    						bit_counter = bit_counter + 1 ;
    						if (bit_counter == 4'b1000)
    						begin 
    						bit_counter = 0 ;
    						pick_cnt = stop  ;
    						end 
    						end 


                Waste_type_2 :
    						begin 
    						Tx = waste_type [waste_select] [bit_counter] ;
    						bit_counter = bit_counter + 1 ;
    						if (bit_counter == 4'b1000)
    						begin 
    						bit_counter = 0 ;
    						pick_cnt = stop  ;
    						end 
    						end 

                Dash_4 :
    						begin 
    						Tx = dash_letter[bit_counter] ;
    						bit_counter = bit_counter + 1 ;
    						if (bit_counter == 4'b1000)
    						begin 
    						bit_counter = 0 ;
    						pick_cnt = stop  ;
    						end 
    						end 

                P_letter2 :
    						begin 
    						Tx = p_letter[bit_counter] ;
    						bit_counter = bit_counter + 1 ;
    						if (bit_counter == 4'b1000)
    						begin 
    						bit_counter = 0 ;
    						pick_cnt = stop  ;
    						end 
    						end 



                I_letter2 :
    						begin 
    						Tx = i_letter[bit_counter] ;
    						bit_counter = bit_counter + 1 ;
    						if (bit_counter == 4'b1000)
    						begin 
    						bit_counter = 0 ;
    						pick_cnt = stop  ;
    						end 
    						end 


                    
                C_letter2 :
    						begin 
    						Tx = c_letter[bit_counter] ;
    						bit_counter = bit_counter + 1 ;
    						if (bit_counter == 4'b1000)
    						begin 
    						bit_counter = 0 ;
    						pick_cnt = stop  ;
    						end 
    						end 




                K_letter2 :
    						begin 
    						Tx = k_letter[bit_counter] ;
    						bit_counter = bit_counter + 1 ;
    						if (bit_counter == 4'b1000)
    						begin 
    						bit_counter = 0 ;
    						pick_cnt = stop  ;
    						end 
    						end 




                Dash_5 :
    						begin 
    						Tx = dash_letter[bit_counter] ;
    						bit_counter = bit_counter + 1 ;
    						if (bit_counter == 4'b1000)
    						begin 
    						bit_counter = 0 ;
    						pick_cnt = stop  ;
    						end 
    						end 



                Hash_2 :
    						begin 
    						Tx = hash_letter[bit_counter] ;
    						bit_counter = bit_counter + 1 ;
    						if (bit_counter == 4'b1000)
    						begin 
    						bit_counter = 0 ;
    						pick_cnt = stop  ;
    						end 
    						end 



                Null_2 :
    						begin 
    						Tx = null_letter[bit_counter] ;
    						bit_counter = bit_counter + 1 ;
    						if (bit_counter == 4'b1000)
    						begin 
    						bit_counter = 0 ;
    						pick_cnt = terminate  ;
    						end 
    						end 

        endcase 
    end 

    // state machine used when bot dump the block
    if ( flag_dump == 1 )
    begin
       case (dump_cnt)

    			idle :
    					begin 
    					Tx = 1 ;
    					dump_cnt = start ;
    					end 
    
    			start : 
    					 begin 
    					 Tx = 0 ;
    					 dump_cnt = dump_data ;
    					 dump_data = dump_data + 1 ;
    					 end 
    
    			stop :
    					 begin 
    					 Tx = 1 ;
    					 dump_cnt = idle ;
    					 end 
    
    			terminate :
    						begin 
    						Tx = 1 ;
    						counter = 9'b00 ; 	
    						dump_cnt = idle ;	
    						dump_data = 27;
    						bit_counter = 4'b00 ;
							flag_dump = 0 ;
    						end 
    
    			G_letter31 :
    						begin 
    						Tx = g_letter[bit_counter] ;
    						bit_counter = bit_counter + 1 ;
    						if (bit_counter == 4'b1000)
    						begin 
    						bit_counter = 0 ;
    						dump_cnt = stop  ;
    						end 
    						end 

                B_letter3 :
    						begin 
    						Tx = b_letter[bit_counter] ;
    						bit_counter = bit_counter + 1 ;
    						if (bit_counter == 4'b1000)
    						begin 
    						bit_counter = 0 ;
    						dump_cnt = stop  ;
    						end 
    						end 


                Block_number_3 :
    						begin 
    						Tx = block_number [block_select] [bit_counter] ;
    						bit_counter = bit_counter + 1 ;
    						if (bit_counter == 4'b1000)
    						begin 
    						bit_counter = 0 ;
    						dump_cnt = stop  ;
    						end 
    						end 


                Dash_6 :
    						begin 
    						Tx = dash_letter[bit_counter] ;
    						bit_counter = bit_counter + 1 ;
    						if (bit_counter == 4'b1000)
    						begin 
    						bit_counter = 0 ;
    						dump_cnt = stop  ;
    						end 
    						end 

                Waste_type_3 :
    						begin 
    						Tx = waste_type [waste_select][bit_counter] ;
    						bit_counter = bit_counter + 1 ;
    						if (bit_counter == 4'b1000)
    						begin 
    						bit_counter = 0 ;
    						dump_cnt = stop  ;
    						end 
    						end 

                Dash_7 :
    						begin 
    						Tx = dash_letter[bit_counter] ;
    						bit_counter = bit_counter + 1 ;
    						if (bit_counter == 4'b1000)
    						begin 
    						bit_counter = 0 ;
    						dump_cnt = stop  ;
    						end 
    						end 

                G_letter32 :
    						begin 
    						Tx = g_letter[bit_counter] ;
    						bit_counter = bit_counter + 1 ;
    						if (bit_counter == 4'b1000)
    						begin 
    						bit_counter = 0 ;
    						dump_cnt = stop  ;
    						end 
    						end 



                D_letter31 :
    						begin 
    						Tx = d_letter[bit_counter] ;
    						bit_counter = bit_counter + 1 ;
    						if (bit_counter == 4'b1000)
    						begin 
    						bit_counter = 0 ;
    						dump_cnt = stop  ;
    						end 
    						end 


                    
                Z_letter3 :
    						begin 
    						Tx = z_letter[bit_counter] ;
    						bit_counter = bit_counter + 1 ;
    						if (bit_counter == 4'b1000)
    						begin 
    						bit_counter = 0 ;
    						dump_cnt = stop  ;
    						end 
    						end 




                Dump_zone_1 :
    						begin 
    						Tx = dump_zone [dump_select] [bit_counter] ;
    						bit_counter = bit_counter + 1 ;
    						if (bit_counter == 4'b1000)
    						begin 
    						bit_counter = 0 ;
    						dump_cnt = stop  ;
    						end 
    						end 




                Dash_8 :
    						begin 
    						Tx = dash_letter[bit_counter] ;
    						bit_counter = bit_counter + 1 ;
    						if (bit_counter == 4'b1000)
    						begin 
    						bit_counter = 0 ;
    						dump_cnt = stop  ;
    						end 
    						end 



                D_letter32 :
    						begin 
    						Tx = d_letter[bit_counter] ;
    						bit_counter = bit_counter + 1 ;
    						if (bit_counter == 4'b1000)
    						begin 
    						bit_counter = 0 ;
    						dump_cnt = stop  ;
    						end 
    						end 

                
                U_letter3 :
    						begin 
    						Tx = u_letter[bit_counter] ;
    						bit_counter = bit_counter + 1 ;
    						if (bit_counter == 4'b1000)
    						begin 
    						bit_counter = 0 ;
    						dump_cnt = stop  ;
    						end 
    						end 


                M_letter3 :
    						begin 
    						Tx = m_letter[bit_counter] ;
    						bit_counter = bit_counter + 1 ;
    						if (bit_counter == 4'b1000)
    						begin 
    						bit_counter = 0 ;
    						dump_cnt = stop  ;
    						end 
    						end 

                P_letter3 :
    						begin 
    						Tx = p_letter[bit_counter] ;
    						bit_counter = bit_counter + 1 ;
    						if (bit_counter == 4'b1000)
    						begin 
    						bit_counter = 0 ;
    						dump_cnt = stop  ;
    						end 
    						end 


                Null_3 :
    						begin 
    						Tx = null_letter[bit_counter] ;
    						bit_counter = bit_counter + 1 ;
    						if (bit_counter == 4'b1000)
    						begin 
    						bit_counter = 0 ;
    						dump_cnt = terminate  ;
    						end 
    						end 

    endcase 

    end 
	 
	if (counter == 9'b110110010)
	begin
	counter = 9'b0 ;
	end 
	counter = counter + 1 ;

end
end


end
endmodule 