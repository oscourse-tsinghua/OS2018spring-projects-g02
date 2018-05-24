library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.consts.ALL;

entity litecpu is
port (
		clk_50m: in std_logic;
		clk_i: in std_logic;
		rst_i: in std_logic;
		led: out std_logic_vector(7 downto 0);
		led_num: out std_logic_vector(15 downto 0);
		txd: out std_logic;
      rxd: in std_logic;
		
		led_g: out std_logic;
		led_b: out std_logic;
		
		switch: in std_logic_vector(3 downto 0);
		halt_btn: in std_logic
	 );
end litecpu;

architecture behave of litecpu is
	signal clk: std_logic := '0';
	signal clk_25M: std_logic;
	signal rst: std_logic := '1';
	
	signal fatalTEST: std_logic := '0';
	signal fatalled: std_logic := '0';

	signal addr: mem_addr_t;
	signal rdata: dword;
	signal wdata: dword;
	signal rammode: rammode_t;

	signal MEMMode: rammode_t;
	signal MEMAddr: mem_addr_t;
	signal MEMRData: dword;
	signal MEMWData: dword;
	
	signal intMode: rammode_t;
	signal intAddr: mem_addr_t;
	signal intRData: dword;
	signal intWData: dword;
	
	signal IDModeTEST: rammode_t;
	signal EXModeTEST: rammode_t;
	
	signal rom_addr: mem_addr_t;
	signal rom_rdata: dword;
	signal rom_wdata: dword;
	signal rom_rammode: rammode_t;

	signal ram_addr: ram_addr_t;
	signal ram_rdata: dword;
	signal ram_wdata: dword;
	signal ram_we: std_logic;
	
	signal watch_reg: std_logic_vector(95 downto 0);
	signal watch_inst: dword;
	
	signal COMReceiveData: std_logic_vector(7 downto 0);
   signal COMReceiveIdle, COMReceiveEndofPacket, COMReceiveDataReady: std_logic;
   signal COMTransmitData: std_logic_vector(7 downto 0); 
   signal COMTransmitStart, COMTransmitBusy: std_logic;
	signal transmitSTARTTEST: std_logic;
	signal COMTEST: std_logic;
	
	signal IFActiveTEST: std_logic;
	signal IDActiveTEST: std_logic;
	signal EXActiveTEST: std_logic;
	signal MEMActiveTEST: std_logic;
	
	signal UART1_IN_ready: std_logic;
	signal UART1_OUT_ready: std_logic;
	signal opcodeTEST: opcode_t;
	
	signal irq: dword;
	signal reg_pcTEST: dword;
	signal reg_pc_weTEST: std_logic;
	
	signal pcTEST: std_logic;
	
	
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
			clk_50m_i: in std_logic;
		
			-- from CPU
			mode_i: in rammode_t;
			addr_i: in mem_addr_t;
			rdata_o: out dword;
			wdata_i: in dword;

			MEMMode_i: in rammode_t;
			MEMAddr_i: in mem_addr_t;
			MEMRData_o: out dword;
			MEMWData_i: in dword;
	/*		
			intMode_i: in rammode_t;
			intAddr_i: in mem_addr_t;
			intRData_o: out dword;
			intWData_i: in dword;
		*/	
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
			
			-- IRQ
--			irq_o: out dword
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
			
/*			intMode_o: out rammode_t;
			intAddr_o: out mem_addr_t;
			intWData_o: out dword;
			intRData_i: in dword;
*/			
			display_reg_o: out std_logic_vector(95 downto 0);
			display_inst_o: out dword;
			
			IDModeTEST: out rammode_t;
			EXModeTEST: out rammode_t;
			
			IFActiveTEST: out std_logic;
			IDActiveTEST: out std_logic;
			EXActiveTEST: out std_logic;
			MEMActiveTEST: out std_logic;
			
			opcodeTEST: out opcode_t;
			
			UART1_IN_ready_i: in std_logic;
			UART1_OUT_ready_i: in std_logic;
			
--			irq_i: in dword;
			reg_pcTEST: out dword;
			reg_pc_weTEST: out std_logic;
			
			pcTEST: out std_logic;
			
			fatal_o: out std_logic
		);
	end component;


begin
	/*process (clk_i)
	begin
		if (rst = '1') then
			clk <= '0';
		elsif (rising_edge(clk_i)) then 
			clk <= not clk;
		end if;
	end process;*/

	rst <= not rst_i;
	clk <= clk_i;
	
	process (rst,clk_50m)
	begin
		if (rst = '1') then 
			clk_25m <= '0';
		elsif (rising_edge(clk_50m)) then
			clk_25m <= not clk_25m;
		end if;
	end process;
	
	process (all)
	begin
	if (rst = '1') then 
		fatalled <= '0';
	else 
		fatalled <= fatalled or fatalTEST;
	end if;
	case switch is
		when "0000" => 
--			led <= not irq(7 downto 0);
			led <= not watch_reg(7 downto 0);
		when "0001" =>
			led <= not watch_reg(15 downto 8);
		when "0010" =>
			led <= not watch_reg(23 downto 16);
		when "0011" =>
			led <= not watch_reg(31 downto 24);
		when "0100" =>
			led <= not watch_reg(39 downto 32);
		when "0101" =>
			led <= not watch_reg(47 downto 40);
		when "0110" =>
			led <= not watch_reg(55 downto 48);
		when "0111" =>
			led <= not watch_reg(63 downto 56);
		when "1000" =>
			led <= not watch_reg(71 downto 64);
		when "1001" =>
			led <= not watch_reg(79 downto 72);
		when "1010" =>
			led <= not watch_reg(87 downto 80);
		when "1011" =>
			led <= not watch_reg(95 downto 88);	
		when "1100" => 
			led <= not watch_inst(7 downto 0);
		when "1101" => 
			led <= not COMReceiveData(7 downto 0);
		when "1110" => 
			led <= x"ff";
			case IDModeTEST is
				when RAM_NOP =>
					led(0) <= '0';
				when RAM_READ =>
					led(1) <= '0';
				when RAM_WRITE =>
					led(2) <= '0';
			end case;
			case EXModeTEST is
				when RAM_NOP =>
					led(3) <= '0';
				when RAM_READ =>
					led(4) <= '0';
				when RAM_WRITE =>
					led(5) <= '0';
			end case;
			led(6) <= not clk;
			led(7) <= not pcTEST;
		when others =>
			led <= x"ff";
			case MEMMode is
				when RAM_NOP =>
					led(0) <= '0';
				when RAM_READ =>
					led(1) <= '0';
				when RAM_WRITE =>
					led(2) <= '0';
			end case;
			case rammode is
				when RAM_NOP =>
					led(3) <= '0';
				when RAM_READ =>
					led(4) <= '0';
				when RAM_WRITE =>
					led(5) <= '0';
			end case;
			led(6) <= not EXActiveTEST;
			led(7) <= not MEMActiveTEST;
	end case;
	end process;
	led_num <= watch_reg(15 downto 8) & COMTransmitData;
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
		clock=> clk_50m, 
		data=> ram_wdata,
		wren=> ram_we,
		q=> ram_rdata
	);
	
	ummu:
	MMU
	port map (
		rst_i => rst,
		clk_i => clk,
		clk_50m_i => clk_50m,
		mode_i=> rammode,
		addr_i=> addr,
		wdata_i=> wdata,
		rdata_o=> rdata,
		
		MEMMode_i => MEMMode,
		MEMAddr_i => MEMAddr,
		MEMRData_o => MEMRData,
		MEMWData_i => MEMWData,
		
/*		intMode_i => intMode,
		intAddr_i => intAddr,
		intRData_o => intRData,
		intWData_i => intWData,
*/		
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
		
--		irq_o => irq
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
		
/*		intMode_o => intMode,
		intAddr_o => intAddr,
		intWData_o => intWData,
		intRData_i => intRData,
	*/	
		display_reg_o => watch_reg,
		display_inst_o => watch_inst,
		
		IDModeTEST => IDModeTEST,
		EXModeTEST => EXModeTEST,
		
		IFActiveTEST => IFActiveTEST,
		IDActiveTEST => IDActiveTEST,
		EXActiveTEST => EXActiveTEST,
		MEMActiveTEST => MEMActiveTEST,
		
		opcodeTEST => opcodeTEST,
		
		UART1_IN_ready_i => UART1_IN_ready,
		UART1_OUT_ready_i => UART1_OUT_ready,
		
--		irq_i => irq,
		reg_pcTEST => reg_pcTEST,
		reg_pc_weTEST => reg_pc_weTEST,
		
		pcTEST => pcTEST,
		
		fatal_o => fatalTEST
	);

	uAsyncTransmitter: component async_transmitter generic map(
       ClkFrequency => 11950000,
       Baud => 9600
   )
   port map(
       clk => clk_i,
       TxD => txd,
       TxD_start => COMTransmitStart,
       TxD_data => COMTransmitData,
       TxD_busy => COMTransmitBusy
   );
      
   uAsyncReceiver: async_receiver generic map(
       ClkFrequency => 11950000,
       Baud => 9600
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
