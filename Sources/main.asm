
  ; Shift Register 
  
            INCLUDE 'derivative.inc'
         
  ;*******************************Pin definition section
pin_LATCH EQU 1 ; to latch data in the output of the registers
pin_CLOCK EQU 2 ; to send the positive edges 
pin_DATA EQU 3 ; data to be displayed 	  
  
            XDEF _Startup
            ABSENTRY _Startup

            ORG    RAMStart         ; Insert your data definition here
data DS.B   2


            ORG    ROMStart
            
_Startup:
            LDHX   #RAMEnd+1        ; initialize the stack pointer
            TXS	
           	CLRA 
           	STA SOPT1 ; disenable watchdog
           	 		   
main:
			JSR initialconfig
			JSR initialstates
			JMP *
            BRA    main
      
;******************************************Subroutine for set the initial configuration of the MCU            
initialconfig:
			BSET pin_LATCH,PTBDD ; Setting data direction (pin LATCH) 
			BSET pin_CLOCK,PTBDD ; Setting data direction (pin CLOCK)
			BSET pin_DATA,PTBDD ; Setting data direction (pin DATA)
			RTS
			
;******************************************Subroutine for set the initial states of the pins and vars			
initialstates: 
			BCLR pin_LATCH,PTBD ; Initial state pin Latch
			BCLR pin_CLOCK,PTBD ; Initial state pin Clock
			BCLR pin_DATA,PTBD ; Initial state pin Data
			CLRA
			LDA #0EAH
			STA data+1 ; Initial State of LEDs Low_byte
			STA data+0 ; Initial State of LEDs High_byte
			JSR showdata
			JSR pulselatch
			RTS      
;*******************************************Subroutine for show data in displays
showdata: 	
			LDA data+1 
			JSR sendbyte
			LDA data+0
			JSR sendbyte 
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
		  	PSHA
		  	PSHX 
		  	LDA #1 
		  	JSR delayAx5ms
		  	BCLR pin_CLOCK,PTBD
		  	PULX
		  	PULA
			RTS	
			
pulselatch: ;Nested subroutine for latch the data that has been sent
			BSET pin_LATCH,PTBD
		  	PSHA
		  	PSHX 
		  	LDA #1 
		  	JSR delayAx5ms			
		  	BCLR pin_LATCH,PTBD
		  	PULX
		  	PULA
			RTS				
				 	
;******************************************Subroutine for crete delays 8MHz
delayAx5ms: ; 6 cycles the call of subroutine
			;LDA #60D ; 2 cycles
delay_2:    LDHX #1387H ; 3 cycles 
delay_1:    AIX #-1 ; 2 cycles
	    	CPHX #0 ; 3 cycles  
			BNE delay_1 ; 3 cycles
			DECA ;1 cycle
			CMP #0 ; 2 cycles
			BNE delay_2  ;3 cycles
			RTS ; 5 cycles				     
			
            ORG Vreset
			DC.W  _Startup			; Reset
