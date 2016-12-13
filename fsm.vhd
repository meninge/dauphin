-- Implementation of the FSM for a nnlayer 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fsm is
	generic (
		-- global parameters of layers
		NB_NEURONS: natural := 200;
		-- parameters of a neuron
		WDATA   : natural := 16;
		WWEIGHT : natural := 16;
		WACCU   : natural := 32;
		-- Parameters for the frame size
		FSIZE   : natural := 1000;
		WADDR   : natural := 10
	);
	port (
		reset         : in  std_logic;
		clk           : in  std_logic;
		-- Control signals
		-- (go to all neurons)
		ctrl_we_mode    : out  std_logic;
		ctrl_we_shift   : out  std_logic;
		ctrl_we_valid   : out  std_logic;
		ctrl_accu_clear : out  std_logic;
		ctrl_accu_add   : out  std_logic;
		ctrl_shift_en   : out  std_logic;
		ctrl_shift_copy : out  std_logic;
		-- Address used for Read and Write
		-- (go to all neurons)
		addr            : out  std_logic_vector(WADDR-1 downto 0);
		-- Ports for Write Enable
		-- go to first neuron
		n0_we_prev         : out  std_logic;
		-- go to last neuron
		nN_we_next         : in std_logic;
		-- Sensors, for synchronization with the controller
		-- go to first neurons
		sensor_shift    : in std_logic;
		sensor_copy     : in std_logic;
		sensor_we_mode  : in std_logic;
		sensor_we_shift : in std_logic;
		sensor_we_valid : in std_logic;

		-- inputs
		fsm_mode	: in std_logic;

		-- output FIFO control
		out_fifo_in_ack: out std_logic;
		out_fifo_in_cnt: in std_logic_vector(WDATA-1 downto 0)
		
	);
end fsm;

architecture synth of fsm is

	type STATE is (RESET_STATE, MODE_WEIGHT, NOTIFY_1N, WAIT_NOTIFY, 
	WAIT_WEIGHT, SEND_WEIGHT, WAIT_DATA, END_ACC, SHIFT_NOTIFY, END_CONFIG, MODE_ACC, WAIT_1D, SEND_DATA,
       	SHIFT_MODE, SHIFT_CPY, SHIFT, WAIT_SHIFT_CPY, WAIT_SHIFT);
	-- Internal signals

	-- state of mirror FSM
	signal current_state_mirror, next_state_mirror : STATE; 
	-- state of neurons accumulation FSM
	signal current_state_acc, next_state_acc : STATE;
	-- address counter for weight loading or neurons classic accumulation
	signal current_addr, next_addr : std_logic_vector(WADDR-1 downto 0); 
	-- counter for mirror chain
	signal current_shift_counter, next_shift_counter : std_logic_vector(15 downto 0);

	-- flag to signal mirror that it can do its things
	signal flag_mirror_chain, next_flag_mirror_chain : std_logic;
	signal first_neuron : std_logic := '0';
	signal next_first_neuron : std_logic := '0';
begin

	------------------------
	-- Sequential process --
	------------------------

	process (clk)
	begin
		if rising_edge(clk) then
			if (reset = '1') then 
				current_state_acc <= RESET_STATE;
				current_state_mirror <= RESET_STATE;
				first_neuron <= '0';
			else
				-- present = next variable
				
				-- state of mirror FSM
				current_state_mirror <= next_state_mirror;
				-- state of neurons accumulation FSM
				current_state_acc<= next_state_acc;
				-- address counter for weight loading or neurons classic accumulation
				current_addr <= next_addr; 
				-- counter for mirror chain
				current_shift_counter <= next_shift_counter;
				-- flag for mirror chain fsm
				flag_mirror_chain <= next_flag_mirror_chain;

				first_neuron <= next_first_neuron;

			end if;
		end if;
	end process;


	-----------------------------
	-- Combinatorial processes --
	-----------------------------
	
	-- La liste de sensibilite doit contenir tous les signaux sur les quels on fait des 'if' par exemple

	-- process to handle classic neurons accumulation and weight loading
	process (current_state_acc, sensor_we_mode, sensor_we_shift, sensor_we_valid, current_addr, nN_we_next, fsm_mode)
		-- variable var_doin    : std_logic := '0';
	begin
		-- need to set all signals at each step

		case current_state_acc is
			when RESET_STATE =>
				ctrl_we_mode <= '0';
				ctrl_we_shift <= '0';
				ctrl_we_valid <= '0';
				ctrl_accu_clear <= '0';
				ctrl_accu_add <= '0';
				n0_we_prev <= '0';
				addr <= (others => '0'); 
				
				next_addr <= (others => '0');

				-- in case of reset, fsm goes to MODE_ACC 
				next_state_acc <= END_ACC;

			when MODE_WEIGHT =>
				ctrl_we_mode <= '1';
				ctrl_we_shift <= '0';
				ctrl_we_valid <= '0';
				ctrl_accu_clear <= '0';
				ctrl_accu_add <= '0';
				n0_we_prev <= '0';
				addr <= current_addr; 
				
				next_addr <= (others => '0');

				-- if neurons has got mode_switch signal
				-- goes to NOTIFY1N
				if (sensor_we_mode = '1') then
					next_first_neuron <= '1';
					next_state_acc <= NOTIFY_1N;
				else
					next_state_acc <= MODE_WEIGHT;
				end if;

			when NOTIFY_1N =>
				ctrl_we_mode <= '1';
				ctrl_we_valid <= '0';
				ctrl_accu_clear <= '0';
				ctrl_accu_add <= '0';
				addr <= current_addr; 
				
				next_addr <= (others => '0');

				-- init addr
				next_addr <= (others => '0');

				if ( sensor_we_shift = '1') then
					ctrl_we_shift <= '0';
					next_state_acc <= WAIT_WEIGHT;
					n0_we_prev <= '1';
				else
					if (first_neuron = '1') then
						ctrl_we_shift <= '1';
						next_first_neuron <= '0';
						next_state_acc <= NOTIFY_1N;
					else
						ctrl_we_shift <= '0';
						next_state_acc <= NOTIFY_1N;
					end if;
				end if;

			when WAIT_NOTIFY =>
				ctrl_we_mode <= '1';
				ctrl_we_shift <= '0';
				ctrl_we_valid <= '0';
				ctrl_accu_clear <= '0';
				ctrl_accu_add <= '0';
				n0_we_prev <= '0';
				addr <= current_addr; 
				
				next_addr <= (others => '0');

				if (nN_we_next = '1') then
					next_state_acc<= END_CONFIG;
				else
					if (sensor_we_shift = '1') then
						next_state_acc <= WAIT_WEIGHT;	
					else 
						next_state_acc <= WAIT_NOTIFY;	
					end if;
				end if;

			when WAIT_WEIGHT =>
			-- data is here if sensor_we_valid = '1'
			-- meaning that data is out of distribuf
				ctrl_we_mode <= '1';
				ctrl_we_shift <= '0';
				ctrl_we_valid <= '0';
				ctrl_accu_clear <= '0';
				ctrl_accu_add <= '0';
				n0_we_prev <= '0';
				addr <= current_addr; 

				next_addr <= current_addr;

				if (sensor_we_valid = '1') then
					next_state_acc <= SEND_WEIGHT;
				else
					next_state_acc <= WAIT_WEIGHT;
				end if;

				
			when SEND_WEIGHT =>
				ctrl_we_mode <= '1';
				ctrl_we_shift <= '0';
				ctrl_we_valid <= '1';
				ctrl_accu_clear <= '0';
				ctrl_accu_add <= '0';
				n0_we_prev <= '0';
				addr <= current_addr;

				-- incr addr for next round
				next_addr <= std_logic_vector(unsigned(current_addr) + 1);
				
				if ( unsigned(current_addr) = FSIZE - 1) then
					next_state_acc <= SHIFT_NOTIFY;
				else
					next_state_acc <= WAIT_WEIGHT;
				end if;

			when SHIFT_NOTIFY =>
				ctrl_we_mode <= '1';
				ctrl_we_shift <= '1';
				ctrl_we_valid <= '0';
				ctrl_accu_clear <= '0';
				ctrl_accu_add <= '0';
				n0_we_prev <= '0';
				addr <= current_addr;

				next_addr <= (others => '0');
					
				next_state_acc <= WAIT_NOTIFY;

			when END_CONFIG =>
				ctrl_we_mode <= '0';
				ctrl_we_shift <= '0';
				ctrl_we_valid <= '0';
				ctrl_accu_clear <= '0';
				ctrl_accu_add <= '0';
				n0_we_prev <= '0';
				addr <= current_addr;

				next_addr <= (others => '0');
					
				next_state_acc <= WAIT_NOTIFY;


			when MODE_ACC => 
			-- we need to switch to weight mode if C program said so
				ctrl_we_mode <= '0';
				ctrl_we_shift <= '0';
				ctrl_we_valid <= '0';
				ctrl_accu_clear <= '0';
				ctrl_accu_add <= '0';
				n0_we_prev <= '0';
				addr <= current_addr;

				next_addr <= (others => '0');
					
				if (sensor_we_mode = '0') then
					next_state_acc <= WAIT_1D;
				else 
					next_state_acc <= MODE_ACC;
				end if;

			when WAIT_1D =>
				ctrl_we_mode <= '0';
				ctrl_we_shift <= '0';
				ctrl_we_valid <= '0';
				ctrl_accu_clear <= '1';
				ctrl_accu_add <= '0';
				n0_we_prev <= '0';
				addr <= current_addr;

				next_addr <= (others => '0');
					
				if (sensor_we_valid= '1') then
					next_state_acc <= SEND_DATA;
				else 
					next_state_acc <= WAIT_1D;
				end if;

			when SEND_DATA =>
				ctrl_we_mode <= '0';
				ctrl_we_shift <= '0';
				ctrl_we_valid <= '0';
				ctrl_accu_clear <= '0';
				ctrl_accu_add <= '1';
				n0_we_prev <= '0';
				addr <= current_addr;

				-- incr addr for next round
				next_addr <= std_logic_vector( unsigned(current_addr) + 1);
					
				if ( unsigned(current_addr) = FSIZE - 1 ) then
					next_state_acc <= END_ACC;
				else 
					next_state_acc <= WAIT_DATA;
				end if;
				
			when WAIT_DATA => 
				ctrl_we_mode <= '0';
				ctrl_we_shift <= '0';
				ctrl_we_valid <= '0';
				ctrl_accu_clear <= '0';
				ctrl_accu_add <= '0';
				n0_we_prev <= '0';
				addr <= current_addr;

				next_addr <= current_addr;
					
				if ( sensor_we_valid = '1') then
					next_state_acc <= SEND_DATA;
				else
					next_state_acc <= WAIT_DATA;
				end if;
				
			when END_ACC => 
				ctrl_we_mode <= '0';
				ctrl_we_shift <= '0';
				ctrl_we_valid <= '0';
				ctrl_accu_clear <= '0';
				ctrl_accu_add <= '0';
				n0_we_prev <= '0';
				addr <= current_addr;

				next_addr <= current_addr;

				-- need to pass flag to mirror FSM
				next_flag_mirror_chain <= '1';
					
				-- mode switching before
				-- going again in acc loop again 
				if (fsm_mode = '1') then
					next_state_acc <= MODE_WEIGHT;
				else
					next_state_acc <= WAIT_1D;
				end if;
			when others =>
		end case;

	end process;

	-- process to handle mirror chain monitoring
	process (current_state_mirror, current_shift_counter, sensor_shift, sensor_copy, flag_mirror_chain)
	begin
		-- signals that are just up for one cycle go there
		out_fifo_in_ack <= '0';
		case current_state_mirror is
			when SHIFT_MODE =>
				ctrl_shift_copy <= '0';
				ctrl_shift_en <= '0';
				next_shift_counter <= (others => '0');

				if (flag_mirror_chain = '1') then
					next_flag_mirror_chain <= '0';
					next_state_mirror <= SHIFT_CPY;
				else
					next_state_mirror <= SHIFT_MODE;
				end if;

			when SHIFT_CPY =>
				-- copy accumulated value to mirror buffer
				ctrl_shift_copy <= '1';
				ctrl_shift_en<= '0';
				next_shift_counter <= (others => '0');

				next_state_mirror <= WAIT_SHIFT_CPY;

			when WAIT_SHIFT_CPY =>
				ctrl_shift_copy <= '0';
				ctrl_shift_en<= '0';
				next_shift_counter <= (others => '0');

				if (sensor_copy = '1') then
					next_state_mirror <= SHIFT;
				else
					next_state_mirror <= WAIT_SHIFT_CPY;
				end if;

			when SHIFT =>
				ctrl_shift_copy <= '0';
				ctrl_shift_en <= '1';
				out_fifo_in_ack <= '1';
				-- loop until we emptied all neurons mirrors

				next_shift_counter <= std_logic_vector( unsigned (current_shift_counter ) +1);

				if (unsigned (current_shift_counter) = NB_NEURONS -1) then
					next_state_mirror <= SHIFT_MODE;
				else
					next_state_mirror <= SHIFT;
				end if;

			when WAIT_SHIFT => 
				-- TODO optimize with out_fifo_in_cnt 
				ctrl_shift_copy <= '0';
				ctrl_shift_en<= '0';
				next_shift_counter <= (others => '0');

				if (sensor_shift = '1') then
					next_state_mirror <= SHIFT;
				else
					next_state_mirror <= WAIT_SHIFT;
				end if;
			when others =>
		end case;

	end process; 


end architecture;
