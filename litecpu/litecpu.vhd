library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.consts.ALL;


entity litecpu is
	port (
		clk_i: in std_logic;
		rst_i: in std_logic;
		led: out std_logic_vector(7 downto 0);
		led_num: out std_logic_vector(15 downto 0)
	 );
end litecpu;

architecture behave of litecpu is
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
	
	signal ram_addr: mem_addr_t;
	signal ram_rdata: dword;
	signal ram_wdata: dword;
	signal ram_rammode: rammode_t;

	signal ram_MEMMode: rammode_t;
	signal ram_MEMAddr: mem_addr_t;
	signal ram_MEMRData: dword;
	signal ram_MEMWData: dword;
	
	signal watch_reg: dword;
	signal watch_inst: dword;

	-- Don't know why but component must be used here
	component MMU is
		port (
			-- from CPU
			mode_i: in rammode_t;
			addr_i: in mem_addr_t;
			rdata_o: out dword;
			wdata_i: in dword;

			MEMMode_i: in rammode_t;
			MEMAddr_i: in mem_addr_t;
			MEMRData_o: out dword;
			MEMWData_i: in dword;
			
			-- to RAM
			ram_mode_o: out rammode_t;
			ram_addr_o: out mem_addr_t;
			ram_rdata_i: in dword;
			ram_wdata_o: out dword;

			ram_MEMMode_o: out rammode_t;
			ram_MEMAddr_o: out mem_addr_t;
			ram_MEMRData_i: in dword;
			ram_MEMWData_o: out dword
		);
	end component;

	component RAM is
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
			MEMWData_o: out dword;
			
			display_reg_o: out dword;
			display_inst_o: out dword
		);
	end component;


begin
	clk <= clk_i;
	rst <= rst_i;

	led <= not watch_reg(7 downto 0);
	led_num <= watch_inst(15 downto 0);
	uram:
	RAM
	port map (
		clk_i=> clk,
		rst_i=> rst,

		addr_i=> ram_addr,
		rdata_o=> ram_rdata,
		wdata_i=> ram_wdata,
		mode_i=> ram_rammode,
		
		MEMMode_i => ram_MEMMode,
		MEMAddr_i => ram_MEMAddr,
		MEMRData_o => ram_MEMRData,
		MEMWData_i => ram_MEMWData
	);

	ummu:
	MMU
	port map (
		mode_i=> rammode,
		addr_i=> addr,
		wdata_i=> wdata,
		rdata_o=> rdata,
		
		MEMMode_i => MEMMode,
		MEMAddr_i => MEMAddr,
		MEMRData_o => MEMRData,
		MEMWData_i => MEMWData,
		
		ram_addr_o=> ram_addr,
		ram_rdata_i=> ram_rdata,
		ram_wdata_o=> ram_wdata,
		ram_mode_o=> ram_rammode,
		
		ram_MEMMode_o => ram_MEMMode,
		ram_MEMAddr_o => ram_MEMAddr,
		ram_MEMRData_i => ram_MEMRData,
		ram_MEMWData_o => ram_MEMWData
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
		MEMWData_o => MEMWData,
		
		display_reg_o => watch_reg,
		display_inst_o => watch_inst
	);

end behave;
