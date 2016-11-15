-- Implementation of the FSM for a nnlayer 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dsp is
	generic (
	);
	port (
		reset         : in  std_logic;
		clk           : in  std_logic;
	);
end dsp;

architecture synth of dsp is

	--Signaux interne
begin

	-- Sequential process
	process (clk)
	begin
		if rising_edge(clk) then
			if (reset = '1') then 
				current_state <= RESET_STATE;
			else
				-- present = next variable
			end if;
		end if;
	end process;

	-- Combinatorial process
	-- La liste de sensibilitÃ doit contenir tous les signaux sur les quels on fait des 'if' par exemple
	process ()
		-- variable var_doin    : std_logic := '0';
	begin

	end process;

	-- Assignment of top-level ports

end architecture;
