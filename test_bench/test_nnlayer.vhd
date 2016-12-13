LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
Library UNISIM;
use UNISIM.vcomponents.all;
library UNIMACRO;
use unimacro.Vcomponents.all;

use ieee.numeric_std.all;

-- entity declaration for your testbench.Dont declare any ports here
ENTITY test_nnlayer IS 
	END test_nnlayer;

ARCHITECTURE behavior OF test_nnlayer IS
	-- add component under test
		-- Parameters for the neurons
	constant WDATA   : natural := 16;
	constant WWEIGHT : natural := 16;
	constant WACCU   : natural := 32;
	-- Parameters for frame and number of neurons
	constant FSIZE   : natural := 1000;
	constant NBNEU   : natural := 10;
	component nnlayer is
	generic (
		-- Parameters for the neurons
		WDATA   : natural := WDATA;
		WWEIGHT : natural := WWEIGHT;
		WACCU   : natural := WACCU;
		-- Parameters for frame and number of neurons
		FSIZE   : natural := FSIZE;
		NBNEU   : natural := NBNEU 
	);
	port (
		clk            : in  std_logic;
		clear          : in  std_logic;
		-- Ports for Write Enable
		write_mode     : in  std_logic;
		write_data     : in  std_logic_vector(WWEIGHT-1 downto 0);
		write_enable   : in  std_logic;
		write_ready    : out std_logic;
		-- The user-specified frame size and number of neurons
		user_fsize     : in  std_logic_vector(15 downto 0);
		user_nbneu     : in  std_logic_vector(15 downto 0);
		-- Data input, 2 bits
		data_in        : in  std_logic_vector(WDATA-1 downto 0);
		data_in_valid  : in  std_logic;
		data_in_ready  : out std_logic;
		-- Scan chain to extract values
		data_out       : out std_logic_vector(WACCU-1 downto 0);
		data_out_valid : out std_logic;
		-- Indicate to the parent component that we are reaching the end of the current frame
		end_of_frame   : out std_logic;
		-- The output data enters a FIFO. This indicates the available room.
		out_fifo_room  : in  std_logic_vector(15 downto 0)
	);
	end component;

	-- clock period definition
	constant clk_period : time := 1 ns;
	-- Control signals
	signal clk            : std_logic := '0';
	signal clear          : std_logic := '0';
		-- Ports for Write Enable
	signal write_mode     : std_logic := '0';
	signal write_data     : std_logic_vector(WWEIGHT-1 downto 0);
	signal write_enable   : std_logic := '0';
	signal write_ready    : std_logic := '0';
		-- The user-specified frame size and number of neurons
	signal user_fsize     : std_logic_vector(15 downto 0);
	signal user_nbneu     : std_logic_vector(15 downto 0);
		-- Data input, 2 bits
	signal data_in        : std_logic_vector(WDATA-1 downto 0);
	signal data_in_valid  : std_logic := '0';
	signal data_in_ready  : std_logic := '0';
		-- Scan chain to extract values
	signal data_out       : std_logic_vector(WACCU-1 downto 0);
	signal data_out_valid : std_logic := '0';
		-- Indicate to the parent component that we are reaching the end of the current frame
	signal end_of_frame   : std_logic := '0';
		-- The output data enters a FIFO. This indicates the available room.
	signal out_fifo_room  : std_logic_vector(15 downto 0);

begin
	-- Instantiate the Unit Under Test (UUT)
	uut: nnlayer
	port map (
		clk => clk,
		clear => clear,
		-- Ports for Write Enable
		write_mode => write_mode,
		write_data => write_data,
		write_enable => write_enable,
		write_ready => write_ready,
		-- The user-specified frame size and number of neurons
		user_fsize => user_fsize,
		user_nbneu => user_nbneu,
		-- Data input, 2 bits
		data_in => data_in,
		data_in_valid => data_in_valid,
		data_in_ready => data_in_ready,
		-- Scan chain to extract values
		data_out => data_out,
		data_out_valid => data_out_valid,
		-- Indicate to the parent component that we are reaching the end of the current frame
		end_of_frame => end_of_frame,
		-- The output data enters a FIFO. This indicates the available room.
		out_fifo_room => out_fifo_room
		 );


	-- Clock process definitions( clock with 50% duty cycle is generated here.
	clk_process : process
	begin
		clk <= '1';
		wait for clk_period/2;  --for 0.5 ns signal is '1'.
		clk <= '0';
		wait for clk_period/2;  --for next 0.5 ns signal is '0'.
	end process;
	--spy_process : process
	--begin
	--	init_signal_spy("/test_nnlayer/uut/fsm_gen/sensor_we_mode","sensor_we_mode",1,-1);
	--end process;
	-- Stimulus process
	stim_proc: process
		variable counter : integer := 0;
		variable neurons : integer := 0;
	begin         
		-- reset
		clear <= '1';
		wait for 3*clk_period;
		clear <= '0';

		write_data <= X"0001";

		write_mode <= '1'; -- load weights
		write_enable <= '1'; -- correspond to FIFO_in_ACK
		data_in_valid <= '1'; -- data is in FIFO

		-- while (.fsm_gen.sensor_we_mode = 0) loop
		-- 	wait for clk_period;
		-- end loop;

		-- while (test_nnlayer.uut.fsm_gen.sensor_we_shift = 0) loop
		-- 	wait for clk_period;
		-- end loop;

		wait for 9 * clk_period;

		while neurons < 10 loop
			while (counter < 1000 ) loop
				wait for clk_period;
				ASSERT ( data_in_ready = '1')
				REPORT "data_in_ready != 1";
				counter := counter + 1;
				wait for clk_period;
			end loop;
			neurons := neurons +1;
			wait for 10 * clk_period;
		end loop;


		write_data <= X"0001";

		write_mode <= '0'; -- accu add 
		write_enable <= '1'; -- correspond to FIFO_in_ACK
		data_in_valid <= '1'; -- data is in FIFO

		ASSERT ( data_in_ready = '1')
			REPORT "data_in_ready != 1";

		wait;

	end process;

END;
