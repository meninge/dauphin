
-- This is one neuron

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity neuron is
	generic (
		-- Parameters for the neurons
		WDATA   : natural := 16;
		WWEIGHT : natural := 16;
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
end neuron;

architecture synth of neuron is
	-- BRAM qui contient tous les coés
	type ram_t is array (0 to FSIZE-1) of std_logic_vector(15 downto 0);
	signal ram : ram_t := (others => (others => '0'));

	-- Registre contenant l'accumulation du DSP
	signal accu : std_logic_vector(47 downto 0);
	-- Registre contenant la copy de l'accu
	signal miroir : std_logic_vector(47 downto 0);
	-- TODO : miroir et accu sur 32 bits
	
	-- Registre mémorisant si on se trouve dans un �tat de config
	signal reg_config : std_logic;
begin
	-------------------------------------------------------------------
	-- Output ports
	-------------------------------------------------------------------

	mac : process (clk, ctrl_we_mode, ctrl_accu_add)
	begin 
		if rising_edge(clk) then
			-- Mode accumulation
			if (ctrl_we_mode = '0') then
				-- we need to clear accu
				if (ctrl_accu_clear = '1') then
					accu <= (others => '0');
				-- data available on input
				elsif (ctrl_accu_add = '1') then
					if ((unsigned(addr) >= 0) and (unsigned(addr) < FSIZE)) then
						accu <= accu + ("000000000"&data_in)*("00"&ram(to_integer(unsigned(addr))));
					end if;
				end if;
			end if;
		end if;
	end process mac;

	shift : process (clk, ctrl_we_mode, ctrl_shift_en, ctrl_shift_copy)
	begin 
		if rising_edge(clk) then
			-- Mode shift des data dans la chaine de miroirs
			if (ctrl_we_mode = '0') then
				-- we have to copy the accu reg into the miroir reg
				if (ctrl_shift_copy = '1') then
					miroir <= accu;
				elsif (ctrl_shift_en = '1') then
					-- we have to shift the miroir prev into the miroir next
					miroir <= sh_data_in;
				end if;
			end if;
		end if;
		sh_data_out <= miroir;
	end process ;

	sensor : process (ctrl_we_mode, ctrl_we_shift, ctrl_we_valid, ctrl_shift_copy, ctrl_shift_en)
	begin 
		if (ctrl_we_mode = '1') then
			sensor_we_mode <= '1';
			-- updating the reg_conf
			if (ctrl_we_shift = '1') then
				-- notify the fsm
				sensor_we_shift <= '1';
			end if;
		elsif (ctrl_we_mode = '0') then
			sensor_we_mode <= '0';
			-- we have to copy the accu reg into the miroir reg
			if (ctrl_shift_copy = '1') then
				sensor_copy <= '1';
			end if;
			-- we have to shift the miroir prev into the miroir next
			if (ctrl_shift_en = '1') then
				sensor_shift <= '1';
			end if;
		end if;
	end process sensor;

	reg_conf : process (clk, ctrl_we_mode, ctrl_we_shift)
	begin 
		if rising_edge(clk) then
			if (ctrl_we_mode = '1') and (ctrl_we_shift = '1') then
				-- update the reg_config
				reg_config <= we_prev;
			end if;
				
		end if;
		we_next <= reg_config;
	end process reg_conf;

	load_weight : process (clk, ctrl_we_mode, ctrl_we_shift, reg_config, ctrl_we_valid)
	begin 
		if rising_edge(clk) then
			-- data available on input
			if (ctrl_we_mode = '1') and (ctrl_we_valid = '1') then
				if (reg_config = '1') then
					-- our turn to get our config
					if (unsigned(addr) >= 0 and unsigned(addr) < FSIZE) then
						-- load all weight
						ram(unsigned(addr)) <= write_data;
					end if; 
				end if;
			end if;
		end if;
	end process load_weight;

	--we_next         <= '0';

	--sh_data_out     <= (others => '0');

	--sensor_shift    <= '0';
	--sensor_copy     <= '0';
	--sensor_we_mode  <= '0';
	--sensor_we_shift <= '0';
	--sensor_we_valid <= '0';

end architecture;
