----------------------------------------------------------------
-- uut:
--	nnlayer.vhd
--	neuron.vhd
--	fsm.vhd
--	distribuf.vhd
--	circbuf_fast.vhd
-- description:
--	simple test_bench to verify nnlayer behavior in normal conditions
--	with a fifo just before
-- expected result:
--	neurons should be configured in weight configuration mode
--	in normal mode, neurons should input accumulation of
--	data*weights
--	nnlayer should correctly interact with input fifo
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
ENTITY test_fifo_nnlayer IS
	END test_fifo_nnlayer;

ARCHITECTURE behavior OF test_fifo_nnlayer IS
	-- add component under test
		-- Parameters for the neurons
	constant WDATA   : natural := 32;
	constant WWEIGHT : natural := 16;
	constant WACCU   : natural := 32;
	-- Parameters for frame and number of neurons
	constant FSIZE   : natural := 64;
	constant NBNEU   : natural := 4;
	constant DATAW : natural := 32;
	constant DEPTH : natural := 8;
	constant CNTW  : natural := 16;

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
		write_data     : in  std_logic_vector(WDATA-1 downto 0);
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

	component circbuf_fast is
	generic (
		DATAW : natural := DATAW;
		DEPTH : natural := DEPTH;
		CNTW  : natural := CNTW
	);
	port (
		reset         : in  std_logic;
		clk           : in  std_logic;
		fifo_in_data  : in  std_logic_vector(DATAW-1 downto 0);
		fifo_in_rdy   : out std_logic;
		fifo_in_ack   : in  std_logic;
		fifo_in_cnt   : out std_logic_vector(CNTW-1 downto 0);
		fifo_out_data : out std_logic_vector(DATAW-1 downto 0);
		fifo_out_rdy  : out std_logic;
		fifo_out_ack  : in  std_logic;
		fifo_out_cnt  : out std_logic_vector(CNTW-1 downto 0)
	);
end component;


	-- clock period definition
	constant clk_period : time := 1 ns;
	-- Control signals
	signal clk            : std_logic := '0';
	signal clear          : std_logic := '0';
		-- Ports for Write Enable
	signal write_mode     : std_logic := '0';
	signal write_data     : std_logic_vector(WDATA-1 downto 0);
	signal write_enable   : std_logic := '0';
	signal write_ready    : std_logic := '0';
		-- The user-specified frame size and number of neurons
	signal user_fsize     : std_logic_vector(15 downto 0);
	signal user_nbneu     : std_logic_vector(15 downto 0);
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

-- for the fifo
	signal	fifo_in_data  : std_logic_vector(DATAW-1 downto 0);
	signal	fifo_in_rdy   : std_logic;
	signal	fifo_in_ack   : std_logic;
	signal	fifo_in_cnt   : std_logic_vector(CNTW-1 downto 0);
	signal	fifo_out_data : std_logic_vector(DATAW-1 downto 0);
	signal	fifo_out_rdy  : std_logic;
	signal	fifo_out_ack  : std_logic;
	signal	fifo_out_cnt  : std_logic_vector(CNTW-1 downto 0);

begin
	-- Instantiate the Uni../recode.vhd:12:t Under Test (UUT)
	uut: nnlayer
	port map (
		clk => clk,
		clear => clear,
		-- Ports for Write Enable
		write_mode => write_mode,
		write_data => write_data,
		write_enable => fifo_out_rdy,
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

	fifo: circbuf_fast
	port map (
		reset         => clear,
		clk           => clk,
		fifo_in_data  => fifo_in_data,
		fifo_in_rdy   => fifo_in_rdy,
		fifo_in_ack   => fifo_in_ack,
		fifo_in_cnt   => fifo_in_cnt,
		fifo_out_data => fifo_out_data,
		fifo_out_rdy  => fifo_out_rdy,
		fifo_out_ack  => fifo_out_ack,
		fifo_out_cnt  => fifo_out_cnt
	);

	write_data <= fifo_out_data;
	data_in <= fifo_out_data;
	data_in_valid <= fifo_out_rdy;
	--data_in_ready <= fifo_out_ack;
	fifo_out_ack <= data_in_ready or write_ready;

	-- Clock process definitions( clock with 50% duty cycle is generated here.
	clk_process : process
	begin
		clk <= '1';
		wait for clk_period/2;  --for 0.5 ns signal is '1'.
		clk <= '0';
		wait for clk_period/2;  --for next 0.5 ns signal is '0'.
	end process;

	out_fifo_room_proc : process
	begin
		wait for clk_period;
		out_fifo_room <= X"0007";
		wait for clk_period;
		wait for clk_period;
		out_fifo_room <= X"0002";
	end process;

	stim_proc: process
		variable counter : integer := 0;
		variable neurons : integer := 0;
	begin
		-------------------------------
		-- TEST CHARGEMENT DES POIDS --
		-------------------------------

		-- reset
		clear <= '1';
		wait for 3*clk_period;
		clear <= '0';
		write_mode <= '1'; -- load weights


		while neurons < NBNEU loop
			counter := 0;
			while (counter < FSIZE) loop
				fifo_in_data <= std_logic_vector(to_signed(counter + 10, 32));
				fifo_in_ack <= '1';
				wait for clk_period;
				counter := counter + 1;
				fifo_in_data <= std_logic_vector(to_signed(counter*10 + 10, 32));
				fifo_in_ack <= '1';
				wait for clk_period;
			end loop;
			neurons := neurons +1;
			--wait for 10 * clk_period;
		end loop;

		wait for 100 * clk_period;

		----------------------------
		-- TEST MODE ACCUMULATION --
		----------------------------

		write_mode <= '0'; -- accu add

		counter := 0;
		while (counter < FSIZE) loop
			wait for clk_period;
			counter := counter + 1;
			wait for clk_period;
		end loop;

		wait;

	end process;

END;
