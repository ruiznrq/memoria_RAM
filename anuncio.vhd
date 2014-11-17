LIBRARY IEEE;
USE  IEEE.STD_LOGIC_1164.all;
--USE  IEEE.STD_LOGIC_ARITH.all;
--USE  IEEE.STD_LOGIC_UNSIGNED.all;
USE  IEEE.numeric_std.all; -->Para hacer los incrementos de memoria

ENTITY anuncio IS
PORT
(	
	--Entradas que modifican el comportamiento
	k0_modo: IN		STD_LOGIC;
	k1_byte: IN		STD_LOGIC;
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
	Data_oD:	OUT 	STD_LOGIC_VECTOR (7 DOWNTO 0);  --8 bits de datos
	Data_oMEM:	OUT 	STD_LOGIC_VECTOR (7 DOWNTO 0)  --8 bits de datos
);
	
END anuncio;

ARCHITECTURE anuncio_arch OF anuncio IS

	--Señal de estado que indica el comportamiento del programa
	signal estado: integer range 0 to 2 :=0;  --Definimos 0=APAGADO (por seguridad), 1=ESCRIBIR y 2=LEER
	--Señal con los bytes leidos para sacarlos por dysplay
	signal display_s: STD_LOGIC_VECTOR(17 DOWNTO 0):="000000000000000000";
	--Señales que luego van a las salidas que conectan con memoria
	signal WrQ_s: 	STD_LOGIC				:='1';
	signal RdQ_s:	STD_LOGIC				:='1';
	signal UpB_s: 	STD_LOGIC				:='0';
	signal LoB_s: 	STD_LOGIC				:='1';
	signal WrE_s: 	STD_LOGIC				:='1';
	signal OuE_s: 	STD_LOGIC				:='1';
	signal CE_s:  	STD_LOGIC				:='1';
	signal Add_s: 	STD_LOGIC_VECTOR (17 DOWNTO 0) :="000000000000000000"; 	--8 bits de direccion

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

---Proceso que cambia display----------------
	process (k1_byte)
	begin		
		IF (k1_byte'event AND k1_byte='0') THEN
			IF (unsigned(Add_s)<7) THEN
				Add_s <= std_logic_vector( unsigned(Add_s) + 1 );
			ELSIF (unsigned(Add_s)=7) THEN
				Add_s <="000000000000000000";
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
	
	Data_oD<=Data_iSW when ((WrQ_s='0') AND (RdQ_s='1') AND (WrE_s='0') AND (OuE_s<='1')) else
				Datos_iMEM when ((WrQ_s='1') AND (RdQ_s='0') AND (WrE_s='1') AND (OuE_s<='0'));
				
	Data_oMEM<=Data_iSW when ((WrQ_s='0') AND (RdQ_s='1') AND (WrE_s='0') AND (OuE_s<='1')) else
					"ZZZZZZZZ" when ((WrQ_s='1') AND (RdQ_s='0') AND (WrE_s='1') AND (OuE_s<='0'));
---------------------------------------------------------------------------			
	
end architecture;
			
			
		 
			
				