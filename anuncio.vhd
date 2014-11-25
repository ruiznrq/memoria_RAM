LIBRARY IEEE;
USE  IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_UNSIGNED.all;

ENTITY anuncio IS
PORT
(	
	--Entradas que modifican el comportamiento
	clk:			IN		STD_LOGIC;
	k0_modo: 	IN		STD_LOGIC;
	k1_byte: 	IN		STD_LOGIC;
	k2_msg:		IN		STD_LOGIC;
	Datos_iMEM:	IN		STD_LOGIC_VECTOR (7 DOWNTO 0); --Datos para leer
	Data_iSW:	IN    STD_LOGIC_VECTOR (7 DOWNTO 0); --Datos para escribir
	--Salidas que conectan a memoria
	WrQ: OUT		STD_LOGIC;
	RdQ: OUT		STD_LOGIC;
	UpB: OUT		STD_LOGIC;
	LoB: OUT		STD_LOGIC;
	WrE: OUT		STD_LOGIC;
	OuE: OUT		STD_LOGIC;
	CE:  OUT		STD_LOGIC;
	Add: OUT 	STD_LOGIC_VECTOR (17 DOWNTO 0); --3 bits de direccion
	Data_oMEM:	OUT 	STD_LOGIC_VECTOR (7 DOWNTO 0);  --8 bits de datos a memoria
	--Salidas visualización
	LedG_o: OUT	STD_LOGIC_VECTOR (7 DOWNTO 0);
	LedR_o: OUT STD_LOGIC_VECTOR (17 DOWNTO 0);
	Disp_o: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
);
	
END anuncio;

ARCHITECTURE anuncio_arch OF anuncio IS

	--Señal de estado que indica el comportamiento del programa
	signal estado: integer range 0 to 2 :=0;  --Definimos 0=APAGADO (por seguridad), 1=ESCRIBIR y 2=LEER
	--Señal con los bytes leidos para sacarlos por dysplay
	signal display_s: STD_LOGIC_VECTOR(31 DOWNTO 0):="00000000000000000000000000000000";
	signal display_rotar: STD_LOGIC_VECTOR(31 DOWNTO 0):="00000000000000000000000000000000";
	signal LedR_o_s: STD_LOGIC_VECTOR(17 DOWNTO 0):="000000000000000000";
	--Señales que luego van a las salidas que conectan con memoria
	signal WrQ_s: 	STD_LOGIC				:='1';
	signal RdQ_s:	STD_LOGIC				:='1';
	signal UpB_s: 	STD_LOGIC				:='0';
	signal LoB_s: 	STD_LOGIC				:='1';
	signal WrE_s: 	STD_LOGIC				:='1';
	signal OuE_s: 	STD_LOGIC				:='1';
	signal CE_s:  	STD_LOGIC				:='1';
	signal Add_s: 	STD_LOGIC_VECTOR (17 DOWNTO 0) :="000000000000000000"; 	--8 bits de direccion
	--Señales auxiliares para lectura
	signal k1_s: 	STD_LOGIC 				:='1';

begin

---Proceso que cambia el estado----------------
	process (k0_modo)
	begin		
		IF (k0_modo'event AND k0_modo='0') THEN
			IF ((estado=0)OR(estado=2)) THEN
				estado <= 1;
			ELSIF (estado=1) THEN
				estado <= 2;
			END IF;
		END IF;	
	END process;
-----------------------------------------------

---Proceso de reloj-------------------------------
	process (clk)
	variable cont: integer range 0 to 5:=0;
	begin
		IF (clk'event AND clk='1') THEN
			IF ((estado = 1) OR (estado=0)) THEN
				k1_s <= k1_byte;
			ELSIF (estado = 2) THEN
				IF (cont = 0) THEN
					k1_s <= '0';					
				ELSIF (cont = 3) THEN
					k1_s <= '1';
				ELSIF (cont = 5) THEN
					cont := 0;
				END IF;
				cont := cont + 1;
			END IF;
		END IF;	
	END process;
-----------------------------------------------

---Proceso que cambia display----------------
	process (k1_s)
	variable numDis: integer range 0 to 8:=0; --8 displays, cuando llega a 8 paramos
	variable display_aux: STD_LOGIC_VECTOR(31 DOWNTO 0):="00000000000000000000000000000000";
	variable add_alta:	STD_LOGIC_VECTOR(3 DOWNTO 0):= "0000";
	variable contador: integer range 0 to 1000000 := 0;
	variable aux: STD_LOGIC_VECTOR(3 DOWNTO 0) := "0000";
	variable aux2: STD_LOGIC_VECTOR(27 downto 0) := "0000000000000000000000000000";
	begin		
		--Si el mensaje cambia, empezamos a leer de nuevo:
		add_alta := Add_s(6 DOWNTO 3);
		IF (NOT(add_alta = Add_s(6 DOWNTO 3))) THEN
			numDis := 0;
		END IF;
		--Cuando hay flanco bajo, aumentamos addr, se mantiene bajo 3 ciclos de reloj:
		IF (k1_s'event AND k1_s='0') THEN
			IF (Add_s(2 DOWNTO 0)<"111") THEN
				Add_s(2 DOWNTO 0)<=Add_s(2 DOWNTO 0)+1;
			ELSIF (Add_s(2 DOWNTO 0)="111") THEN
				Add_s(2 DOWNTO 0)<="000";
			END IF;
		--Cuado tenemos flanco subida, si estamos en lectura, leemos 8 veces en display_aux
		ELSIF ((k1_s'event AND k1_s='1') AND (estado = 2) AND (numDis <=7)) THEN --Esto solo se eecuta en lectura
			IF (Add_s(2 DOWNTO 0)="000") THEN
				display_aux(3 DOWNTO 0) := Datos_iMEM(3 DOWNTO 0);
			ELSIF (Add_s(2 DOWNTO 0)="001") THEN
				display_aux(7 DOWNTO 4) := Datos_iMEM(3 DOWNTO 0);
			ELSIF (Add_s(2 DOWNTO 0)="010") THEN
				display_aux(11 DOWNTO 8) := Datos_iMEM(3 DOWNTO 0);
			ELSIF (Add_s(2 DOWNTO 0)="011") THEN
				display_aux(15 DOWNTO 12) := Datos_iMEM(3 DOWNTO 0);
			ELSIF (Add_s(2 DOWNTO 0)="100") THEN
				display_aux(19 DOWNTO 16) := Datos_iMEM(3 DOWNTO 0);
			ELSIF (Add_s(2 DOWNTO 0)="101") THEN
				display_aux(23 DOWNTO 20) := Datos_iMEM(3 DOWNTO 0);
			ELSIF (Add_s(2 DOWNTO 0)="110") THEN
				display_aux(27 DOWNTO 24) := Datos_iMEM(3 DOWNTO 0);
			ELSIF (Add_s(2 DOWNTO 0)="111") THEN
				display_aux(31 DOWNTO 28) := Datos_iMEM(3 DOWNTO 0);
			END IF;
			numDis := numDis + 1;
		END IF;
		--Si estamos en lectura, contamos un segundo (un millon, ya se conto 5 antes), si en ese segundo se han leido todos los displays, rotamos:
		IF (estado = 2) THEN
			contador := contador + 1;
			IF (numDis = 8) AND (contador = 1000000) THEN
				contador := 0;
				aux := display_aux(31 downto 28);
				aux2:= display_aux(27 downto 0);
				display_rotar <= aux2 & aux;
			END IF;
		END IF;			
	END process;
-----------------------------------------------

---Proceso que cambia mensaje----------------
	process (k2_msg)
	begin		
		IF (k2_msg'event AND k2_msg='0') THEN
			IF (Add_s(6 DOWNTO 3)<"0010") THEN
				--Add_s <= std_logic_vector( unsigned(Add_s) + 1 );
				Add_s(6 DOWNTO 3)<=Add_s(6 DOWNTO 3)+1;
			ELSIF (Add_s(6 DOWNTO 3)="0010") THEN
				Add_s(6 DOWNTO 3)<="0000";
			END IF;
		END IF;	
	END process;
-----------------------------------------------

---Asignación de señales intermedias según estado---------
	WrQ_s<='0' when (estado=1) else
		    '1';
	RdQ_s<='0' when (estado=2) else
		    '1';
	WrE_s<='0' when (estado=1) else
		    '1';
	OuE_s<='0' when (estado=2) else
		    '1';
	CE_s<= '0' when ((estado=1) OR (estado=2)) else
		    '1';
	--UpB_s<= '0' when (estado=1) else
	--	    '1';
	--LoB_s<= '1' when (estado=2) else
	--	    '0';			 
-----------------------------------------------------------

---Asignación de salidas en función de señales intermedias por seguridad---     -->¿Realmente tiene sentido? No se debería hacer fuera?
	WrQ<='0' when ((WrE_s='0') AND (OuE_s<='1')) else
		  '1';
		  
	RdQ<='0' when ((WrE_s='1') AND (OuE_s<='0')) else
		  '1';
		  
	WrE<='0' when ((WrQ_s='0') AND (RdQ_s='1') AND ((WrE_s='0') AND (OuE_s<='1'))) else
		  '1';
		  
	OuE<='0' when ((WrQ_s='1') AND (RdQ_s='0') AND ((WrE_s='1') AND (OuE_s<='0'))) else
		  '1';
		  
	CE<=CE_s; --Sobre CE no establecemos medidas de seguridad, el chip se mantiene encendido.
	
	UpB<=UpB_s;
	
	LoB<=LoB_s;
	
	Add<=Add_s;
				
	Data_oMEM<=Data_iSW when ((WrQ_s='0') AND (RdQ_s='1') AND (WrE_s='0') AND (OuE_s<='1')) else
					"ZZZZZZZZ" when ((WrQ_s='1') AND (RdQ_s='0') AND (WrE_s='1') AND (OuE_s<='0'));
---------------------------------------------------------------------------			

---Asignación del LEDs----------------------------------------------------------------	
	--En los LED verdes mostramos la direccion
	LedG_o <= Add_s(7 DOWNTO 0);
	--En los led rojos mostramos el display escrito o el dato que se esta leyendo
	LedR_o_s <= "100000000000000000" when ((Add_s(2 DOWNTO 0)="111") AND (estado=1)) else
				   "010000000000000000" when ((Add_s(2 DOWNTO 0)="110") AND (estado=1)) else
				   "000100000000000000" when ((Add_s(2 DOWNTO 0)="101") AND (estado=1)) else	
				   "000001000000000000" when ((Add_s(2 DOWNTO 0)="100") AND (estado=1)) else
					"000000010000000000" when ((Add_s(2 DOWNTO 0)="011") AND (estado=1)) else
				   "000000001000000000" when ((Add_s(2 DOWNTO 0)="010") AND (estado=1)) else	
				   "000000000100000000" when ((Add_s(2 DOWNTO 0)="001") AND (estado=1)) else
					"000000000001000000" when ((Add_s(2 DOWNTO 0)="000") AND (estado=1)) else
					"000000000000000000" when ((estado=0));
	LedR_o(7 DOWNTO 0) <= Datos_iMEM when ((estado = 2)) else
								 LedR_o_s(7 DOWNTO 0) when ((estado = 1) OR (estado = 0));
	LedR_o(17 DOWNTO 8) <= "0000000000" when ((estado = 2)) else
								  LedR_o_s(17 DOWNTO 8) when ((estado = 1) OR (estado = 0));
-------------------------------------------------------------------------------------------	

---Asignacion de Displays----------------------------------------------------------------------- 
	display_s(3 DOWNTO 0) <= Data_iSW(3 DOWNTO 0) when ((estado=1) AND (Add_s(2 DOWNTO 0)="000")) else
									 display_rotar(3 DOWNTO 0) when (estado=2);
	display_s(7 DOWNTO 4) <= Data_iSW(3 DOWNTO 0) when ((estado=1) AND (Add_s(2 DOWNTO 0)="001")) else
									 display_rotar(7 DOWNTO 4) when (estado=2);
	display_s(11 DOWNTO 8) <= Data_iSW(3 DOWNTO 0) when ((estado=1) AND (Add_s(2 DOWNTO 0)="010")) else
									 display_rotar(11 DOWNTO 8) when (estado=2);
	display_s(15 DOWNTO 12) <= Data_iSW(3 DOWNTO 0) when ((estado=1) AND (Add_s(2 DOWNTO 0)="011")) else
									 display_rotar(15 DOWNTO 12) when (estado=2);
	display_s(19 DOWNTO 16) <= Data_iSW(3 DOWNTO 0) when ((estado=1) AND (Add_s(2 DOWNTO 0)="100")) else
									 display_rotar(19 DOWNTO 16) when (estado=2);
	display_s(23 DOWNTO 20) <= Data_iSW(3 DOWNTO 0) when ((estado=1) AND (Add_s(2 DOWNTO 0)="101")) else
									 display_rotar(23 DOWNTO 20) when (estado=2);
	display_s(27 DOWNTO 24) <= Data_iSW(3 DOWNTO 0) when ((estado=1) AND (Add_s(2 DOWNTO 0)="110")) else
									 display_rotar(27 DOWNTO 24) when (estado=2);	
	display_s(31 DOWNTO 28) <= Data_iSW(3 DOWNTO 0) when ((estado=1) AND (Add_s(2 DOWNTO 0)="111")) else
									 display_rotar(31 DOWNTO 28) when (estado=2); 
		
	Disp_o <= display_s;
------------------------------------------------------------------------------------------------
					
	
end architecture;
			
			
		 
			
				