
-- This is one neuron

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity neuron is
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
end neuron;

architecture synth of neuron is

begin
	-------------------------------------------------------------------
	-- Output ports
	-------------------------------------------------------------------

	we_next         <= '0';

	sh_data_out     <= (others => '0');

	sensor_shift    <= '0';
	sensor_copy     <= '0';
	sensor_we_mode  <= '0';
	sensor_we_shift <= '0';
	sensor_we_valid <= '0';

end architecture;


