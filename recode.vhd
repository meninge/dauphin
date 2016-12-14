
-- This block recodes data on-the-fly

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity recode is
	generic(
		WDATA : natural := 16;
		WOUT  : natural := 16;
		FSIZE : natural := 200 -- warning, this is NB_NEU
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
end recode;

architecture synth of recode is

	type STATE is (RESET, WRITE_INPUT, WRITE_WAIT, DATA);

	signal current_state : STATE := RESET;
	signal next_state : STATE := RESET;

	-- table containing constants to add to incoming neuron data.
	type ram_t is array (0 to FSIZE-1) of std_logic_vector(WDATA-1 downto 0);
	signal ram : ram_t := (others => (others => '0'));

	signal addr : natural := 0;
	signal next_addr : natural := 0;


begin
	-- Sequential process
	process (clk)
	begin
		if rising_edge(clk) then
			if (addr_clear = '1') then
				current_state <= RESET;
			else
				current_state <= next_state;
				addr <= next_addr;
			end if;
		end if;
	end process;

	process (clk, current_state, write_mode, write_enable, addr, out_fifo_room, data_in_valid)
	begin
			write_ready <= '0';
			data_out <= (others => '0');
			data_out_valid <= '0';
			data_in_ready <= '0';
			next_state <= RESET;

			case current_state is
				when RESET =>
					next_addr <= 0;
					if (write_mode = '1' and write_enable = '1') then
						next_state <= WRITE_INPUT;
					elsif (write_mode = '0' and data_in_valid = '1') then
						next_state <= DATA;
					else
						next_state <= RESET;
					end if;

				when WRITE_INPUT =>
					ram(addr) <= write_data;
					write_ready <= '1';
					next_addr <= addr + 1;
					if (addr = FSIZE-1) then
						next_state <= RESET;
					elsif (write_enable = '1') then
						next_state <= WRITE_INPUT;
					else
						next_state <= WRITE_WAIT;
					end if;

				when WRITE_WAIT =>
					if (write_enable = '1') then
						next_state <= WRITE_INPUT;
					else
						next_state <= WRITE_WAIT;
					end if;
				when DATA =>
					if ( unsigned(out_fifo_room) > 0 and data_in_valid = '1') then
						if (signed(data_in) + signed(ram(addr)) > 0) then
							data_out <= std_logic_vector(resize(signed(data_in) + signed(ram(addr)), WOUT));
						else
							data_out <= (others => '0');
						end if;
						data_out_valid <= '1';
						data_in_ready <= '1';
						next_addr <= addr +1;

						if (addr = FSIZE-1) then 
							next_state <= RESET;
						else
							next_state <= DATA;
						end if;
					else
						next_state <= DATA;
					end if;
				when others =>
			end case;
	end process;

	-- write_ready    <= '1';

	-- data_in_ready  <= '1' when unsigned(out_fifo_room) > 0 else '0';

	-- data_out       <= std_logic_vector(resize(signed(data_in), WOUT));

	-- data_out_valid <= data_in_valid;

end architecture;


