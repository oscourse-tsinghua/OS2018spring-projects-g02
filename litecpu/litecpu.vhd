library IEEE;

using IEEE.STD_LOGIC_1164.ALL;
using IEEE.NUMERIC_STD.ALL;

entity litecpu
	port (
		dummy: out std_logic
	)
end litecpu;

architecture behave of litecpu is

begin
	dummy <= '0';
end behave;