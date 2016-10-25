
-- This is multi-stage shift register designed to limit fanout
-- There is at least one register, there may be more depending on wanted fanout

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity distribuf is
	generic(
		WDATA :  natural := 20;
		NBOUT :  natural := 20;
		FANOUT : natural := 20
	);
	port(
		clk : in std_logic;
		-- Input
		idata : in std_logic_vector(WDATA-1 downto 0);
		-- Output
		odata : out std_logic_vector(WDATA*NBOUT-1 downto 0)
	);
end distribuf;

architecture synth of distribuf is

	-- Stupid compnent declaration for recursive instantiation
	component distribuf is
		generic(
			WDATA :  natural := 20;
			NBOUT :  natural := 20;
			FANOUT : natural := 20
		);
		port(
			clk : in std_logic;
			-- Input
			idata : in std_logic_vector(WDATA-1 downto 0);
			-- Outputs
			odata : out std_logic_vector(WDATA*NBOUT-1 downto 0)
		);
	end component;

	-- The number of registers needed in the local stage
	constant NBREGS : natural := (NBOUT + FANOUT - 1) / FANOUT;
	-- The registers, and the signal to compute their input
	signal regs, regs_n : std_logic_vector(NBREGS*WDATA-1 downto 0) := (others => '0');

begin

	-- If the fanout is low enough, just connect the input port to the registers
	gen_lowfan_in: if NBREGS <= FANOUT generate
		gen_lowfan_in_loop: for i in 0 to NBREGS-1 generate
			regs_n((i+1)*WDATA-1 downto i*WDATA) <= idata;
		end generate;
	end generate;

	-- If the fanout is high enough, recursively instantiate a sub-component
	gen_highfan_in: if NBREGS > FANOUT generate

		-- Instantiate the sub-stage
		i_stage: distribuf
			generic map (
				WDATA => WDATA,
				NBOUT => NBREGS,
				FANOUT => FANOUT
			)
			port map (
				clk => clk,
				idata => idata,
				odata => regs_n
			);

	end generate;

	-- Write to registers
	process(clk)
	begin
		if rising_edge(clk) then
			regs <= regs_n;
		end if;
	end process;

	-- Connect outputs: first guaranteed max-fanout outputs
	gen_maxfan: if NBREGS > 1 generate
		gen_maxfan_reg: for r in 0 to NBREGS-2 generate
			gen_maxfan_regloop: for i in r * FANOUT to (r+1) * FANOUT - 1 generate
				odata((i+1)*WDATA-1 downto i*WDATA) <= regs((r+1) * WDATA - 1 downto r * WDATA);
			end generate;
		end generate;
	end generate;

	-- Connect last outputs
	gen_lastout_loop: for i in (NBREGS-1) * FANOUT to NBOUT - 1 generate
		odata((i+1)*WDATA-1 downto i*WDATA) <= regs(NBREGS * WDATA - 1 downto (NBREGS-1) * WDATA);
	end generate;

end architecture;


