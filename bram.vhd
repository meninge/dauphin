library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ram is
	generic (
			WDATA : natural := 16;
			SIZE   : natural := 784;
			WADDR   : natural := 10

		);
	port (
		clk : in std_logic;
		we: in std_logic;
		en: in std_logic;
		addr : in std_logic_vector(WADDR-1 downto 0);
		di: in std_logic_vector(WDATA-1 downto 0);
		do: out std_logic_vector(WDATA-1 downto 0));
end ram;

architecture syn of ram is
	type ram_type is array (SIZE-1 downto 0) of std_logic_vector (WDATA-1 downto 0);
	signal RAM : ram_type := (others => (others => '0'));
begin
	process (clk)
	begin
		if rising_edge(clk) then
			if en = '1' then
				if we = '1' then
					RAM(to_integer(unsigned(addr))) <= di;
				end if;
				do <= RAM(to_integer(unsigned(addr))) ;
			end if;
		end if;
	end process;
end syn;
