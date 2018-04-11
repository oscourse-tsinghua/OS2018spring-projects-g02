library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.consts.ALL;


entity litecpu_tb is
end litecpu_tb;


architecture behave of litecpu_tb is
	signal clk: std_logic := '0';
	signal rst: std_logic := '1';

	signal addr: mem_addr_t := x"00000004";
	signal rdata: dword := (others=> '0');
	signal wdata: dword := (others=> '0');
	signal rammode: rammode_t := RAM_NOP;

	-- Don't know why but component must be used here
	component RAM_TB is
		port (
			clk_i: in std_logic;
			rst_i: in std_logic;

			mode_i: in rammode_t;
			addr_i: in mem_addr_t;
			rdata_o: out dword;
			wdata_i: in dword
		);
	end component;

begin
	clk <= not clk after 50ns;
	rst <= '0' after 90ns;

	uram:
	RAM_TB
	port map(
		clk_i=> clk,
		rst_i=> rst,

		addr_i=> addr,
		rdata_o=> rdata,
		wdata_i=> wdata,
		mode_i=> rammode
	);

	process
	begin
		wait for 100ns;
		rammode <= RAM_READ;
		wait for 300ns;
		rammode <= RAM_WRITE;
		wdata <= x"55555555";
		addr <= x"00000010";
	end process;

end behave;
