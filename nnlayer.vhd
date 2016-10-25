
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
		WACCU   : natural := 32;
		-- Parameters for frame and number of neurons
		FSIZE   : natural := 1000;
		NBNEU   : natural := 1000
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
end nnlayer;

architecture synth of nnlayer is

	-- Max fanout for signals distributed to all BRAM-based blocks
	constant FANOUT : natural := 2;

	-- The address to access neuron memory, read and write
	constant WADDR : natural := 16;

	-- Arrays of signals to instantiate the neurons
	signal arr_write_data : std_logic_vector(NBNEU*WWEIGHT-1 downto 0) := (others => '0');

	-- Component declaration: one neuron
	component neuron is
		generic (
			-- Parameters for the neurons
			WDATA   : natural := 16;
			WWEIGHT : natural := 16;
			WACCU   : natural := 32;
			-- Parameters for the frame size
			FSIZE   : natural := 1000;
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

	-------------------------------------------------------------------
	-- Instantiate the neurons
	-------------------------------------------------------------------

	gen_neu: for i in 0 to NBNEU-1 generate

		i_neu: neuron
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
				ctrl_we_mode    => '0',
				ctrl_we_shift   => '0',
				ctrl_we_valid   => '0',
				ctrl_accu_clear => '0',
				ctrl_accu_add   => '0',
				ctrl_shift_en   => '0',
				ctrl_shift_copy => '0',
				-- Address used for Read and Write
				addr            => (others => '0'),
				-- Ports for Write Enable
				we_prev         => '0',
				we_next         => open,
				write_data      => arr_write_data((i+1)*WWEIGHT-1 downto i*WWEIGHT),
				-- Data input, 2 bits
				data_in         => (others => '0'),
				-- Scan chain to extract values
				sh_data_in      => (others => '0'),
				sh_data_out     => open,
				-- Sensors, for synchronization with the controller
				sensor_shift    => open,
				sensor_copy     => open,
				sensor_we_mode  => open,
				sensor_we_shift => open,
				sensor_we_valid => open
			);

	end generate;

	-------------------------------------------------------------------
	-- Dummy functionality
	-------------------------------------------------------------------

	write_ready    <= '1';

	data_in_ready  <= '1';

	data_out       <= (others => '0');
	data_out_valid <= '1';

	end_of_frame   <= '0';

end architecture;


