----------------------------------------------------------------
-- uut:
--	recode.vhd
--	circbuf_fast.vhd
-- description: 
--	simple test_bench to verify recode behavior in normal conditions
--	with a fifo just before
--	and a fifo just after
-- expected result:
--	recode should be configured in weight configuration mode
--	in normal mode, recode should act as:
--		output = (input < 0) ? 0 : input + cst[addr]
--	recode should correctly interact with input and output fifos
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
ENTITY test_fifo_recode_fifo IS 
	END test_fifo_recode_fifo;

ARCHITECTURE behavior OF test_fifo_recode_fifo IS
	-- add component under test
		-- Parameters for the neurons
	constant WDATA   : natural := 32;
	constant WOUT : natural := WDATA;
	constant WWEIGHT : natural := 16;
	constant WACCU   : natural := 32;
	-- Parameters for frame and number of neurons
	constant FSIZE   : natural := 4;
	constant NBNEU   : natural := 4;
	constant DATAW : natural := 32;
	constant DEPTH : natural := 8;
	constant CNTW  : natural := 16;

	component recode 
	generic(
		WDATA : natural := WDATA;
		WWEIGHT : natural := WWEIGHT;
		WOUT  : natural := WOUT;
		FSIZE : natural := NBNEU -- warning, this is NB_NEU
	);
	port(
		clk             : in  std_logic;
		-- Ports for address control
		addr_clear      : in  std_logic;
		-- Ports for Write into memory
		write_mode      : in  std_logic;
		write_data      : in  std_logic_vector(WDATA - 1 downto 0);
		write_enable    : in  std_logic;
		write_ready     : out std_logic;
		-- The user-specified number of neurons
		user_nbneu      : in  std_logic_vector(15 downto 0);
		-- Data input
		data_in         : in  std_logic_vector(WDATA-1 downto 0);
		data_in_valid   : in  std_logic;
		data_in_ready   : out std_logic;
		-- Data output
		data_out        : out std_logic_vector(WOUT-1 downto 0);
		data_out_valid  : out std_logic;
		-- The output data enters a FIFO. This indicates the available room.
		out_fifo_room   : in  std_logic_vector(15 downto 0)
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
	signal clear		: std_logic := '0';
	signal clk		: std_logic := '0';

-- recode signals
	signal addr_clear      : std_logic;
	signal write_mode      : std_logic;
	signal write_data      : std_logic_vector(WDATA - 1 downto 0);
	signal write_enable    : std_logic;
	signal write_ready     : std_logic;
	signal user_nbneu      : std_logic_vector(15 downto 0);
	signal data_in         : std_logic_vector(WDATA-1 downto 0);
	signal data_in_valid   : std_logic;
	signal data_in_ready   : std_logic;
	signal data_out        : std_logic_vector(WOUT-1 downto 0);
	signal data_out_valid  : std_logic;
	signal out_fifo_room   : std_logic_vector(15 downto 0);


-- for the fifo_1
	signal	fifo_in_data_1  : std_logic_vector(DATAW-1 downto 0);
	signal	fifo_in_rdy_1   : std_logic;
	signal	fifo_in_ack_1   : std_logic;
	signal	fifo_in_cnt_1   : std_logic_vector(CNTW-1 downto 0);
	signal	fifo_out_data_1 : std_logic_vector(DATAW-1 downto 0);
	signal	fifo_out_rdy_1  : std_logic;
	signal	fifo_out_ack_1  : std_logic;
	signal	fifo_out_cnt_1  : std_logic_vector(CNTW-1 downto 0);

-- for the fifo_2
	signal	fifo_in_data_2  : std_logic_vector(DATAW-1 downto 0);
	signal	fifo_in_rdy_2   : std_logic;
	signal	fifo_in_ack_2   : std_logic;
	signal	fifo_in_cnt_2   : std_logic_vector(CNTW-1 downto 0);
	signal	fifo_out_data_2 : std_logic_vector(DATAW-1 downto 0);
	signal	fifo_out_rdy_2  : std_logic;
	signal	fifo_out_ack_2  : std_logic;
	signal	fifo_out_cnt_2  : std_logic_vector(CNTW-1 downto 0);

begin

	fifo_1: circbuf_fast 
	port map (
		reset         => clear,
		clk           => clk,
		fifo_in_data  => fifo_in_data_1,
		fifo_in_rdy   => fifo_in_rdy_1,
		fifo_in_ack   => fifo_in_ack_1,
		fifo_in_cnt   => fifo_in_cnt_1,
		fifo_out_data => fifo_out_data_1,
		fifo_out_rdy  => fifo_out_rdy_1,
		fifo_out_ack  => fifo_out_ack_1,
		fifo_out_cnt  => fifo_out_cnt_1
	);

	fifo_2: circbuf_fast 
	port map (
		reset         => clear,
		clk           => clk,
		fifo_in_data  => fifo_in_data_2,
		fifo_in_rdy   => fifo_in_rdy_2,
		fifo_in_ack   => fifo_in_ack_2,
		fifo_in_cnt   => fifo_in_cnt_2,
		fifo_out_data => fifo_out_data_2,
		fifo_out_rdy  => fifo_out_rdy_2,
		fifo_out_ack  => fifo_out_ack_2,
		fifo_out_cnt  => fifo_out_cnt_2
	);

	recode_1 : recode 
	port map (
		clk => clk,
		addr_clear => addr_clear,
		write_mode => write_mode,
		write_data => write_data,
		write_enable => write_enable,
		write_ready => write_ready,
		user_nbneu => user_nbneu,
		data_in => data_in,
		data_in_valid => data_in_valid,
		data_in_ready => data_in_ready,
		data_out => data_out,
		data_out_valid => data_out_valid,
		out_fifo_room => out_fifo_room
	);
	
	write_data <= fifo_out_data_1;
	write_enable <= fifo_out_rdy_1;
	data_in <= fifo_out_data_1;
	data_in_valid <= fifo_out_rdy_1;
	--data_in_ready <= fifo_out_ack;
	fifo_out_ack_1 <= data_in_ready or write_ready;

	fifo_in_ack_2 <= data_out_valid;
	fifo_in_data_2 <= data_out;
	out_fifo_room <= fifo_in_cnt_2;

	-- Clock process definitions( clock with 50% duty cycle is generated here.
	clk_process : process
	begin
		clk <= '1';
		wait for clk_period/2;  --for 0.5 ns signal is '1'.
		clk <= '0';
		wait for clk_period/2;  --for next 0.5 ns signal is '0'.
	end process;

	stim_proc: process
		variable counter : integer := 0;
		variable neurons : integer := 0;
	begin         
		-- TEST CHARGEMENT DES POIDS
		-- reset
		clear <= '1';
	   fifo_in_data_1 <= std_logic_vector(to_unsigned(0, 32));
	fifo_in_ack_1 <= '0'; 

		wait for 3*clk_period;
		clear <= '0';
		write_mode <= '1'; -- load weights
		-- load data into the fifo
		  fifo_in_data_1 <= std_logic_vector(to_unsigned(3, 32));
		  fifo_in_ack_1 <= '1'; 
		     --while neurons < NBNEU loop
			counter := 0;
			neurons := neurons + 1;
			wait for clk_period;
			wait for clk_period;

			counter := 0;
			fifo_in_data_1 <= std_logic_vector(to_signed(4, 32));
			fifo_in_ack_1 <= '1'; 
			neurons := neurons +1;
			wait for clk_period;
			counter := 0;
			fifo_in_data_1 <= std_logic_vector(to_signed(5, 32));
			fifo_in_ack_1 <= '1'; 
			neurons := neurons +1;
			wait for clk_period;
			counter := 0;
			fifo_in_data_1 <= std_logic_vector(to_signed(1, 32));
			fifo_in_ack_1 <= '1'; 
			neurons := neurons +1;
			wait for clk_period;
			fifo_in_data_1 <= std_logic_vector(to_signed(10, 32));
			fifo_in_ack_1 <= '0'; 

		--end loop;
			wait for clk_period;
			wait for clk_period;
			wait for clk_period;
			wait for clk_period;
			wait for clk_period;
		write_mode <= '0'; -- accu add 
fifo_in_ack_1 <= '1';
		wait for clk_period;

		-- TEST MODE ACCUMULATION 
		write_mode <= '0'; -- accu add 
		fifo_in_data_1 <= std_logic_vector(to_unsigned(64, 32));

		counter := 0;
		while (counter < FSIZE) loop
			wait for clk_period;
			fifo_in_data_1 <= std_logic_vector(to_unsigned(128, 32));
			counter := counter + 1;
			wait for clk_period;
			fifo_in_data_1 <= std_logic_vector(to_unsigned(64, 32));
		end loop;

		wait;

	end process;

END;
