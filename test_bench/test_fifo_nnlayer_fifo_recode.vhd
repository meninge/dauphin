----------------------------------------------------------------
-- uut:
--	nnlayer.vhd
--	neuron.vhd
--	fsm.vhd
--	distribuf.vhd
--	recode.vhd
--	circbuf_fast.vhd
-- description: 
--	simple test_bench to verify nnlayer and recode behaviors in normal conditions
--	with a fifo just before nnlayer,
--	and a fifo between nnlayer and recode
-- expected result:
--	neurons should be configured in weight configuration mode
--	in normal mode, neurons should input accumulation of
--	data*weights
--	nnlayer should correctly interact with input and output fifos

--	recode should be configured in weight configuration mode
--	in normal mode, recode should act as:
--		output = (input < 0) ? 0 : input + cst[addr]
--	recode should correctly interact with input fifo
--
--	total outputs:
--		total = (sum(datas*weights[neuron]) < 0) ?
--			0 : sum(datas*weights[neuron]) + cst[corresponding neuron]
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
ENTITY test_nnlayer_fifo IS 
	END test_nnlayer_fifo;

ARCHITECTURE behavior OF test_nnlayer_fifo IS
	-- add component under test
		-- Parameters for the neurons
	constant WDATA   : natural := 32;
	constant WOUT : natural := WDATA;
	constant WWEIGHT : natural := 32;
	constant WACCU   : natural := 32;
	-- Parameters for frame and number of neurons
	constant FSIZE   : natural := 10;
	constant NBNEU   : natural := 10;
	constant DATAW : natural := WDATA;
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

	component recode 
	generic(
		WDATA : natural := WDATA;
		WOUT  : natural := WOUT;
		FSIZE : natural := NBNEU -- warning, this is NB_NEU
	);
	port(
		clk             : in  std_logic;
		addr_clear      : in  std_logic;
		write_mode      : in  std_logic;
		write_data      : in  std_logic_vector(WDATA - 1 downto 0);
		write_enable    : in  std_logic;
		write_ready     : out std_logic;
		user_nbneu      : in  std_logic_vector(15 downto 0);
		data_in         : in  std_logic_vector(WDATA-1 downto 0);
		data_in_valid   : in  std_logic;
		data_in_ready   : out std_logic;
		data_out        : out std_logic_vector(WOUT-1 downto 0);
		data_out_valid  : out std_logic;
		out_fifo_room   : in  std_logic_vector(15 downto 0)
	);
	end component;



	-- clock period definition
	constant clk_period : time := 1 ns;
	signal clk            : std_logic := '0';
	signal clear          : std_logic := '0';

-- nnlayer signals
	signal write_mode     : std_logic := '0';
	signal write_data     : std_logic_vector(WWEIGHT-1 downto 0);
	signal write_enable   : std_logic := '0';
	signal write_ready    : std_logic := '0';
	signal user_fsize     : std_logic_vector(15 downto 0);
	signal user_nbneu     : std_logic_vector(15 downto 0);
	signal data_in        : std_logic_vector(WDATA-1 downto 0);
	signal data_in_valid  : std_logic := '0';
	signal data_in_ready  : std_logic := '0';
	signal data_out       : std_logic_vector(WACCU-1 downto 0);
	signal data_out_valid : std_logic := '0';
	signal end_of_frame   : std_logic := '0';
	signal out_fifo_room  : std_logic_vector(15 downto 0);

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

-- recode signals
	signal recode_write_mode      : std_logic;
	signal recode_write_data      : std_logic_vector(WDATA - 1 downto 0);
	signal recode_write_enable    : std_logic;
	signal recode_write_ready     : std_logic;
	signal recode_user_nbneu      : std_logic_vector(15 downto 0);
	signal recode_data_in         : std_logic_vector(WDATA-1 downto 0);
	signal recode_data_in_valid   : std_logic;
	signal recode_data_in_ready   : std_logic;
	signal recode_data_out        : std_logic_vector(WOUT-1 downto 0);
	signal recode_data_out_valid  : std_logic;
	signal recode_out_fifo_room   : std_logic_vector(15 downto 0);


begin
	-- Instantiate the Uni../recode.vhd:12:t Under Test (UUT)
	nnlayer_1 : nnlayer
	port map (
		clk => clk,
		clear => clear,
		write_mode => write_mode,
		write_data => write_data,
		write_enable => write_enable,
		write_ready => write_ready,
		user_fsize => user_fsize,
		user_nbneu => user_nbneu,
		data_in => data_in,
		data_in_valid => data_in_valid,
		data_in_ready => data_in_ready,
		data_out => data_out,
		data_out_valid => data_out_valid,
		end_of_frame => end_of_frame,
		out_fifo_room => out_fifo_room
		 );

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
		addr_clear => clear,
		write_mode => recode_write_mode,
		write_data => recode_write_data,
		write_enable => recode_write_enable,
		write_ready => recode_write_ready,
		user_nbneu => recode_user_nbneu,
		data_in => recode_data_in,
		data_in_valid => recode_data_in_valid,
		data_in_ready => recode_data_in_ready,
		data_out => recode_data_out,
		data_out_valid => recode_data_out_valid,
		out_fifo_room => recode_out_fifo_room
	);
	
	-- fifo 1 & nnlayer_1
	write_data <= fifo_out_data_1;
	data_in <= fifo_out_data_1;
	data_in_valid <= fifo_out_rdy_1;

	-- fifo 2 & nnlayer_1
	fifo_in_data_2 <= data_out;
	fifo_in_ack_2 <= data_out_valid;

	-- fifo_2 & recode

	recode_data_in <= fifo_out_data_2;
	recode_data_in_valid <= fifo_out_rdy_2;
	fifo_out_ack_2 <= recode_data_in_ready and not recode_write_mode;
	recode_write_enable <= fifo_out_rdy_1;

	-- special case for config recode!
	fifo_out_ack_1 <= (recode_data_in_ready and recode_write_mode) or (data_in_ready and not recode_write_mode);
	recode_write_data <= fifo_out_data_1;





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
		-- TEST CHARGEMENT DES POIDS
		-- reset
		clear <= '1';
		wait for 3*clk_period;
		clear <= '0';
		write_mode <= '1'; -- load weights
		recode_out_fifo_room <= X"0008";

		-- load data into the fifo
		fifo_in_data_1 <= X"00000001";
		fifo_in_ack_1 <= '1'; 

		while neurons < NBNEU loop
			counter := 0;
			fifo_in_data_1 <= X"00000001";
			fifo_in_ack_1 <= '1'; 
			while (counter < FSIZE) loop
				wait for clk_period;
				counter := counter + 1;
				wait for clk_period;
			end loop;
			neurons := neurons +1;
		end loop;
		
		write_mode <= '0'; -- load weights

		-- recode write config
		recode_write_mode <= '1'; -- load weights

		neurons := 0;
		while neurons < NBNEU loop
			counter := 0;
			fifo_in_data_1 <= X"00000001";
			fifo_in_ack_1 <= '1'; 
			neurons := neurons +1;
			wait for clk_period;
		end loop;
		recode_write_mode <= '0'; -- accu add 


		-- TEST MODE ACCUMULATION 
		write_mode <= '0'; -- accu add 

		counter := 0;
		while (counter < FSIZE) loop
			wait for clk_period;
			ASSERT ( data_in_ready = '1')
			REPORT "data_in_ready != 1";
			counter := counter + 1;
			wait for clk_period;
		end loop;


		wait;

	end process;

END;
