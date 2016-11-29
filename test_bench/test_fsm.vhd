LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
Library UNISIM;
use UNISIM.vcomponents.all;
library UNIMACRO;
use unimacro.Vcomponents.all;

-- entity declaration for your testbench.Dont declare any ports here
ENTITY test_fsm IS 
	END test_fsm;

ARCHITECTURE behavior OF test_fsm IS
	-- add component under test
	component fsm
		generic ( NB_NEURONS : natural);
		port (
			     reset         : in  std_logic;
			     clk           : in  std_logic;
			     -- Control signals
			     ctrl_we_mode    : out  std_logic;
			     ctrl_we_shift   : out  std_logic;
			     ctrl_we_valid   : out  std_logic;
			     ctrl_accu_clear : out  std_logic;
			     ctrl_accu_add   : out  std_logic;
			     ctrl_shift_en   : out  std_logic;
			     ctrl_shift_copy : out  std_logic;
			     -- Address used for Read and Write
			     addr            : out  std_logic_vector(9 downto 0);
			     -- Ports for Write Enable
			     n0_we_prev         : out  std_logic;
			     nN_we_next         : in std_logic;
			     -- Sensors, for synchronization with the controller
			     sensor_shift    : in std_logic;
			     sensor_copy     : in std_logic;
			     sensor_we_mode  : in std_logic;
			     sensor_we_shift : in std_logic;
			     sensor_we_valid : in std_logic;

			     -- inputs
			     fsm_mode	: in std_logic
		     );
	end component;
	signal clk           :   std_logic := '0';
	signal reset         :   std_logic := '0';
	-- Control signals
	signal ctrl_we_mode    :   std_logic := '0';
	signal ctrl_we_shift   :   std_logic := '0';
	signal ctrl_we_valid   :   std_logic := '0';
	signal ctrl_accu_clear :   std_logic := '0';
	signal ctrl_accu_add   :   std_logic := '0';
	signal ctrl_shift_en   :   std_logic := '0';
	signal ctrl_shift_copy :   std_logic := '0';
	-- Address used for Read and Write
	signal addr            :   std_logic_vector(9 downto 0);
	-- Ports for Write Enable
	signal n0_we_prev      :   std_logic := '0';
	signal nN_we_next      :  std_logic := '0';
	-- Sensors, for synchronization with the controller
	signal sensor_shift    :  std_logic := '0';
	signal sensor_copy     :  std_logic := '0';
	signal sensor_we_mode  :  std_logic := '0';
	signal sensor_we_shift :  std_logic := '0';
	signal sensor_we_valid :  std_logic := '0';

	-- puts
	signal fsm_mode	:  std_logic := '0';
	-- clock period definitions
	constant clk_period : time := 1 ns;

begin
	-- Instantiate the Unit Under Test (UUT)
	uut: fsm
	generic map (
			    NB_NEURONS => 1
		    )
	port map (
			 reset => reset,
			 clk => clk         ,
			 -- Control signals
			 ctrl_we_mode => ctrl_we_mode   ,
			 ctrl_we_shift => ctrl_we_shift  ,
			 ctrl_we_valid => ctrl_we_valid  ,
			 ctrl_accu_clear => ctrl_accu_clear,
			 ctrl_accu_add => ctrl_accu_add  ,
			 ctrl_shift_en => ctrl_shift_en  ,
			 ctrl_shift_copy => ctrl_shift_copy,
			 -- Address used for Read and Write
			 addr => addr           ,
			 -- Ports for Write Enable
			 n0_we_prev => n0_we_prev        ,
			 nN_we_next => nN_we_next        ,
			 -- Sensors, for synchronization with the controller
			 sensor_shift => sensor_shift   ,
			 sensor_copy => sensor_copy    ,
			 sensor_we_mode => sensor_we_mode ,
			 sensor_we_shift => sensor_we_shift,
			 sensor_we_valid => sensor_we_valid,
			 -- inputs
			 fsm_mode => fsm_mode
		 );       


	-- Clock process definitions( clock with 50% duty cycle is generated here.
	clk_process :process
	begin
		clk <= '1';
		wait for clk_period/2;  --for 0.5 ns signal is '1'.
		clk <= '0';
		wait for clk_period/2;  --for next 0.5 ns signal is '0'.
	end process;
	-- Stimulus process
	stim_proc: process
	begin         
		wait for 1 ns;
		reset       <= '1';
		fsm_mode    <= '0';
		--signal ctrl_we_mode    :   std_logic;
		--signal ctrl_we_shift   :   std_logic;
		--signal ctrl_we_valid   :   std_logic;
		--signal ctrl_accu_clear :   std_logic;
		--signal ctrl_accu_add   :   std_logic;
		--signal ctrl_shift_en   :   std_logic;
		--signal ctrl_shift_copy :   std_logic;
		--signal addr            :   std_logic_vector(9 downto 0);
		--signal n0_we_prev      :   std_logic;
		--signal nN_we_next      :  std_logic;
		--signal sensor_shift    :  std_logic;
		--signal sensor_copy     :  std_logic;
		--signal sensor_we_mode  :  std_logic;
		--signal sensor_we_shift :  std_logic;
		--signal sensor_we_valid :  std_logic;

		wait for 1 ns;
		reset       <= '0';
		fsm_mode    <= '0';
		wait for 1 ns;
		reset       <= '0';
		sensor_we_valid <= '1';
		wait for 2000 ns;
		reset       <= '0';
		sensor_we_valid <= '0';
		fsm_mode <= '1';
		wait for 1 ns;
		sensor_we_mode  <= '1';
		fsm_mode <= '0';
		reset       <= '0';
		wait for 2 ns;
		sensor_copy <= '1';
		sensor_we_shift <= '1';
		sensor_we_mode  <= '0';
		wait for 1 ns;
		sensor_copy <= '0';
		sensor_we_shift <= '0';
		sensor_we_valid <= '1';
		wait for 2000 ns;
		sensor_shift <= '1';
		sensor_we_valid <= '0';
		wait for 1 ns;
		sensor_shift <= '0';

		wait;
	end process;

END;
