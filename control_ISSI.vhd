LIBRARY IEEE;
USE  IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_UNSIGNED.all;

-- Este bloque tan sólo pretende ser un sistema de seguridad para evitar asignaciones
--incorrectas de valores a pines que pudieran provocar daños físicos. Estas
--situaciones, dadas las características de las memorias, se resumen en asignar un valor
--a los pines de datos desde fuera cuando, al mismo tiempo, se solicita a la memoria
--el valor almacenado en un registro. En ese caso, se produciría un corto caso de que el valor
--que se fuerza desde fuera y el valor que suministra la memoria difieran.

--Por ello, en este bloque el puerto de direcciones y datos accesible al sistema del usuario aparece
--desdoblado en dos. Cada puerto gemelo es sólo de entrada (_I) o de salida (_O) y no INOUT, que es
--el modelo de pin que puede generar problemas. El puerto de conexión a la memoria (_M) sí es de tipo
--INOUT, pero su conexión con uno u otro puerto del lado accesible al usuario sólo se produce cuando
--los pines READ_QUERY y WRITE_QUERY están bien configurados, lo que evita conexiones incorrectas.
 
--El resto de pines son reflejo fiel de los pines de control del chip de memoria.

ENTITY mem_control IS
PORT
(	
	D_M:	INOUT STD_LOGIC_VECTOR (15 DOWNTO 0);
	--D_M_LED: OUT	STD_LOGIC;
	D_O:	OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
	--D_O_LED: OUT STD_LOGIC;
	D_I:	IN STD_LOGIC_VECTOR (15 DOWNTO 0);
	ADDRESS_M:	OUT STD_LOGIC_VECTOR (17 DOWNTO 0);
	--ADDR_LED: OUT	STD_LOGIC;
	ADDRESS_I:	IN	STD_LOGIC_VECTOR (17 DOWNTO 0);
	C_E_M: OUT 	STD_LOGIC;
	W_E_M:	OUT		STD_LOGIC;
	O_E_M: OUT		STD_LOGIC;
	C_E_IN: IN 	STD_LOGIC;
	W_E_IN:	IN		STD_LOGIC;
	O_E_IN: IN		STD_LOGIC;
	L_B_IN:	IN	STD_LOGIC;
	U_B_IN:	IN	STD_LOGIC;
	L_B_M:	OUT	STD_LOGIC;
	U_B_M:	OUT	STD_LOGIC;
	
--Estos son los únicos pines adicionales al funcionamiento
	READ_QUERY:	IN	STD_LOGIC;
	WRITE_QUERY: IN STD_LOGIC
);
	
END MEM_CONTROL;

ARCHITECTURE memory_arch OF mem_control IS

begin

--ADDRESS
--Aunque no es necesario por seguridad, sólo se permite la asignación de valores a los pines
--de dirección cuando los pines READ Y WRITE están configurados correctamente.
	ADDRESS_M<=ADDRESS_I	when	(READ_QUERY='0' AND WRITE_QUERY='1') else
			   ADDRESS_I	when	(READ_QUERY='1' AND WRITE_QUERY='0') else
			   "ZZZZZZZZZZZZZZZZZZ";
	
--Los pines de entrada se conectan a la memoria cuando se solicita una escritura
	D_M<=D_I	when	(READ_QUERY='1' AND WRITE_QUERY='0') else
		 (others=>'Z');

--Los pines de salida se conectan a la memoria cuando se solicita lectura
	D_O<=D_M	when	(READ_QUERY='0' AND WRITE_QUERY='1') else
		 (others=>'Z');

--Lo anterior no supone una protección en si misma. Se podría solicitar lectura 
--y luego indicar a la memoria que se quiere escritura al configurar mal sus pines
--relativos a la lectura y escritura (W_E, O_E). Para evitar fallos, el usuario debe
--configurar estos pines también (interesante desde un punto de vista docente), pero
--esta asignación no se traslada a los pines reales si la configuración de WRITE
--Y READ son corectas.
		 
	C_E_M<=C_E_IN;
	
	O_E_M<='0' when	(READ_QUERY='0' AND WRITE_QUERY='1' and O_E_IN='0' and W_E_IN='1') else
		   '1';
		   
	W_E_M<='0' when	(READ_QUERY='1' AND WRITE_QUERY='0' and W_E_IN='0' and O_E_IN='1') else
		   '1';
		   
	U_B_M<=U_B_IN;
		
	L_B_M<=L_B_IN;
	
	
end architecture;
			
			
		 
			
				