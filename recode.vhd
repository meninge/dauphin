
-- This block recodes data on-the-fly

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity recode is
	generic(
		WDATA : natural := 16;
		WOUT  : natural := 16;
		FSIZE : natural := 784
	);
	port(
		clk             : in  std_logic;
		-- Ports for address control
		addr_clear      : in  std_logic;
		-- Ports for Write into memory
		write_mode      : in  std_logic;
		write_data      : in  std_logic_vector(31 downto 0);
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
end recode;

architecture synth of recode is

begin

	-------------------------------------------------------------------
	-- Dummy functionality
	-------------------------------------------------------------------

	write_ready    <= '1';

	data_in_ready  <= '1' when unsigned(out_fifo_room) > 0 else '0';

	data_out       <= std_logic_vector(resize(signed(data_in), WOUT));
	data_out_valid <= data_in_valid;

end architecture;


