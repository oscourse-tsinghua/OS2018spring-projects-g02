library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.consts.ALL;


entity litecpu is
	port (
		clk_i: in std_logic;
		rst_i: in std_logic;
		led: out std_logic_vector(7 downto 0);
		led_num: out std_logic_vector(15 downto 0);
		txd: out std_logic;
      rxd: in std_logic;
		
		led_g: out std_logic;
		led_b: out std_logic
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
	
	signal rom_addr: mem_addr_t;
	signal rom_rdata: dword;
	signal rom_wdata: dword;
	signal rom_rammode: rammode_t;

	signal ram_addr: ram_addr_t;
	signal ram_rdata: dword;
	signal ram_wdata: dword;
	signal ram_we: std_logic;
	
	signal watch_reg: dword;
	signal watch_inst: dword;
	
	signal COMReceiveData: std_logic_vector(7 downto 0);
   signal COMReceiveIdle, COMReceiveEndofPacket, COMReceiveDataReady: std_logic;
   signal COMTransmitData: std_logic_vector(7 downto 0); 
   signal COMTransmitStart, COMTransmitBusy: std_logic;
	signal transmitSTARTTEST: std_logic;
	signal COMTEST: std_logic;
	
	signal UART1_IN_ready: std_logic;
	signal UART1_OUT_ready: std_logic;
	
	
	-- Don't know why but component must be used here
	component async_transmitter generic(
       ClkFrequency: integer;
       Baud: integer);
   port(
       clk: in std_logic;
       TxD_start: in std_logic;
       TxD_data: in std_logic_vector(7 downto 0);
       TxD: out std_logic;
       TxD_busy: out std_logic
   );
   end component;
   component async_receiver generic(
       ClkFrequency: integer;
       Baud: integer);
   port(
       clk: in std_logic;
       RxD_data: out std_logic_vector(7 downto 0);
       RxD: in std_logic;
       RxD_idle: out std_logic;
       RxD_endofpacket: out std_logic;
       RxD_data_ready: out std_logic
   );
   end component;
   
	component MMU is
		port (
			rst_i: in std_logic;
			clk_i: in std_logic;
		
			-- from CPU
			mode_i: in rammode_t;
			addr_i: in mem_addr_t;
			rdata_o: out dword;
			wdata_i: in dword;

			MEMMode_i: in rammode_t;
			MEMAddr_i: in mem_addr_t;
			MEMRData_o: out dword;
			MEMWData_i: in dword;
			
			-- to ROM
			rom_mode_o: out rammode_t;
			rom_addr_o: out mem_addr_t;
			rom_rdata_i: in dword;
			rom_wdata_o: out dword;

			-- to RAM
			ram_we_o: out std_logic;
			ram_addr_o: out ram_addr_t;
			ram_rdata_i: in dword;
			ram_wdata_o: out dword;
			
			-- COM
    		COMReceiveData: in std_logic_vector(7 downto 0);
		   COMTransmitData: out std_logic_vector(7 downto 0);
		   COMTransmitStart: out std_logic;
		   COMReceiveReady: in std_logic;-- receive: 1 for ready, 0 for not
		   COMTransmitBusy: in std_logic;-- transmit: 1 for busy, 0 for ready
			
			COMTransmitStartTEST: out std_logic;
			COMTEST: out std_logic;
			
			UART1_IN_ready_o: out std_logic;
			UART1_OUT_ready_o: out std_logic
		);
	end component;

	component ROM is
		port (
			clk_i: in std_logic;
			rst_i: in std_logic;

			mode_i: in rammode_t;
			addr_i: in mem_addr_t;
			rdata_o: out dword;
			wdata_i: in dword
		);
	end component;
	
	component RAM is
		port (
			address		: IN ram_addr_t;
			clock		: IN STD_LOGIC ;
			data		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
			wren		: IN STD_LOGIC ;
			q		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
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
			display_inst_o: out dword;
			
			UART1_IN_ready_i: in std_logic;
			UART1_OUT_ready_i: in std_logic
		);
	end component;


begin
	clk <= clk_i;
	rst <= rst_i;

	led <= not watch_reg(7 downto 0);
	led_num <= watch_inst(15 downto 0);
	led_g <= txd;
	led_b <= transmitSTARTTEST;
	urom:
	ROM
	port map (
		clk_i=> clk,
		rst_i=> rst,

		addr_i=> rom_addr,
		rdata_o=> rom_rdata,
		wdata_i=> rom_wdata,
		mode_i=> rom_rammode
	);

	uram:
	RAM
	port map (
		address=> ram_addr,
		clock=> clk,
		data=> ram_wdata,
		wren=> ram_we,
		q=> ram_rdata
	);
	
	ummu:
	MMU
	port map (
		rst_i => rst_i,
		clk_i => clk_i,
		mode_i=> rammode,
		addr_i=> addr,
		wdata_i=> wdata,
		rdata_o=> rdata,
		
		MEMMode_i => MEMMode,
		MEMAddr_i => MEMAddr,
		MEMRData_o => MEMRData,
		MEMWData_i => MEMWData,
		
		rom_addr_o=> rom_addr,
		rom_rdata_i=> rom_rdata,
		rom_wdata_o=> rom_wdata,
		rom_mode_o=> rom_rammode,
		
		ram_addr_o=> ram_addr,
		ram_rdata_i=> ram_rdata,
		ram_wdata_o=> ram_wdata,
		ram_we_o=> ram_we,
		
		COMReceiveData => COMReceiveData,
      COMTransmitData => COMTransmitData,
      COMTransmitStart => COMTransmitStart,
      COMReceiveReady => COMReceiveDataReady,
      COMTransmitBusy => COMTransmitBusy,
		
		COMTransmitStartTEST => transmitSTARTTEST,
		COMTEST => COMTEST,
		
		UART1_IN_ready_o => UART1_IN_ready,
		UART1_OUT_ready_o => UART1_OUT_ready		
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
		display_inst_o => watch_inst,
		
		UART1_IN_ready_i => UART1_IN_ready,
		UART1_OUT_ready_i => UART1_OUT_ready	
	);

	uAsyncTransmitter: component async_transmitter generic map(
       ClkFrequency => 12000000,
       Baud => 115200
   )
   port map(
       clk => clk_i,
       TxD => txd,
       TxD_start => COMTransmitStart,
       TxD_data => COMTransmitData,
       TxD_busy => COMTransmitBusy
   );
      
   uAsyncReceiver: async_receiver generic map(
       ClkFrequency => 12000000,
       Baud => 115200
   )
   port map(
       clk => clk_i,
       RxD => rxd,
       RxD_data_ready => COMReceiveDataReady,
       RxD_data => COMReceiveData,
       RxD_idle => COMReceiveIdle,
       RxD_endofpacket => COMReceiveEndofPacket
   );
	
end behave;
