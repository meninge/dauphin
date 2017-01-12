
-- This is one layer of a neural network
-- It contains several neurons that process input frames

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.all;

entity nnlayer is
	generic (
		-- Parameters for the neurons
		WDATA   : natural := 16;
		WWEIGHT : natural := 16;
		WACCU   : natural := 48;
		-- Parameters for frame and number of neurons
		FSIZE   : natural := 784;
		NBNEU   : natural := 200;
		-- fifo count
		CNTW : natural := 16
	);
	port (
		clk            : in  std_logic;
	-- reset
		clear          : in  std_logic;
		-- Ports for Write Enable
		write_mode     : in  std_logic;
		write_data     : in  std_logic_vector(WWEIGHT-1 downto 0) ;
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
		out_fifo_room  : in  std_logic_vector(CNTW - 1 downto 0)
	);
end nnlayer;

architecture synth of nnlayer is

	-- Max fanout for signals distributed to all BRAM-based blocks
	constant FANOUT : natural := 4;

	-- The address to access neuron memory, read and write
	constant WADDR : natural := 10;

	-- Arrays of signals to instantiate the neurons
	signal arr_write_data : std_logic_vector(NBNEU*WWEIGHT-1 downto 0) := (others => '0');
	-- Input data
	signal arr_data_in : std_logic_vector(NBNEU*WDATA-1 downto 0) := (others => '0');

	-- Controls signals, go to every neuron through distribuf
	signal sg_ctrl_we_mode : std_logic_vector(0 downto 0):= (others => '0');
	signal sg_ctrl_we_shift : std_logic_vector(0 downto 0):= (others => '0');
	signal sg_ctrl_we_valid : std_logic_vector(0 downto 0):= (others => '0');
	signal sg_ctrl_accu_clear : std_logic_vector(0 downto 0):= (others => '0');
	signal sg_ctrl_accu_add : std_logic_vector(0 downto 0):= (others => '0');
	signal sg_ctrl_shift_en : std_logic_vector(0 downto 0):= (others => '0');
	signal sg_ctrl_shift_copy : std_logic_vector(0 downto 0):= (others => '0');
	-- Address signal
	signal sg_addr : std_logic_vector(WADDR - 1 downto 0):= (others => '0');
	-- Signal to connect the sensor we valid from the good fifo to the fsm inside the nnlayer
	signal sg_sensor_we_valid : std_logic := '0';

	-- Corresponding arrays
	signal arr_ctrl_we_mode : std_logic_vector(NBNEU - 1 downto 0) := (others => '0');
	signal arr_ctrl_we_shift : std_logic_vector(NBNEU - 1 downto 0) := (others => '0');
	signal arr_ctrl_we_valid : std_logic_vector(NBNEU - 1 downto 0) := (others => '0');
	signal arr_ctrl_accu_clear : std_logic_vector(NBNEU - 1 downto 0) := (others => '0');
	signal arr_ctrl_accu_add : std_logic_vector(NBNEU - 1 downto 0) := (others => '0');
	signal arr_ctrl_shift_en : std_logic_vector(NBNEU - 1 downto 0) := (others => '0');
	signal arr_ctrl_shift_copy : std_logic_vector(NBNEU - 1 downto 0) := (others => '0');
	signal arr_addr : std_logic_vector(NBNEU * WADDR - 1 downto 0) := (others => '0');

	-- Declaration of signal array to wire we_next and we_prev of every
	-- neuron
	-- We need 1 wire between two neurons and 2 more for first and last one.
	-- Hence NBNEU + 1 values.
	type match_array is array (0 to NBNEU) of std_logic;

	signal we_match : match_array := (others => '0');

	type match_array_waccu is array (0 to NBNEU) of std_logic_vector(WACCU - 1 downto 0);
	-- Declaration of sh_data array with NBNEU wires
	signal sh_data_match : match_array_waccu := (others => (others => '0'));

	-- Declaration of sensor arrays
	-- We use only the first one of this array
	signal sensors_shift_match : match_array:= (others => '0');
	signal sensors_copy_match : match_array:= (others => '0');
	signal sensors_we_mode_match : match_array:= (others => '0');
	signal sensors_we_shift_match : match_array:= (others => '0');
	signal sensors_we_valid_match : match_array:= (others => '0');

	-- FIFO management signals
	signal sg_in_fifo_out_ack : std_logic := '0';
	--signal sg_out_fifo_in_ack : std_logic;
	signal sg_out_fifo_in_cnt : std_logic_vector(CNTW - 1 downto 0) := (others => '0');

	-- Component declaration: one neuron
	component neuron is
		generic (
			-- Parameters for the neurons
			WDATA   : natural := 32;
			WWEIGHT : natural := 32;
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
			write_data      : in  std_logic_vector(WWEIGHT-1 downto 0);
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

	-- FSM for this layer
	component fsm is
		generic (
			-- global parameters of layers
			NB_NEURONS: natural := 200;
			-- parameters of a neuron
			WDATA   : natural := 16;
			WWEIGHT : natural := 16;
			WACCU   : natural := 48;
			-- Parameters for the frame size
			FSIZE   : natural := 784;
			WADDR   : natural := 10
		);
		port (
			reset         : in  std_logic;
			clk           : in  std_logic;
			-- Control signals
			-- (go to all neurons)
			ctrl_we_mode    : out  std_logic;
			ctrl_we_shift   : out  std_logic;
			ctrl_we_valid   : out  std_logic;
			ctrl_accu_clear : out  std_logic;
			ctrl_accu_add   : out  std_logic;
			ctrl_shift_en   : out  std_logic;
			ctrl_shift_copy : out  std_logic;
			-- Address used for Read and Write
			-- (go to all neurons)
			addr            : out  std_logic_vector(WADDR-1 downto 0);
			-- Ports for Write Enable
			-- go to first neuron
			n0_we_prev         : out  std_logic;
			-- come from last neuron
			nN_we_next         : in std_logic;
			-- Sensors, for synchronization with the controller
			-- go to first neurons
			sensor_shift    : in std_logic;
			sensor_copy     : in std_logic;
			sensor_we_mode  : in std_logic;
			sensor_we_shift : in std_logic;
			sensor_we_valid : in std_logic;

			-- inputs
			fsm_mode	: in std_logic;

			-- input FIFO control
			out_fifo_in_cnt : in std_logic_vector(CNTW-1 downto 0)
			-- output FIFO control
			--out_fifo_in_ack : out std_logic

		);
	end component;

	-- Component declaration: distribution tree to limit fanout
	component distribuf is
		generic(
			WDATA :  natural := 32;
			NBOUT :  natural := 32;
			FANOUT : natural := 32
		);
		port(
			clk : in std_logic;
			-- Input
			idata : in std_logic_vector(WDATA-1 downto 0);
			-- Outputs
			odata : out std_logic_vector(WDATA*NBOUT-1 downto 0)
		);
	end component;

begin

	-------------------------------------------------------------------
	-- Instantiate the fanout distribution trees
	-------------------------------------------------------------------

	-- Fanout distribution tree: write_data
	i_buf_write_data: distribuf
		generic map (
			WDATA  => WWEIGHT,
			NBOUT  => NBNEU,
			FANOUT => FANOUT
		)
		port map (
			clk   => clk,
			idata => write_data,
			odata => arr_write_data
		);

	-- Fanout distribution tree: data_in
	i_buf_data_in: distribuf
		generic map (
			WDATA  => WDATA,
			NBOUT  => NBNEU,
			FANOUT => FANOUT
		)
		port map (
			clk   => clk,
			idata => data_in,
			odata => arr_data_in
		);

	-- ctrl_we_mode distribution tree
	i_ctrl_we_mode: distribuf
		generic map (
			WDATA  => 1,
			NBOUT  => NBNEU,
			FANOUT => FANOUT
		)
		port map (
			clk   => clk,
			idata => sg_ctrl_we_mode,
			odata => arr_ctrl_we_mode
		);

	-- ctrl_we_shift distribution tree
	i_ctrl_we_shift: distribuf
		generic map (
			WDATA  => 1,
			NBOUT  => NBNEU,
			FANOUT => FANOUT
		)
		port map (
			clk   => clk,
			idata => sg_ctrl_we_shift,
			odata => arr_ctrl_we_shift
		);

	-- ctrl_we_valid distribution tree
	i_ctrl_we_valid: distribuf
		generic map (
			WDATA  => 1,
			NBOUT  => NBNEU,
			FANOUT => FANOUT
		)
		port map (
			clk   => clk,
			idata => sg_ctrl_we_valid,
			odata => arr_ctrl_we_valid
		);

	-- ctrl_accu_clear distribution tree
	i_ctrl_accu_clear: distribuf
		generic map (
			WDATA  => 1,
			NBOUT  => NBNEU,
			FANOUT => FANOUT
		)
		port map (
			clk   => clk,
			idata => sg_ctrl_accu_clear,
			odata => arr_ctrl_accu_clear
		);

	-- ctrl_accu_add distribution tree
	i_ctrl_accu_add: distribuf
		generic map (
			WDATA  => 1,
			NBOUT  => NBNEU,
			FANOUT => FANOUT
		)
		port map (
			clk   => clk,
			idata => sg_ctrl_accu_add,
			odata => arr_ctrl_accu_add
		);

	-- ctrl_shift_en distribution tree
	i_ctrl_shift_en: distribuf
		generic map (
			WDATA  => 1,
			NBOUT  => NBNEU,
			FANOUT => FANOUT
		)
		port map (
			clk   => clk,
			idata => sg_ctrl_shift_en,
			odata => arr_ctrl_shift_en
		);

	-- ctrl_shift_copy distribution tree
	i_ctrl_shift_copy: distribuf
		generic map (
			WDATA  => 1,
			NBOUT  => NBNEU,
			FANOUT => FANOUT
		)
		port map (
			clk   => clk,
			idata => sg_ctrl_shift_copy,
			odata => arr_ctrl_shift_copy
		);

	-- we_mode distribution tree
	i_addr: distribuf
		generic map (
			WDATA  => WADDR,
			NBOUT  => NBNEU,
			FANOUT => FANOUT
		)
		port map (
			clk   => clk,
			idata => sg_addr,
			odata => arr_addr
		);

	-------------------------------------------------------------------
	-- Instantiate the neurons
	-------------------------------------------------------------------

	gen_neu: for i in 0 to NBNEU-1 generate
		i_neu_normal: neuron
			generic map (
				-- Parameters for the neurons
				WDATA   => WDATA,
				WWEIGHT => WWEIGHT,
				WACCU   => WACCU,
				-- Parameters for the frame size
				FSIZE   => FSIZE,
				WADDR   => WADDR
			)
			port map (
				clk             => clk,
				-- Control signals
				ctrl_we_mode    => arr_ctrl_we_mode(i),
				ctrl_we_shift   => arr_ctrl_we_shift(i),
				ctrl_we_valid   => arr_ctrl_we_valid(i),
				ctrl_accu_clear => arr_ctrl_accu_clear(i),
				ctrl_accu_add   => arr_ctrl_accu_add(i),
				ctrl_shift_en   => arr_ctrl_shift_en(i),
				ctrl_shift_copy => arr_ctrl_shift_copy(i),
				-- Address used for Read and Write
				addr            => arr_addr((i+1)*WADDR-1 downto i*WADDR),
				-- Ports for Write Enable
				we_prev         => we_match(i),
				we_next         => we_match(i + 1),
				write_data      => arr_write_data((i+1)*WWEIGHT-1 downto i*WWEIGHT),
				-- Data input, 2 bits
				data_in         => arr_data_in((i+1)*WDATA-1 downto i*WDATA),
				-- Scan chain to extract values
				-- Inversed from we_prev and we_next
				sh_data_in      => sh_data_match(i+1),
				sh_data_out     => sh_data_match(i),
				-- Sensors, for synchronization with the controller
				-- We use only the first (we suppose that synthesis will remove wires)
				sensor_shift    => sensors_shift_match(i),
				sensor_copy     => sensors_copy_match(i),
				sensor_we_mode  => sensors_we_mode_match(i),
				sensor_we_shift => sensors_we_shift_match(i),
				-- Not used
				sensor_we_valid => open
			);
	end generate;

	-------------------------------------------------------------------
	-- Instantiate the FSM
	-------------------------------------------------------------------
	fsm_gen: fsm
		generic map (
			NB_NEURONS => NBNEU,
			WDATA => WDATA,
			WWEIGHT => WWEIGHT,
			WACCU => WACCU,
			FSIZE => FSIZE,
			WADDR => WADDR
		)
		port map (
			reset => clear,
			clk => clk,
			ctrl_we_mode => sg_ctrl_we_mode(0),
			ctrl_we_shift => sg_ctrl_we_shift(0),
			ctrl_we_valid => sg_ctrl_we_valid(0),
			ctrl_accu_clear => sg_ctrl_accu_clear(0),
			ctrl_accu_add => sg_ctrl_accu_add(0),
			ctrl_shift_en => sg_ctrl_shift_en(0),
			ctrl_shift_copy => sg_ctrl_shift_copy(0),
			addr => sg_addr,
			n0_we_prev => we_match(0),
			nN_we_next => we_match(NBNEU),
			sensor_shift    => sensors_shift_match(0),
			sensor_copy     => sensors_copy_match(0),
			sensor_we_mode  => sensors_we_mode_match(0),
			sensor_we_shift => sensors_we_shift_match(0),
			sensor_we_valid => sg_sensor_we_valid,
			fsm_mode => write_mode,
			out_fifo_in_cnt => sg_out_fifo_in_cnt
			--out_fifo_in_ack => sg_out_fifo_in_ack
		);
	sg_sensor_we_valid <= (data_in_valid and not(write_mode)) or (write_enable and write_mode);
	data_in_ready <= sg_ctrl_accu_add(0) and not(write_mode);
	write_ready <= sg_ctrl_we_valid(0) and write_mode;
	sg_out_fifo_in_cnt <= out_fifo_room;


	data_out <= sh_data_match(0);
	sh_data_match(NBNEU) <= std_logic_vector(to_unsigned(0, sh_data_match(NBNEU)'length));
	--data_out_valid <= sg_out_fifo_in_ack;
	data_out_valid <= sensors_shift_match(0);

	end_of_frame <= '0';

end architecture;
