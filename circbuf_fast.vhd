
-- FIFO implemented as a circular buffer

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity circbuf_fast is
	generic (
		DATAW : natural := 32;
		DEPTH : natural := 8;
		CNTW  : natural := 16
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
end circbuf_fast;

architecture synth of circbuf_fast is

	-- Compute the minimum number of bits needed to store the input value
	function storebitsnb(vin : natural) return natural is
		variable r : natural := 1;
		variable v : natural := vin;
	begin
		loop
			exit when v <= 1;
			r := r + 1;
			v := v / 2;
		end loop;
		return r;
	end function;

	-- Compute the minimum number of bits needed to store the input value
	function ispower2(vin : natural) return boolean is
	begin
		if storebitsnb(vin-1) /= storebitsnb(vin) then return true; end if;
		return false;
	end function;

	-- The needed index width
	constant IDXW : natural := storebitsnb(DEPTH-1);
	-- Detect when the number of cells is power of 2, this enables to skip some tests
	constant DEPTHISPOW2 : boolean := ispower2(DEPTH);

	-- The embedded memory
	type mem_type is array (0 to DEPTH-1) of std_logic_vector(DATAW-1 downto 0);
	signal mem : mem_type := (others => (others => '0'));

	attribute ram_style : String;
	attribute ram_style of mem : signal is "distributed";

	-- Internal registers
	signal idx_in, idx_in_n   : unsigned(IDXW-1 downto 0) := to_unsigned(0, IDXW);
	signal idx_out, idx_out_n : unsigned(IDXW-1 downto 0) := to_unsigned(0, IDXW);

	signal reg_cnt_in, reg_cnt_in_n   : unsigned(CNTW-1 downto 0) := to_unsigned(0, CNTW);
	signal reg_cnt_out, reg_cnt_out_n : unsigned(CNTW-1 downto 0) := to_unsigned(0, CNTW);

	signal reg_in2out, reg_in2out_n : std_logic;
	signal reg_out2in, reg_out2in_n : std_logic;

	signal regout_data : std_logic_vector(DATAW-1 downto 0) := (others => '0');

	signal regin_rdy, regin_rdy_n   : std_logic := '1';
	signal regout_rdy, regout_rdy_n : std_logic := '0';

	-- Signals for mem write enable and read enable
	signal sigmem_ren : std_logic := '0';
	signal sigmem_wen : std_logic := '0';

	-- Signals to enable update the in and out indexes
	signal idx_in_we  : std_logic := '0';
	signal idx_out_we : std_logic := '0';

begin

	-- Sequential process
	process (clk)
	begin
		if rising_edge(clk) then

			if idx_in_we = '1' then
				idx_in <= idx_in_n;
			end if;

			if idx_out_we = '1' then
				idx_out <= idx_out_n;
			end if;

			reg_cnt_in  <= reg_cnt_in_n;
			reg_cnt_out <= reg_cnt_out_n;

			reg_in2out <= reg_in2out_n;
			reg_out2in <= reg_out2in_n;

			regin_rdy  <= regin_rdy_n;
			regout_rdy <= regout_rdy_n;

			-- Write the input value to the memory
			if sigmem_wen = '1' then
				mem(to_integer(idx_in)) <= fifo_in_data;
			end if;

			-- Read the output value from the memory
			if sigmem_ren = '1' then
				regout_data <= mem(to_integer(idx_out));
			end if;

		end if;
	end process;

	-- Combinatorial process
	process (
		reset,
		reg_cnt_in, reg_cnt_out,
		reg_in2out, reg_out2in,
		idx_in, idx_out,
		regin_rdy, regout_rdy,
		fifo_in_ack, fifo_out_ack
	)
		variable var_doin    : std_logic := '0';
		variable var_doout   : std_logic := '0';
		variable var_cnt_inc : unsigned(CNTW-1 downto 0) := to_unsigned(0, CNTW);
	begin

		-- Default values for the variables

		var_doin  := '0';
		var_doout := '0';

		-- Default next values for internal registers

		idx_in_we  <= '0';
		idx_out_we <= '0';

		idx_in_n  <= idx_in;
		idx_out_n <= idx_out;

		reg_cnt_in_n  <= reg_cnt_in;
		reg_cnt_out_n <= reg_cnt_out;

		reg_in2out_n <= '0';
		reg_out2in_n <= '0';

		regin_rdy_n  <= regin_rdy;
		regout_rdy_n <= regout_rdy;

		-- Default values for internal signals

		sigmem_wen <= '0';
		sigmem_ren <= '0';

		-- Handle FIFO input
		if (regin_rdy = '1') and (fifo_in_ack = '1') then
			sigmem_wen   <= '1';
			var_doin     := '1';
			idx_in_we    <= '1';
			reg_in2out_n <= '1';
		end if;

		-- Handle FIFO output
		if (regout_rdy = '1') and (fifo_out_ack = '1') then
			sigmem_ren   <= '1';
			var_doout    := '1';
			idx_out_we   <= '1';
			reg_out2in_n <= '1';
			-- Don't increment index when reading the last value
			if reg_cnt_out = 1 then
				sigmem_ren <= '0';
				idx_out_we <= '0';
			end if;
		end if;

		-- Increment the output counter by +1 if doing only input, or -1 if doing only output
		var_cnt_inc(CNTW-1 downto 1) := (others => var_doout and not reg_in2out);
		var_cnt_inc(0) := var_doout xor reg_in2out;
		-- Next value for the counter
		reg_cnt_out_n <= reg_cnt_out + var_cnt_inc;

		-- Increment the input counter by +1 if doing only output, or -1 if doing only input
		var_cnt_inc(CNTW-1 downto 1) := (others => var_doin and not reg_out2in);
		var_cnt_inc(0) := var_doin xor reg_out2in;
		-- Next value for the counter
		reg_cnt_in_n <= reg_cnt_in + var_cnt_inc;

		-- Next value for the in_rdy register
		if reg_cnt_in = 1 then
			regin_rdy_n <= (not var_doin) or reg_out2in;
		end if;

		-- Next value for the out_rdy register
		if reg_cnt_out = 1 then
			regout_rdy_n <= not var_doout;
		end if;

		-- Perform one mem read to initialize the output register
		if (reg_cnt_out = 1) and (regout_rdy = '0') then
			sigmem_ren   <= '1';
			regout_rdy_n <= '1';
			idx_out_we   <= '1';
		end if;

		-- Systematically compute the next value of the in index
		idx_in_n <= idx_in + 1;
		if (DEPTHISPOW2 = false) and (idx_in = DEPTH-1) then
			idx_in_n <= to_unsigned(0, IDXW);
		end if;

		-- Systematically compute the next value of the out index
		idx_out_n <= idx_out + 1;
		if (DEPTHISPOW2 = false) and (idx_out = DEPTH-1) then
			idx_out_n <= to_unsigned(0, IDXW);
		end if;

		-- Handle reset
		-- Note: The memory content is not affected by reset
		if reset = '1' then
			idx_in_n      <= to_unsigned(0, IDXW);
			idx_out_n     <= to_unsigned(0, IDXW);
			reg_cnt_in_n  <= to_unsigned(DEPTH, CNTW);
			reg_cnt_out_n <= to_unsigned(0, CNTW);
			regin_rdy_n   <= '1';
			regout_rdy_n  <= '0';
			idx_in_we     <= '1';
			idx_out_we    <= '1';
		end if;

	end process;

	-- Assignment of top-level ports
	fifo_in_rdy   <= regin_rdy;
	fifo_out_rdy  <= regout_rdy;
	fifo_out_data <= regout_data;

	fifo_in_cnt  <= std_logic_vector(reg_cnt_in);
	fifo_out_cnt <= std_logic_vector(reg_cnt_out);

end architecture;

