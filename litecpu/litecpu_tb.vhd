library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.consts.ALL;


entity litecpu_tb is
end litecpu_tb;


architecture behave of litecpu_tb is
	signal clk: std_logic := '0';
	signal rst: std_logic := '1';

	signal addr: mem_addr_t;
	signal rdata: dword;
	signal wdata: dword;
	signal rammode: rammode_t;

	signal MEMMode: rammode_t;
	signal MEMAddr: mem_addr_t;
	signal MEMRData: dword;
	signal MEMWData: dword;

	-- Don't know why but component must be used here
	component RAM_TB is
		port (
			clk_i: in std_logic;
			rst_i: in std_logic;

			mode_i: in rammode_t;
			addr_i: in mem_addr_t;
			rdata_o: out dword;
			wdata_i: in dword;
				
			MEMMode_i: in rammode_t;
			MEMAddr_i: in mem_addr_t;
			MEMRData_o: out dword;
			MEMWData_i: in dword
		);
	end component;


	component CPU_CORE is
		port (
			rst_i: in std_logic;
			clk_i: in std_logic; 

			ram_mode_o: out rammode_t;
			ram_addr_o: out mem_addr_t;
			ram_wdata_o: out dword;
			ram_rdata_i: in dword;
				
			MEMMode_o: out rammode_t;
			MEMAddr_o: out mem_addr_t;
			MEMRData_i: in dword;
			MEMWData_o: out dword
		);
	end component;


begin
	clk <= not clk after 50ns;
	rst <= '0' after 90ns;


	uram:
	RAM_TB
	port map (
		clk_i=> clk,
		rst_i=> rst,

		addr_i=> addr,
		rdata_o=> rdata,
		wdata_i=> wdata,
		mode_i=> rammode,
		
		MEMMode_i => MEMMode,
		MEMAddr_i => MEMAddr,
		MEMRData_o => MEMRData,
		MEMWData_i => MEMWData
	);


	ucpu_core:
	CPU_CORE
	port map (
		clk_i=> clk,
		rst_i=> rst,

		ram_mode_o=> rammode,
		ram_addr_o=> addr,
		ram_wdata_o=> wdata,
		ram_rdata_i=> rdata,
		
		MEMMode_o => MEMMode,
		MEMAddr_o => MEMAddr,
		MEMRData_i => MEMRData,
		MEMWData_o => MEMWData
	);

end behave;
