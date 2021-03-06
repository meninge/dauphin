----------------------------------------------------------------
-- uut:
--	recode.vhd
-- description:
--	simple test_bench to verify recode behavior in simple cases
-- expected result:
--	recode should be configurable, and in simple mode
--	negative inputs become 0, and positive ones are added a constant
--	input shall not be taken if there is no room in output fifo
----------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
Library UNISIM;
use UNISIM.vcomponents.all;
library UNIMACRO;
use unimacro.Vcomponents.all;
use ieee.numeric_std.all;

-- entity declaration for your testbench.Dont declare any ports here
ENTITY test_recode IS
	END test_recode;

ARCHITECTURE behavior OF test_recode IS
	-- add component under test
	constant WDATA : natural := 32;
	constant WWEIGHT : natural := 16;
	constant WOUT  : natural := 32;
	constant FSIZE : natural := 10; -- warning, this is NB_NEU

	component recode
	generic(
		WDATA : natural := 32;
		WWEIGHT : natural := WWEIGHT;
		WOUT  : natural := 32;
		FSIZE : natural := 10 -- warning, this is NB_NEU
	);
	port(
		clk             : in  std_logic;
		-- Ports for address control
		addr_clear      : in  std_logic;
		-- Ports for Write into memory
		write_mode      : in  std_logic;
		write_data      : in  std_logic_vector(WDATA - 1 downto 0);
		write_enable    : in  std_logic;
		write_ready     : out std_logic;
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
	end component;

	signal clk           :   std_logic := '0';
	-- clock period definitions
	constant clk_period : time := 1 ns;
	signal addr_clear      : std_logic;
	signal write_mode      : std_logic;
	signal write_data      : std_logic_vector(WDATA - 1 downto 0);
	signal write_enable    : std_logic;
	signal write_ready     : std_logic;
	signal user_nbneu      : std_logic_vector(15 downto 0);
	signal data_in         : std_logic_vector(WDATA-1 downto 0);
	signal data_in_valid   : std_logic;
	signal data_in_ready   : std_logic;
	signal data_out        : std_logic_vector(WOUT-1 downto 0);
	signal data_out_valid  : std_logic;
	signal out_fifo_room   : std_logic_vector(15 downto 0);

begin
	-- Instantiate the Unit Under Test (UUT)
	uut: recode
	generic map (
		WDATA => WDATA,
		WOUT => WOUT,
		FSIZE => FSIZE
	)
	port map (
		clk => clk,
		-- Ports for address control
		addr_clear => addr_clear,
		-- Ports for Write into memory
		write_mode => write_mode,
		write_data => write_data,
		write_enable => write_enable,
		write_ready => write_ready,
		-- The user-specified number of neurons
		user_nbneu => user_nbneu,
		-- Data input
		data_in => data_in,
		data_in_valid => data_in_valid,
		data_in_ready => data_in_ready,
		-- Data output
		data_out => data_out,
		data_out_valid => data_out_valid,
		-- The output data enters a FIFO. This indicates the available room.
		out_fifo_room => out_fifo_room
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
		variable counter : natural := 0;
	begin
		wait for 1 ns;
		-- reset component
		addr_clear <= '1';
		data_in_valid <= '0';
		wait for 1 ns;

		-------------------------------
		-- TEST CHARGEMENT DES POIDS --
		-------------------------------

		addr_clear <= '0';
		write_mode <= '1';
		wait for 1 ns;
		-- chargement des constantes à ajouter dans le recode
		while counter < 10 loop
			write_data <= std_logic_vector(to_unsigned(counter + 10,32));
			write_enable <= '1';
			wait for clk_period;
			counter := counter +1;
		end loop;
		write_data <= std_logic_vector(to_unsigned(1220,32));

		----------------------
		-- TEST MODE RECODE --
		----------------------

		-- mode de recode, traitement des données
		write_mode <= '0';
		data_in_valid <= '1';
		data_in <= X"00000020";
		out_fifo_room <= X"0020";

		wait for 10 * clk_period;

		-- simule que la fifo de sortie est pleine
		out_fifo_room <= X"0000";
		wait for 10 * clk_period;

		-- De nouveau, il y a de la place
		out_fifo_room <= X"0002";
		wait for 10 * clk_period;
		data_in <= X"FFFFFFF2";
		wait;

	end process;

END;
