-- Implementation of the FSM for a nnlayer

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity fsm is
	generic (
		-- global parameters of layers
		NB_NEURONS: natural := 200;
		-- parameters of a neuron
		WDATA   : natural := 16;
		WWEIGHT : natural := 16;
		WACCU   : natural := 48;
		-- Parameters for the frame size
		FSIZE   : natural := 784;
		WADDR   : natural := 10;
		FANOUT  : natural := 2;
		-- fifo count
		CNTW : natural := 16
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
		--out_fifo_in_ack: out std_logic;
		out_fifo_in_cnt: in std_logic_vector(CNTW-1 downto 0)
	);
end fsm;

architecture synth of fsm is

	type STATE is (RESET_STATE, MODE_WEIGHT, NOTIFY_1N, WAIT_NOTIFY,
	WAIT_WEIGHT, SEND_WEIGHT, WAIT_DATA, END_ACC, SHIFT_NOTIFY, END_CONFIG, MODE_ACC, WAIT_1D, SEND_DATA, MODE_FSM,
	SHIFT_MODE, SHIFT_CPY, SHIFT, WAIT_SHIFT_CPY, WAIT_SHIFT);
	-- Internal signals
	constant TMP_CST : integer := integer(( LOG( real(NB_NEURONS),real(FANOUT))));
	constant MIN_OUT_FIFO_IN_CNT : unsigned := to_unsigned(30, 32);
	constant OUT_FIFO_MARGIN : unsigned := to_unsigned(2,32);

	-- state of mirror FSM
	signal current_state_mirror: STATE := SHIFT_MODE;
	signal next_state_mirror : STATE := SHIFT_MODE;
	-- state of neurons accumulation FSM
	signal current_state_acc: STATE := RESET_STATE;
	signal next_state_acc : STATE := RESET_STATE;
	-- address counter for weight loading or neurons classic accumulation
	signal current_addr: std_logic_vector(WADDR-1 downto 0) := (others => '0');
	signal next_addr: std_logic_vector(WADDR-1 downto 0) := (others => '0'); 
	-- counter for mirror chain
	signal current_shift_counter : std_logic_vector(15 downto 0) := (others => '0');
	signal next_shift_counter : std_logic_vector(15 downto 0) := (others => '0');

	-- flag to signal mirror that it can do its things
	signal flag_mirror_chain : std_logic := '0';
	signal next_flag_mirror_chain : std_logic := '0';
	signal first_neuron : std_logic := '0';
	signal next_first_neuron : std_logic := '0';

	-- output signals
	signal out_ctrl_we_mode : std_logic := '0';
	signal out_ctrl_we_shift : std_logic := '0';
	signal out_ctrl_we_valid : std_logic := '0';
	signal out_ctrl_accu_clear : std_logic := '0';
	signal out_ctrl_accu_add : std_logic := '0';
	signal out_ctrl_shift_en : std_logic := '0';
	signal out_ctrl_shift_copy : std_logic := '0';
	signal out_n0_we_prev : std_logic := '0';

	signal config_written : boolean := false;
	signal next_config_written : boolean := false;
begin

	------------------------
	-- Sequential process --
	------------------------

	process (clk)
	begin
		if rising_edge(clk) then
			if (reset = '1') then
				current_state_acc <= RESET_STATE;
				current_state_mirror <= SHIFT_MODE;
				first_neuron <= '0';
			else
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

				config_written <= next_config_written;

			end if;
		end if;
	end process;


	-----------------------------
	-- Combinatorial processes --
	-----------------------------

	-- process to handle classic neurons accumulation and weight loading
	process (current_state_acc, sensor_we_mode, sensor_we_shift, sensor_we_valid, current_addr, nN_we_next, fsm_mode, first_neuron, config_written)
	begin
		-- need to set all signals at each step

		out_ctrl_we_mode <= '0';
		out_ctrl_we_shift <= '0';
		out_ctrl_we_valid <= '0';
		out_ctrl_accu_clear <= '0';
		out_ctrl_accu_add <= '0';
		out_n0_we_prev <= '0';
		next_addr <= (others => '0');
		next_state_acc <= MODE_FSM;
		next_flag_mirror_chain <= '0';
		next_first_neuron <= '0';

		if (config_written = false) then
			next_config_written <= false;
		else
			next_config_written <= true;
		end if;


		case current_state_acc is
			when RESET_STATE =>
				-- in case of reset, fsm goes to MODE_FSM
				next_state_acc <= MODE_FSM;

			-- on est en mode chargement des poids
			-- on attend que les neurones soient au courant
			when MODE_WEIGHT =>
				out_ctrl_we_mode <= '1';

				-- if neurons has got mode_switch signal
				-- goes to NOTIFY1N
				if (sensor_we_mode = '1') then
					next_first_neuron <= '1';
					next_state_acc <= NOTIFY_1N;
				else
					next_state_acc <= MODE_WEIGHT;
				end if;

			-- on passe le registre de config au premier neurone
			-- shift et attente dans le meme etat
			when NOTIFY_1N =>
				out_ctrl_we_mode <= '1';

				if ( sensor_we_shift = '1') then
					next_state_acc <= WAIT_WEIGHT;
					out_n0_we_prev <= '1';
				else
					if (first_neuron = '1') then
						out_ctrl_we_shift <= '1';
						next_first_neuron <= '0';
					end if;
					out_n0_we_prev <= '0';
					next_state_acc <= NOTIFY_1N;
				end if;

			-- on shift le registre de config
			when SHIFT_NOTIFY =>
				out_ctrl_we_mode <= '1';
				out_ctrl_we_shift <= '1';

				next_state_acc <= WAIT_NOTIFY;

			-- attente du passage du registre de config
			when WAIT_NOTIFY =>
				out_ctrl_we_mode <= '1';
				if (nN_we_next = '1') then
					next_state_acc<= END_CONFIG;
				else
					if (sensor_we_shift = '1') then
						next_state_acc <= WAIT_WEIGHT;
					else
						next_state_acc <= WAIT_NOTIFY;
					end if;
				end if;

			-- un neurone est pret à configurer sa memoire
			-- on attend qu'un poids arrive sur la fifo
			when WAIT_WEIGHT =>
				out_ctrl_we_mode <= '1';

				next_addr <= current_addr;

				if (sensor_we_valid = '1') then
					next_state_acc <= SEND_WEIGHT;
				else
					next_state_acc <= WAIT_WEIGHT;
				end if;

			-- un poids est dans la fifo
			-- le neurone prend le poids
			when SEND_WEIGHT =>
				out_ctrl_we_mode <= '1';
				out_ctrl_we_valid <= '1';

				if ( unsigned(current_addr) = FSIZE - 1) then
					next_state_acc <= SHIFT_NOTIFY;
				else
				-- incr addr for next round
					next_addr <= std_logic_vector(unsigned(current_addr) + 1);
					next_state_acc <= WAIT_WEIGHT;
				end if;

			-- on a configure tous les neurones
			-- on repasse en choix de mode
			when END_CONFIG =>
				next_config_written <= true;
				next_state_acc <= MODE_FSM;

			-- on est en mode accumulation
			-- on attend que les neurones soient au courant
			when MODE_ACC =>
				if (fsm_mode = '1') then
					if (not(config_written)) then
						next_state_acc <= MODE_WEIGHT;
					else
						next_state_acc <= RESET_STATE;
					end if;
				else
					if (sensor_we_mode = '0') then
						next_state_acc <= WAIT_1D;
					else
						next_state_acc <= MODE_ACC;
					end if;
				end if;

			when WAIT_1D =>
				out_ctrl_accu_clear <= '1';
				if (fsm_mode = '1' ) then
					if (not(config_written)) then
						next_state_acc <= MODE_WEIGHT;
					else
						next_state_acc <= RESET_STATE;
					end if;
				else
					if (sensor_we_valid = '1') then
						next_state_acc <= SEND_DATA;
					else
						next_state_acc <= WAIT_1D;
					end if;
				end if;

			when SEND_DATA =>
				out_ctrl_accu_add <= '1';
				-- incr addr for next round
				if ( unsigned(current_addr) = FSIZE - 1 ) then
					next_state_acc <= END_ACC;
				else
					next_state_acc <= WAIT_DATA;
					next_addr <= std_logic_vector( unsigned(current_addr) + 1);
				end if;

			when WAIT_DATA =>
				next_addr <= current_addr;
				if ( sensor_we_valid = '1') then
					next_state_acc <= SEND_DATA;
				else
					next_state_acc <= WAIT_DATA;
				end if;

			when END_ACC =>
				next_config_written <= false;
				-- need to pass flag to mirror FSM
				next_flag_mirror_chain <= '1';
				-- mode switching before
				-- going again in acc loop again
				next_state_acc <= MODE_FSM;

			when MODE_FSM=>
				if (fsm_mode = '1') then
					if (not(config_written)) then
						next_state_acc <= MODE_WEIGHT;
					else
						next_state_acc <= RESET_STATE;
					end if;
				else
					next_state_acc <= MODE_ACC;
				end if;

			when others =>
		end case;

	end process;

	-- process to handle mirror chain monitoring
	process (current_state_mirror, current_shift_counter, sensor_copy, flag_mirror_chain, out_fifo_in_cnt)
	begin
		out_ctrl_shift_copy <= '0';
		out_ctrl_shift_en <= '0';
		next_shift_counter <= (others => '0');
		next_state_mirror <= SHIFT_MODE;

		case current_state_mirror is
			when SHIFT_MODE =>
				if (flag_mirror_chain = '1') then
					next_state_mirror <= SHIFT_CPY;
				else
					next_state_mirror <= SHIFT_MODE;
				end if;

			when SHIFT_CPY =>
				-- copy accumulated value to mirror buffer
				out_ctrl_shift_copy <= '1';
				next_state_mirror <= WAIT_SHIFT_CPY;

			when WAIT_SHIFT_CPY =>
				if (sensor_copy = '1') then
					next_state_mirror <= SHIFT;
				else
					next_state_mirror <= WAIT_SHIFT_CPY;
				end if;

			when SHIFT =>
				next_shift_counter <= current_shift_counter;
				if (unsigned (current_shift_counter) = NB_NEURONS -1) then
					next_state_mirror <= SHIFT_MODE;
					out_ctrl_shift_en <= '1';
				elsif ( unsigned(out_fifo_in_cnt) > MIN_OUT_FIFO_IN_CNT + OUT_FIFO_MARGIN) then
					-- there is enough space in out_fifo
					next_state_mirror <= SHIFT;
					out_ctrl_shift_en <= '1';
					next_shift_counter <= std_logic_vector( unsigned (current_shift_counter ) +1);
				else
					next_state_mirror <= SHIFT;
				end if;
			when others =>
		end case;

	end process;

	---------------------------------------------
	----------- Ports assignements --------------
	---------------------------------------------

	addr <= current_addr;
	ctrl_we_mode <= out_ctrl_we_mode;
	ctrl_we_shift <= out_ctrl_we_shift;
	ctrl_we_valid <= out_ctrl_we_valid;
	ctrl_accu_clear <= out_ctrl_accu_clear;
	ctrl_accu_add <= out_ctrl_accu_add;
	ctrl_shift_en <= out_ctrl_shift_en;
	ctrl_shift_copy <= out_ctrl_shift_copy;
	n0_we_prev <= out_n0_we_prev;

end architecture;
