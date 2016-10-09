
  ; Shift Register 
  
            INCLUDE 'MC9S08JM16.inc'
         
  ;*******************************Pin definition section
pin_LATCH EQU 1 ; to latch data in the output of the registers
pin_CLOCK EQU 2 ; to send the positive edges 
pin_DATA EQU 3 ; data to be displayed 	 
pin_Red EQU  0; common pin red color
pin_Green EQU 4 ; common pin green color
pin_Blue EQU 1; common pin blue color
ID_GY521 EQU  
  
            XDEF _Startup
            ABSENTRY _Startup

            ORG   Z_RAMStart       ; Insert your data definition here
data DS.B   2
counter DS.B 1 ; For colors
mode DS.B 1 ;  

            ORG    ROMStart
            
_Startup:   CLRA 
           	STA SOPT1 ; disenable watchdog
            LDHX   #RAMEnd+1        ; initialize the stack pointer
            TXS	

           	 		   
main:
			JSR initialconfig
			JSR initialstates
			JSR initIRQ
			;JSR initI2C
			JMP case9
			JMP *
            BRA    main
      
;******************************************Subroutine for set the initial configuration of the MCU            
initialconfig:
			BSET pin_LATCH,PTBDD ; Setting data direction (pin LATCH) 
			BSET pin_CLOCK,PTBDD ; Setting data direction (pin CLOCK)
			BSET pin_DATA,PTBDD ; Setting data direction (pin DATA)
			BSET pin_Green,PTBDD ; setting data direction (pin green)
			BSET pin_Red,PTBDD
			BSET pin_Blue,PTGDD
			RTS
			
;******************************************Subroutine for set the initial states of the pins and vars			
initialstates: 
			BCLR pin_LATCH,PTBD ; Initial state pin Latch
			BCLR pin_CLOCK,PTBD ; Initial state pin Clock
			BCLR pin_DATA,PTBD ; Initial state pin Data
			CLRA
			STA data+1 ; Initial State of LEDs Low_byte
			STA data+0 ; Initial State of LEDs High_byte
			STA counter
			STA mode ; mode 
			JSR showdata
			JSR changecolor
			RTS 
;*******************************************Subroutine for initialize IRQ
initIRQ:
			MOV #01110110B,IRQSC
			CLI  ; Enabling interrupts
			RTS
;*******************************************Subroutine for initialize I2C			
			 			     
;*******************************************Subroutine for show data in displays
showdata: 	
			PSHX 
			PSHA ; Save context
			LDA data+1 
			JSR sendbyte
			LDA data+0
			JSR sendbyte 
			JSR pulselatch
			PULA
			PULX
			RTS
	
sendbyte:	CLRX ; Nested subroutine for send a byte 
send8:	 	LSRA 
			BCS set1
			BCLR pin_DATA,PTBD
			BRA set2
set1:		BSET pin_DATA,PTBD			
set2:		INCX
			JSR pulseclock
			CPX #8
			BEQ endsend8
			BRA send8					 
endsend8:	RTS
			
pulseclock: ;Nested subroutine for send a pulse clock
		  	BSET pin_CLOCK,PTBD
		  	BCLR pin_CLOCK,PTBD
			RTS	
			
pulselatch: ;Nested subroutine for latch the data that has been sent
			BSET pin_LATCH,PTBD
		  	BCLR pin_LATCH,PTBD
			RTS	
			
;**********************************************************************CASES			
case0:;/////////////////////////////////////////////CASE 0
			CLRA 
		    STA data+1
		    STA data+0
		    JSR showdata
		    JMP case0   ;wait for an interruption
case1:;/////////////////////////////////////////////CASE 1
			LDA #0FFH
			STA data
			STA data+1
		    JSR showdata
		    JSR changecolor
		    JSR delayAx5ms ; delay of 300ms
		    JMP case1   ;wait for an interruption
case2:;////////////////////////////////////////////CASE  2
			CLRA
			STA data+1
			LDA #1
			STA data
case2_1:    JSR showdata
    		JSR delayAx5ms ; delay of 300ms
    		JSR rrsdata2 
    		BRCLR  7,data,case2_1
		   	JSR changecolor
    		BRA case2_1
    		
case3:;/////////////////////////////////////////////CASE 3
			CLRA 
		    STA data
		    LDA #80H
		    STA data+1
case3_1:    JSR showdata
		    JSR  delayAx5ms
		    JSR rlsdata2 
		    BRCLR  7,data,case3_1
		   	JSR changecolor
		    BRA case3_1 
     
case4:;/////////////////////////////////////////////CASE 4
		    CLRA ; A count 14
		    LDA #1
		    STA data
		    LDA #80H
		    STA data+1
case4_1: 	JSR showdata
		    JSR changecolor
		    JSR  delayAx5ms
		    INCA
		    CBEQA #8,case4_3
		    BRA case4_2
case4_2:	LSR data+1
			BCC c4_2 
			BSET 7,data+1
c4_2:   	LSL data
			BCC case4_1
			BSET 0,data
		    BRA case4_1
case4_3:	LSR data
			BCC c4_3 
			BSET 7,data
c4_3:   	LSL data+1
			BCC c4_31 
			BSET 0,data+1
c4_31:   	CBEQA #0EH,case4
    		BRA case4_1
    
case5:;/////////////////////////////////////////////////CASE 5
		    CLRA
		    STA data+1
		    LDA #1
		    STA data
case5_1:	JSR showdata
		    JSR  delayAx5ms   
		    JSR rrsdata2 
		    JSR rrsdata2
		    JSR changecolor
		    BRA case5_1
		    
case6:;/////////////////////////////////////////////////CASE 6
			CLRA
		    STA data
		    LDA #80H
		    STA data+1
case6_1:	JSR showdata
		    JSR delayAx5ms    
		    JSR rlsdata2 
		    JSR rlsdata2
		    JSR changecolor
		    BRA case6_1
		    
case7:;////////////////////////////////////////////////CASE 7
		    LDA #0AAH
		    STA data
		    STA data+1
case7_1:	JSR showdata
		    JSR delayAx5ms
		    COM data
		    COM data+1
		    JSR changecolor
		    BRA case7_1

		        
case8:;////////////////////////////////////////////////CASE 8
		    LDA #1
		    STA data
		    CLRX ; X counts 15
		    CLRA  
		    STA data+1
		    JSR showdata
case8_1:    LDA #1
		    LSRA ; C=1 
	   		ROL data
	   	    BCC c8_1 
c8_1:       ROL data+1
   		    INCX
	        CBEQX #10H,c8_12
   		    BRA case8_2
c8_12: 		CLRX
case8_3:     
     		LSR data+1
   		    BCS c8_3
     		ROR data
c8_3:  		INCX
    	    CBEQX #0FH,c8_31
     		BRA case8_4
c8_31: 	    CLRX
			JSR changecolor
     		BRA case8_2
case8_2:    JSR delayAx5ms
    		JSR showdata
    		BRA case8_1
case8_4:    JSR delayAx5ms
    		JSR showdata
   		    BRA case8_3
    
case9:;////////////////////////////////////////////////CASE 9
		    CLRA
		    STA data+1
		    CLRX ; X counts 15
		    LDA #80H  
		    STA data
		    JSR showdata
case9_1:    LDA #1
		    LSRA ; C=1 
	   		ROR data
	   	    BCC c9_1 
c9_1:       ROR data+1
   		    INCX
	        CBEQX #10H,c9_12
   		    BRA case9_2
c9_12: 		CLRX
			JSR changecolor
case9_3:     
     		LSL data+1
   		    BCS c9_3
     		ROL data
c9_3:  		INCX
    	    CBEQX #0FH,c9_31
     		BRA case9_4
c9_31: 	    CLRX
     		BRA case9_2
case9_2:    JSR delayAx5ms
    		JSR showdata
    		BRA case9_1
case9_4:    JSR delayAx5ms
    		JSR showdata
   		    BRA case9_3
   		        
        
;******************************************Subroutine to rotate right 16 bit register    						
rrsdata2:
	LSR data
	ROR data+1
	BCC endrr
	BSET 7,data 
endrr:	RTS		
		
;******************************************Subroutine to rotate right 16 bit register    						
rlsdata2:
	LSL data+1
	ROL data
	BCC endrl
	BSET 0,data+1 
endrl:	RTS	
		 	
;******************************************Subroutine for change of colors
changecolor:
			PSHA
			INC counter
			LDA counter
			CBEQA #1,blue
			CBEQA #2,red
			CBEQA #3,green
			CBEQA #4,aqua
			CBEQA #5,rose
			CBEQA #6,orange
			LDA #1
			STA counter
			BRA blue
			RTS 
blue:
			BCLR pin_Green,PTBD ; Turn off LEDs green
			BSET pin_Blue,PTGD ; Turn ON LEDs blue
			BCLR pin_Red,PTBD ; Turn off LEDs red	
			PULA
			RTS
red:
			BCLR pin_Green,PTBD ; Turn off LEDs green
			BCLR pin_Blue,PTGD ; Turn off LEDs blue
			BSET pin_Red,PTBD ; Turn ON LEDs red	
			PULA
			RTS
green:
			BSET pin_Green,PTBD ; Turn ON LEDs green
			BCLR pin_Blue,PTGD ; Turn off LEDs blue
			BCLR pin_Red,PTBD ; Turn off LEDs red	
			PULA
			RTS
aqua:
			BSET pin_Green,PTBD ; Turn ON LEDs green
			BSET pin_Blue,PTGD ; Turn ON LEDs blue
			BCLR pin_Red,PTBD ; Turn off LEDs red	
			PULA
			RTS
rose:
			BCLR pin_Green,PTBD ; Turn off LEDs green
			BSET pin_Blue,PTGD ; Turn ON LEDs blue
			BSET pin_Red,PTBD ; Turn ON LEDs red	
			PULA
			RTS
orange:
			BSET pin_Green,PTBD ; Turn ON LEDs green
			BCLR pin_Blue,PTGD ; Turn off LEDs blue
			BSET pin_Red,PTBD ; Turn ON LEDs red	
			PULA
			RTS			
			 	
;******************************************Subroutine for crete delays 8MHz
delayAx5ms: ; 6 cycles the call of subroutine
			PSHX
			PSHA
			LDA #20D ; 2 cycles
delay_2:    LDHX #1387H ; 3 cycles 
delay_1:    AIX #-1 ; 2 cycles
	    	CPHX #0 ; 3 cycles  
			BNE delay_1 ; 3 cycles
			DECA ;1 cycle
			CMP #0 ; 2 cycles
			BNE delay_2  ;3 cycles
			PULA
			PULX
			RTS ; 5 cycles				     
			
;*********************************************Routine for IRQ
ISR_IRQ:
			PULA ; Throw CCR away
			PULA ; Throw A away
			PULA ; Throw X away
			PULA ; Throw PCH away 
			PULA ; Throw PCL away
			
			JSR delayAx5ms ; Antidebouncing

			INC mode 
			LDA mode
			CBEQA #1,rcase0
			CBEQA #2,rcase1
			CBEQA #3,rcase2
			CBEQA #4,rcase3
			CBEQA #5,rcase4
			CBEQA #6,rcase5
			CBEQA #7,rcase6
			CBEQA #8,rcase7
			CBEQA #9,rcase8
			CBEQA #10,rcase9
			CLR mode ;else
			BRA ISR_IRQ
	;JMP *
rcase0:		LDHX #case0
			BRA SALIR
rcase1:		LDHX #case1
			BRA SALIR
rcase2:		LDHX #case2
			BRA SALIR
rcase3:		LDHX #case3
			BRA SALIR
rcase4:		LDHX #case4
			BRA SALIR
rcase5:		LDHX #case5
			BRA SALIR
rcase6:		LDHX #case6
			BRA SALIR
rcase7:		LDHX #case7
			BRA SALIR
rcase8:		LDHX #case8
			BRA SALIR
rcase9:		LDHX #case9
			BRA SALIR


SALIR:	   	PSHX  
			PSHH
			CLRA
			PSHA
			PSHA
			PSHA
		    BSET 2,IRQSC ; clearing flag
			RTI
			
;*********************************************************INTERRUPT VECTORS						
			ORG Virq
			DC.W ISR_IRQ			;External interrupt
            ORG Vreset
			DC.W  _Startup			; Reset
