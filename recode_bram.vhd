
-- This block recodes data on-the-fly

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity recode is
	generic(
		WDATA : natural := 32;
		WWEIGHT : natural := 16;
		WOUT  : natural := 32;
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
		write_ready     : out std_logic; -- not used
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
	--type ram_t is array (0 to FSIZE-1) of std_logic_vector(WWEIGHT-1 downto 0);
	--signal ram : ram_t := (others => (others => '0'));

	signal addr : integer := 0;
	signal next_addr : integer := 0;

	-- output signals
	signal out_write_ready : std_logic := '0';
	signal out_data_in_ready : std_logic := '0';
	signal out_data_out : std_logic_vector(WOUT-1 downto 0) := (others => '0');
	signal out_data_out_valid : std_logic := '0';
	signal cur_ram : std_logic_vector(WWEIGHT-1 downto 0);

	signal config_written : boolean := false;
	signal next_config_written : boolean := false;

	component ram is
		generic (
				WDATA : natural := 16;
				SIZE   : natural := 784;
				WADDR   : natural := 10

			);
		port (	clk : in std_logic;
			we : in std_logic;
			en : in std_logic;
			addr : in std_logic_vector(WADDR-1 downto 0);
			di : in std_logic_vector(WDATA-1 downto 0);
			do : out std_logic_vector(WDATA-1 downto 0));
	end component;
	signal we_ram : std_logic := '0';

begin

	-------------------------------------------------------------------
	-- instanciation of component
	-------------------------------------------------------------------
	i_ram: ram
	generic map (

			WDATA  => WWEIGHT,
			SIZE => FSIZE,
			WADDR => 10
		)
	port map (
		clk	=> clk,
		we	=> we_ram,
		en	=> '1',
		addr	=> std_logic_vector(to_unsigned(addr, 10)),
		di	=> write_data(WWEIGHT-1 downto 0),
		do	=> cur_ram
	);

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

			config_written <= next_config_written;

			if next_state = WRITE_INPUT then
				we_ram <= '1';
			else
				we_ram <= '0';
			end if;
		end if;
	end process;

	-- Process combinatoire de la FSM
	process (current_state, write_mode, write_enable, addr, out_fifo_room, data_in_valid, write_data, cur_ram, data_in)
	begin
			out_write_ready <= '0';
			out_data_out <= (others => '0');
			out_data_out_valid <= '0';
			out_data_in_ready <= '0';
			next_state <= RESET;
			next_addr <= 0;

			if (config_written = false) then
				next_config_written <= false;
			else
				next_config_written <= true;
			end if;

			case current_state is
				when RESET =>
					next_addr <= 0;
					if (write_mode = '1' and write_enable = '1') then
						if (not(config_written)) then
							next_state <= WRITE_INPUT;
						end if;
					elsif (write_mode = '0' and data_in_valid = '1') then
						next_state <= DATA;
					else
						next_state <= RESET;
					end if;

				when WRITE_INPUT =>
					next_config_written <= true;
					out_write_ready <= '1';
					next_addr <= addr + 1;
					if (addr = FSIZE - 1) then
						next_state <= RESET;
						next_addr <= 0;
					elsif (write_enable = '1') then
						next_state <= WRITE_INPUT;
					else
						next_state <= WRITE_WAIT;
					end if;

				when WRITE_WAIT =>
					next_addr <= addr;
					if (write_enable = '1') then
						next_state <= WRITE_INPUT;
					else
						next_state <= WRITE_WAIT;
					end if;
				when DATA =>
					if ( unsigned(out_fifo_room) > 0 and data_in_valid = '1') then
						if (signed(data_in) + signed(cur_ram) > 0) then
							out_data_out <= std_logic_vector(signed(data_in) + signed(cur_ram));
						else
							out_data_out <= (others => '0');
						end if;

						out_data_out_valid <= '1';
						out_data_in_ready <= '1';
						next_addr <= addr + 1;

						if (addr = FSIZE-1) then 
							next_config_written <= false;
							next_state <= RESET;
							next_addr <= 0;
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
	write_ready <= out_write_ready;
	data_in_ready <= out_data_in_ready;
	data_out <= out_data_out;
	data_out_valid <= out_data_out_valid;

end architecture;


