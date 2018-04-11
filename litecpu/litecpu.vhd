library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.consts.ALL;


entity litecpu is
	port (
		clk: in std_logic;
		disp: out std_logic
	 );
end litecpu;


architecture behave of litecpu is
	signal t_count: unsigned(21 downto 0) := (others=> '0');
	signal l_disp: std_logic := '0';
	constant KT_COUNT_ZERO: unsigned(21 downto 0) := (others=> '0');
begin

	disp <= l_disp;

	process (clk) begin
		if (rising_edge(clk)) then
			t_count <= t_count + 1;
			if (t_count = KT_COUNT_ZERO) then
				l_disp <= not l_disp;
			end if;
		end if;
	end process;

end behave;
