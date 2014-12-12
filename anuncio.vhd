LIBRARY IEEE;
USE  IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_UNSIGNED.all;

ENTITY anuncio IS
PORT
(	
	--Entradas que modifican el comportamiento
	clk:			IN		STD_LOGIC;
	k0_modo: 	IN		STD_LOGIC; --Cambio lectura/escritura
	k1_byte: 	IN		STD_LOGIC; --Cambio display
	k2_msg:		IN		STD_LOGIC; --Cambio de mensaje
	--Entradas datos
	Datos_iMEM:	IN		STD_LOGIC_VECTOR (7 DOWNTO 0); --Datos desde RAM
	Data_iSW:	IN    STD_LOGIC_VECTOR (7 DOWNTO 0); --Datos desde SW
	--Salidas que conectan a memoria
	WrQ: OUT		STD_LOGIC;
	RdQ: OUT		STD_LOGIC;
	UpB: OUT		STD_LOGIC;
	LoB: OUT		STD_LOGIC;
	WrE: OUT		STD_LOGIC;
	OuE: OUT		STD_LOGIC;
	CE:  OUT		STD_LOGIC;
	Add: OUT 	STD_LOGIC_VECTOR (17 DOWNTO 0);
	Data_oMEM:	OUT 	STD_LOGIC_VECTOR (7 DOWNTO 0);  --8 bits de datos a memoria (usamos 3 bajos para cada msg)
	--Salidas visualización
	LedG_o: OUT	STD_LOGIC_VECTOR (7 DOWNTO 0); --Muestran direccion
	LedR_o: OUT STD_LOGIC_VECTOR (17 DOWNTO 0); --Muestran dato leido (para depurar en placa)
	Disp_o: OUT STD_LOGIC_VECTOR (31 DOWNTO 0) --Salida a displays
);
	
END anuncio;

ARCHITECTURE anuncio_arch OF anuncio IS

	--Señal de estado que indica el comportamiento del programa
	signal estado: integer range 0 to 2 :=0;  --Definimos 0=APAGADO (EN's a '1'), 1=ESCRIBIR y 2=LEER
	--Señales intermedias antes de Disp_o (para almacenamiento)
	signal display_s: STD_LOGIC_VECTOR(31 DOWNTO 0):="00000000000000000000000000000000"; --Almacenamiento
	signal display_rotar: STD_LOGIC_VECTOR(31 DOWNTO 0):="00000000000000000000000000000000"; --Esta se rota
	--Señal inicialización de los led rojos:
	signal LedR_o_s: STD_LOGIC_VECTOR(17 DOWNTO 0):="000000000000000000";
	--Señales que luego van a las salidas que conectan con memoria
	signal WrQ_s: 	STD_LOGIC				:='1';
	signal RdQ_s:	STD_LOGIC				:='1';
	--signal UpB_s: 	STD_LOGIC				:='0';
	--signal LoB_s: 	STD_LOGIC				:='1';
	signal WrE_s: 	STD_LOGIC				:='1';
	signal OuE_s: 	STD_LOGIC				:='1';
	signal CE_s:  	STD_LOGIC				:='1';
	signal Add_s: 	STD_LOGIC_VECTOR (17 DOWNTO 0) :="000000000000000000"; 	--8 bits de direccion
	--Señal auxiliar: en escritura se corresponde con k1, en lectura es un reloj.
	signal k1_s: 	STD_LOGIC 				:='1';

begin

---Proceso que cambia el estado----------------
	process (k0_modo) --pasar a stdlogic --> No arreglo nada (menos las advertencias sobre ledr_o)
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
	variable cont: integer range 0 to 50:=0;
	begin
		IF (clk'event AND clk='1') THEN
			IF ((estado = 1) OR (estado=0)) THEN  --Si estamos en escritura o apagado
				k1_s <= k1_byte;  --La señal se corrsponde con el KEY1
			ELSIF (estado = 2) THEN --Si estamos en lectura, la señal es un reloj.
				IF (cont = 1) THEN
					k1_s <= '0';	--Lo bajamos al empezar, durante 10 ciclos (en la bajada cambia addr)			
				ELSIF (cont = 10) THEN
					k1_s <= '1';	--Lo levantamos a los 40 ciclos (tiempo de espera despues de cambiar addr)
				ELSIF (cont = 50) THEN
					cont := 0;
				END IF;
				cont := cont + 1;
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

---Proceso que hace muchas cosas----------------
	process (k1_s)
	variable numDis: integer range 0 to 8:=0; --Contador de 8 displays, cuando llega a 8 paramos de leer
	variable reiniciar: STD_LOGIC := '0';
	variable display_aux: STD_LOGIC_VECTOR(31 DOWNTO 0):="00000000000000000000000000000000"; --Aqui se va almacenando lo leido de RAM, luego se rota en otra señal
	variable add_alta:	STD_LOGIC_VECTOR(3 DOWNTO 0):= "0000";	--Copia para ver si cambia el mensaje
	variable est_ant: integer range 0 to 2:=0; --Copia para ver si cambia el estado
	variable contador: integer range 0 to 1000000 := 0; --Contador de la rotacion -> 1s aprox.
	begin		
		--Cuando hay flanco bajo, aumentamos addr (se mantiene bajo unos ciclos de reloj)
		IF (k1_s'event AND k1_s='0') THEN
			IF (Add_s(2 DOWNTO 0)<"111") THEN
				Add_s(2 DOWNTO 0)<=Add_s(2 DOWNTO 0)+1;
			ELSIF (Add_s(2 DOWNTO 0)="111") THEN --OR ((NOT(add_alta = Add_s(6 DOWNTO 3))) OR (NOT(est_ant = estado))) THEN --Si cambia el mensaje o el estado, reiniciamos al primer display
				Add_s(2 DOWNTO 0)<="000";
			END IF;
			--Si el mensaje cambia, empezamos a leer de nuevo:
			IF ((NOT(add_alta = Add_s(6 DOWNTO 3))) OR (NOT(est_ant = estado))) THEN
				reiniciar := '1';
			ELSE
				reiniciar := '0';
			END IF;
			add_alta := Add_s(6 DOWNTO 3);
			est_ant := estado;
		--Cuado tenemos flanco subida (y lectura):
		ELSIF ((k1_s'event AND k1_s='1') AND (estado = 2)) THEN --Esto solo se ejecuta en lectura
			--Si quedan posiciones de RAM a leer, las guardamos en display_aux
			IF (reiniciar='1') THEN
				numDis := 0;
			END IF;
			IF (numDis <=7) THEN
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
			contador := contador + 1;
			--Si se han leido las 8 posiciones, y ha pasado 1 segundo aprox, rotamos
			IF (numDis = 8) AND (contador = 1000000) THEN
				contador := 0;
				display_rotar <= display_aux(27 downto 0) & display_aux(31 downto 28);
				display_aux := display_aux(27 downto 0) & display_aux(31 downto 28);-----------> Esto ARREGLÓ lo del parpadeo de 0's durante la rotación
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
	
	UpB<='0';
	
	LoB<='1';
	
	Add<=Add_s;
				
	Data_oMEM<=Data_iSW when ((WrQ_s='0') AND (RdQ_s='1') AND (WrE_s='0') AND (OuE_s<='1')) else --Aqui podría haber puesto estado como condición, pero es lo mismo...
					"ZZZZZZZZ" when ((WrQ_s='1') AND (RdQ_s='0') AND (WrE_s='1') AND (OuE_s<='0'));
---------------------------------------------------------------------------			

---Asignación del LEDs----------------------------------------------------------------	
	--En los LED verdes mostramos la direccion
	LedG_o(6 DOWNTO 0) <= Add_s(6 DOWNTO 0);
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
	ledG_o(7) <= k1_s; --Para depurar
-------------------------------------------------------------------------------------------	

---Asignacion de Displays----------------------------------------------------------------------- 
	display_s(3 DOWNTO 0) <=  Data_iSW(3 DOWNTO 0) when ((estado=1) AND (Add_s(2 DOWNTO 0)="000")) else 
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