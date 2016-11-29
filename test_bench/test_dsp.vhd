LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
Library UNISIM;
use UNISIM.vcomponents.all;
library UNIMACRO;
use unimacro.Vcomponents.all;

-- entity declaration for your testbench.Dont declare any ports here
ENTITY test_dsp IS 
END test_dsp;

ARCHITECTURE behavior OF test_dsp IS
   SIGNAL p            : std_logic_vector(47 downto 0);
   SIGNAL load_data    : std_logic_vector(47 downto 0);
   SIGNAL a            : std_logic_vector(24 downto 0);
   SIGNAL b            : std_logic_vector(17 downto 0);
   SIGNAL addsub       : std_logic := '1';
   SIGNAL carryin      : std_logic := '0';
   SIGNAL ce           : std_logic := '1';
   SIGNAL cin          : std_logic := '0';
   SIGNAL clk          : std_logic;
   SIGNAL load         : std_logic;
   SIGNAL rst          : std_logic;
   -- cLOCK PERIOD DEfinitions
   constant clk_period : time := 1 ns;
BEGIN
      -- Instantiate the Unit Under Test (UUT)
   uut: MACC_MACRO
   generic map (
       DEVICE => "7SERIES",  -- Target Device: "VIRTEX5", "7SERIES", "SPARTAN6"
       LATENCY => 3,
       WIDTH_A => 25,
       WIDTH_B => 18,
       WIDTH_P => 48)
   PORT MAP (
       p         => p,
       a         => a,
       b         => b,
       addsub    => addsub,
       carryin   => carryin,
       ce        => ce,
       clk       => clk,
       load      => load,
       load_data => load_data,
       rst       => rst
   );       

   -- Clock process definitions( clock with 50% duty cycle is generated here.
   clk_process :process
   begin
      clk <= '0';
      wait for clk_period/2;  --for 0.5 ns signal is '0'.
      clk <= '1';
      wait for clk_period/2;  --for next 0.5 ns signal is '1'.
   end process;
                                          -- Stimulus process
   stim_proc: process
   begin         
      wait for 1 ns;
      rst       <= '1';
      wait for 1 ns;
      rst       <= '0';
      a         <= B"0" & X"00_0000";
      b         <= B"00" & X"0000";
      load      <= '1';
      load_data <= X"0000_0000_0000";

      wait for 1 ns;
      rst       <= '0';
      a         <= B"0" & X"00_0001";
      b         <= B"00" & X"0001";
      load      <= '0';

      wait for 1 ns;
      rst       <= '0';
      a         <= B"0" & X"00_0001";
      b         <= B"00" & X"0002";
      load      <= '0';

      wait for 1 ns;
      rst       <= '0';
      a         <= B"0" & X"00_0002";
      b         <= B"00" & X"0002";
      load      <= '0';
      wait;
   end process;

END;
