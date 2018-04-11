library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.consts.ALL;


entity litecpu is
	port (
		clk_i: in std_logic;
		rst_i: in std_logic
	 );
end litecpu;


architecture behave of litecpu is
	signal ram_mode: rammode_t;
	signal ram_addr: mem_addr_t;
	signal ram_wdata: dword;
	signal ram_rdata: dword;

begin

--	ucpu_core:
--	entity work.CPU_CORE
--	port map (
--		rst_i=> rst_i,
--		clk_i=> clk_i,
--
--		ram_mode_o=> ram_mode,
--		ram_addr_o=> ram_addr,
--		ram_wdata_o=> ram_wdata,
--		ram_rdata_i=> ram_rdata
--	);

end behave;
