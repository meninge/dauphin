----------------------------------------------------------------
-- uut:
--	neuron.vhd
-- description:
--	simple test_bench to verify neuron behavior in simple cases
-- expected result:
--	neuron should behave as we describe in the neuron schematic
----------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
Library UNISIM;
use UNISIM.vcomponents.all;
library UNIMACRO;
use unimacro.Vcomponents.all;

use ieee.numeric_std.all;

-- entity declaration for your testbench.Dont declare any ports here
ENTITY test_neuron IS
	END test_neuron;

ARCHITECTURE behavior OF test_neuron IS
	-- add component under test
	component neuron
		generic (
		-- Parameters for the neurons
		WDATA   : natural := 32;
		WWEIGHT : natural := 16;
		WACCU   : natural := 32;
		-- Parameters for the frame size
		FSIZE   : natural := 784;
		WADDR   : natural := 10
	);
	port (
		clk             : in  std_logic;
		-- Control signals
		ctrl_we_mode    : in  std_logic;
		ctrl_we_shift   : in  std_logic;
		ctrl_we_valid   : in  std_logic;
		ctrl_accu_clear : in  std_logic;
		ctrl_accu_add   : in  std_logic;
		ctrl_shift_en   : in  std_logic;
		ctrl_shift_copy : in  std_logic;
		-- Address used for Read and Write
		addr            : in  std_logic_vector(WADDR-1 downto 0);
		-- Ports for Write Enable
		we_prev         : in  std_logic;
		we_next         : out std_logic;
		write_data      : in  std_logic_vector(WDATA-1 downto 0);
		-- Data input, 2 bits
		data_in         : in  std_logic_vector(WDATA-1 downto 0);
		-- Scan chain to extract values
		sh_data_in      : in  std_logic_vector(WACCU-1 downto 0);
		sh_data_out     : out std_logic_vector(WACCU-1 downto 0);
		-- Sensors, for synchronization with the controller
		sensor_shift    : out std_logic;
		sensor_copy     : out std_logic;
		sensor_we_mode  : out std_logic;
		sensor_we_shift : out std_logic;
		sensor_we_valid : out std_logic
	);
	end component;

	signal clk           :   std_logic := '0';
	-- Control signals
	signal ctrl_we_mode    :   std_logic := '0';
	signal ctrl_we_shift   :   std_logic := '0';
	signal ctrl_we_valid   :   std_logic := '0';
	signal ctrl_accu_clear :   std_logic := '0';
	signal ctrl_accu_add   :   std_logic := '0';
	signal ctrl_shift_en   :   std_logic := '0';
	signal ctrl_shift_copy :   std_logic := '0';
	-- Address used for Read and Write
	signal addr            :   std_logic_vector(9 downto 0);
	-- Ports for Write Enable
	signal we_prev      :   std_logic := '0';
	signal we_next      :  std_logic := '0';
	signal write_data   :  std_logic_vector(31 downto 0);
	-- Data input, 2 bits
	signal data_in         : std_logic_vector(31 downto 0);
	-- Scan chain to extract values
	signal sh_data_in      : std_logic_vector(31 downto 0);
	signal sh_data_out     : std_logic_vector(31 downto 0);
	-- Sensors, for synchronization with the controller
	signal sensor_shift    :  std_logic := '0';
	signal sensor_copy     :  std_logic := '0';
	signal sensor_we_mode  :  std_logic := '0';
	signal sensor_we_shift :  std_logic := '0';
	signal sensor_we_valid :  std_logic := '0';

	-- clock period definition
	constant clk_period : time := 1 ns;

begin
	-- Instantiate the Unit Under Test (UUT)
	uut: neuron
	port map (
			 clk => clk         ,
			 -- Control signals
			 ctrl_we_mode => ctrl_we_mode   ,
			 ctrl_we_shift => ctrl_we_shift  ,
			 ctrl_we_valid => ctrl_we_valid  ,
			 ctrl_accu_clear => ctrl_accu_clear,
			 ctrl_accu_add => ctrl_accu_add  ,
			 ctrl_shift_en => ctrl_shift_en  ,
			 ctrl_shift_copy => ctrl_shift_copy,
			 -- Address used for Read and Write
			 addr => addr           ,
			 -- Ports for Write Enable
			 we_prev => we_prev        ,
			 we_next => we_next        ,
			 write_data => write_data,
			 data_in => data_in,
			 sh_data_in => sh_data_in,
			 sh_data_out => sh_data_out,
			 -- Sensors, for synchronization with the controller
			 sensor_shift => sensor_shift   ,
			 sensor_copy => sensor_copy    ,
			 sensor_we_mode => sensor_we_mode ,
			 sensor_we_shift => sensor_we_shift,
			 sensor_we_valid => sensor_we_valid
		 );


	-- Clock process definitions( clock with 50% duty cycle is generated here.
	clk_process : process
	begin
		clk <= '1';
		wait for clk_period/2;  --for 0.5 ns signal is '1'.
		clk <= '0';
		wait for clk_period/2;  --for next 0.5 ns signal is '0'.
	end process;
	-- Stimulus process
	stim_proc: process
	begin
		-------------------------------
		-- TEST CHARGEMENT DES POIDS --
		-------------------------------

		wait for clk_period;
		ctrl_we_mode <= '1';
		sh_data_in <= X"00000000";

		wait for clk_period;
		we_prev <= '1';
		ctrl_we_shift <= '1';

		wait for clk_period;
		we_prev <= '0';
		ctrl_we_shift <= '0';
		ctrl_we_valid <= '1';

		for I in 0 to 783 loop
			addr <= std_logic_vector(to_unsigned(I, addr'length));
			write_data <= std_logic_vector(to_unsigned(I mod 2, write_data'length));
			wait for clk_period;
		end loop;

		ctrl_we_valid <= '0';
		ctrl_we_shift <= '1';
		we_prev <= '0';

		wait for clk_period;
		ctrl_we_shift <= '0';

		wait for clk_period;
		wait for clk_period;
		wait for clk_period;

		-----------------------
		-- TEST ACCUMULATION --
		-----------------------
		ctrl_we_mode <= '0';

		wait for clk_period;
		ctrl_accu_clear <= '1';

		wait for clk_period;
		ctrl_accu_clear <= '0';
		ctrl_accu_add <= '1';
		data_in <= X"00000001";
		addr <= std_logic_vector(to_unsigned(0, addr'length));

		for I in 0 to 783 loop
			addr <= std_logic_vector(to_unsigned(I, addr'length));
			wait for clk_period;
		end loop;

		ctrl_accu_add <= '0';
		ctrl_shift_copy <= '1';

		wait for clk_period;
		ctrl_shift_copy <= '0';
		ctrl_shift_en <= '1';

		wait for clk_period;
		ctrl_shift_en <= '0';

		wait for clk_period;

		wait;
	end process;

END;
