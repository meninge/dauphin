
-- This is one neuron

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity neuron is
	generic (
		-- Parameters for the neurons
		WDATA   : natural := 32;
		WWEIGHT : natural := 16;
		WACCU   : natural := 32;
		-- Parameters for the frame size
		FSIZE   : natural := 784;
		WADDR   : natural := 10
	);
	port (
		clk             : in  std_logic;
		-- Control signals, test
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
		write_data      : in  std_logic_vector(WDATA-1 downto 0);
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
	-- Registre contenant l'accumulation du DSP
	signal accu : signed(47 downto 0) := (others => '0');
	-- Registre contenant la copy de l'accu
	signal mirror : std_logic_vector(WACCU-1 downto 0) := (others => '0');

	-- Registre memorisant si on se trouve dans un etat de config
	signal reg_config : std_logic := '0';

	-- output signals
	signal out_sensor_shift    : std_logic := '0';
	signal out_sensor_copy     : std_logic := '0';
	signal out_sensor_we_mode  : std_logic := '0';
	signal out_sensor_we_shift : std_logic := '0';

	signal weight : std_logic_vector(WWEIGHT-1 downto 0);

	signal write_data_in : std_logic_vector(WWEIGHT-1 downto 0);
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
	signal en_ram : std_logic := '0';
begin
	-------------------------------------------------------------------
	-- instanciation of component
	-------------------------------------------------------------------
	i_ram: ram
	generic map (

			WDATA  => WWEIGHT,
			SIZE => FSIZE,
			WADDR => WADDR
		)
	port map (
		clk	=> clk,
		we	=> we_ram,
		en	=> en_ram,
		addr	=> addr,
		di	=> write_data_in,
		do	=> weight
		);

	---------------------------------------------
	----------- Sequential processes ------------
	---------------------------------------------

	mac : process (clk)
	begin
		if rising_edge(clk) then
			-- Mode accumulation
			if (ctrl_we_mode = '0') then
				-- we need to clear accu
				if (ctrl_accu_clear = '1') then
					accu <= (others => '0');
					-- data available
				elsif (ctrl_accu_add = '1') then
					accu <= accu + signed(data_in(24 downto 0))*(resize(signed(weight), 18));
				end if;
			end if;
		end if;
	end process mac;

	shift: process (clk)
	begin
		if (rising_edge(clk)) then
			-- we have to copy the accu reg into the miroir reg
			if ((ctrl_shift_copy = '1')) then
				mirror <= std_logic_vector(accu(WACCU-1 downto 0));
			elsif (ctrl_shift_en = '1') then
				-- we have to shift the miroir prev into the miroir next
				mirror <= sh_data_in;
			end if;
		end if;
	end process;


	reg_conf : process (clk)
	begin
		if rising_edge(clk) then
			if (ctrl_we_mode = '1') and (ctrl_we_shift = '1') then
				-- update the reg_config
				reg_config <= we_prev;
			end if;

		end if;
	end process reg_conf;


	---------------------------------------------
	--------- Combinatorial processes -----------
	---------------------------------------------

	sensor : process (ctrl_we_mode, ctrl_we_shift, ctrl_shift_copy, ctrl_shift_en)
	begin
		-- updating the reg_conf
		if (ctrl_we_shift = '1') then
			-- notify the fsm
			out_sensor_we_shift <= '1';
		else
			out_sensor_we_shift <= '0';
		end if;
		if (ctrl_we_mode = '1') then
			out_sensor_we_mode <= '1';
		else
			out_sensor_we_mode <= '0';
		end if;
		-- we have to copy the accu reg into the miroir reg
		if (ctrl_shift_copy = '1') then
			out_sensor_copy <= '1';
		else
			out_sensor_copy <= '0';
		end if;
		-- we have to shift the miroir prev into the miroir next
		if (ctrl_shift_en = '1') then
			out_sensor_shift <= '1';
		else
			out_sensor_shift <= '0';
		end if;
	end process sensor;

	---------------------------------------------
	----------- Ports assignements --------------
	---------------------------------------------

	en_ram <= '1';
	we_ram <= ctrl_we_mode and reg_config and not(ctrl_we_shift);
	we_next <= reg_config;
	sh_data_out <= mirror;
	-- not used, but need to be set
	sensor_we_valid <= '1';

	sensor_shift <= out_sensor_shift;
	sensor_copy <= out_sensor_copy;
	sensor_we_mode <= out_sensor_we_mode;
	sensor_we_shift <= out_sensor_we_shift;

	-- to get right conversion for the BRAM
	write_data_in <= std_logic_vector(resize(signed(write_data), WWEIGHT));

end architecture;
