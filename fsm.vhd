-- Implementation of the FSM for a nnlayer 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fsm is
	generic (
		DATAW : natural := 32;
		DEPTH : natural := 8;
		CNTW  : natural := 16
	);
	port (
		reset         : in  std_logic;
		clk           : in  std_logic;
	);
end fsm;

architecture synth of fsm is

	type STATE is (RESET_STATE, MODE_WEIGHT, NOTIFY_1N, WAIT_WEIGHT, SEND_WEIGHT, WAIT_DATA, SHIFT_NOTIFY, END_CONFIG, MODE_ACC, WAIT_1D, SEND_DATA, SHIFT_MODE, SHIFT_CPY, SHIFT);
	--Signaux interne
	signal current_state, next_state : STATE;
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
	process (current_state)
		-- variable var_doin    : std_logic := '0';
	begin
		case current_state is
			when RESET_STATE =>

			when MODE_WEIGHT =>

			when NOTIFY_1N => 

			when WAIT_WEIGHT =>
				
			when SEND_WEIGHT =>

			when WAIT_DATA => 

			when SHIFT_NOTIFY =>

			when END_CONFIG =>

			when MODE_ACC => 

			when WAIT_1D =>

			when SEND_DATA =>
		end case;

	end process;

	process (current_state)
	begin
		case current_state is
			when SHIFT_MODE =>

			when SHIFT_CPY =>

			when SHIFT =>

		end case;

	end process; 

	-- Assignment of top-level ports

end architecture;
