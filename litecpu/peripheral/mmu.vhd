library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.consts.ALL;
use IEEE.NUMERIC_STD.ALL;


entity MMU is
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
/*		
		intMode_i: in rammode_t;
		intAddr_i: in mem_addr_t;
		intWData_i: in dword;
		intRData_o: out dword;
*/		
		-- to RAM
		ram_we_o: out std_logic;
		ram_addr_o: out ram_addr_t;
		ram_rdata_i: in dword;
		ram_wdata_o: out dword;

		-- to ROM
		rom_mode_o: out rammode_t;
		rom_addr_o: out mem_addr_t;
		rom_rdata_i: in dword;
		rom_wdata_o: out dword;
		
		-- COM
		
		-- reuse old codes, no rename yet.
		COMReceiveData: in std_logic_vector(7 downto 0);
	   COMTransmitData: out std_logic_vector(7 downto 0);
	   COMTransmitStart: out std_logic;
	   COMReceiveReady: in std_logic;-- receive: 1 for ready, 0 for not
	   COMTransmitBusy: in std_logic;-- transmit: 1 for busy, 0 for ready
		COMTransmitStartTEST: out std_logic;
		COMTEST: out std_logic;
		
		UART1_IN_ready_o: out std_logic;
		UART1_OUT_ready_o: out std_logic
		
		-- IRQ_HANDLER
--		irq_o: out dword
	);
end MMU;

architecture bhv of MMU is
   signal comRdata, comWdata: std_logic_vector(7 downto 0);
   signal comReadyRead, comLastRead: std_logic;
   signal comReadySend, comLastSend: std_logic;
   signal COMdata: std_logic_vector(31 downto 0);
	signal COMTransmitStart1: std_logic;
--	signal irq: dword := x"ffffff34";
begin

	-- write (happens on clk_i rising edges) (*** not a practical assump. ***)
	-- do not consider forwarding.
	-- because for the 5 insts. in pipeline,
	-- at most one of them is accessing the memory
	
	COMTransmitStart <= COMTransmitStart1;	
	COMTransmitStartTEST <= COMTransmitStart1;
	UART1_IN_ready_o <= to_std_logic(comReadyRead/=comLastRead);
	UART1_OUT_ready_o <= (not COMTransmitBusy) and (comReadySend xor comLastSend);
	COMTEST <= '0';
	
--	irq_o <= x"ffffff34";
	--	MEM && IFF
	process (all)
	begin
		rdata_o <= (others=>'0');
		ram_we_o <= '0';
		ram_addr_o <= (others=>'0');
		MEMRData_o <= (others=>'0');
		rom_wdata_o <= (others=>'0');
		
		if(rst_i = '1') then
			comLastRead <= '0';
         comLastSend <= '1';
--		elsif (intMode_i /= RAM_NOP) then 
--			if (intAddr_i(23 downto 20) = x"3") then --it can't be COM or IRQ in IFF
--				null;
--			elsif (intAddr_i(31 downto 8) = x"FFFFFF") then -- logic element based ROM
--				rom_mode_o <= intMode_i;
--				rom_addr_o <= x"000000" & intAddr_i(7 downto 0);
--				rom_wdata_o <= intwdata_i;
--				intrdata_o <= rom_rdata_i;
--			else -- RAM otherwise
--				if (intMode_i = RAM_READ) then 
--					ram_we_o <= '0';
--				elsif (intMode_i = RAM_WRITE) then 
--					ram_we_o <= '1';
--				end if;
--				ram_addr_o <= intAddr_i(11 downto 2);
--				ram_wdata_o <= intWdata_i;
--				intRdata_o <= ram_rdata_i;
--			end if;
		elsif (MEMMode_i /= RAM_NOP) then
			if (MEMAddr_i(23 downto 20) = x"3") then 
/*				if (MEMAddr_i = x"00300020") then --IRQ_HANDLER
					if (MEMMode_i = RAM_READ) then 
						MEMRData_o <= irq;
					elsif (MEMMode_i = RAM_WRITE) then
						irq <= MEMWData_i;
					end if;
				els*/
				if (MEMAddr_i = x"00300010") then -- UART_IN
					if (MEMMode_i = RAM_READ) then	-- only read the UART_IN can be allowed
						MEMRData_o <= zero_extend(comRdata);
						if(comReadyRead /= comLastRead) then
							comLastRead <= comReadyRead;
						else
							-- error
						end if;
					end if;
				elsif (MEMAddr_i = x"00300000") then -- UART_OUT		
					if (MEMMode_i = RAM_WRITE) then 	-- only write the UART_OUT can be allowed
						if(COMTransmitBusy = '0' and (comLastSend /= comReadySend)) then
							COMTransmitData <= MEMWData_i(7 downto 0);
							comLastSend <= comReadySend;
						else
							--error
						end if;
					end if ;
					
				end if;
			elsif (MEMAddr_i(31 downto 8) = x"FFFFFF") then -- logic element based ROM
				rom_mode_o <= MEMMode_i;
				rom_addr_o <= x"000000" & MEMAddr_i(7 downto 0);
				rom_wdata_o <= MEMwdata_i;
				MEMrdata_o <= rom_rdata_i;
			else -- RAM otherwise
				if (MEMMode_i = RAM_WRITE) then
					ram_we_o <= '1';
				else
					ram_we_o <= '0';
				end if;
				ram_addr_o <= MEMAddr_i(11 downto 2);
				ram_wdata_o <= MEMWData_i;
				MEMrdata_o <= ram_rdata_i;
			end if;
	-- IFF --
		elsif (mode_i /= RAM_NOP) then 
			if (addr_i(23 downto 20) = x"3") then --it can't be COM or IRQ in IFF
				null;
			elsif (addr_i(31 downto 8) = x"FFFFFF") then -- logic element based ROM
				rom_mode_o <= mode_i;
				rom_addr_o <= x"000000" & addr_i(7 downto 0);
				rom_wdata_o <= wdata_i;
				rdata_o <= rom_rdata_i;
			else -- RAM otherwise
				ram_we_o <= '0';
				ram_addr_o <= addr_i(11 downto 2);
				ram_wdata_o <= wdata_i;
				rdata_o <= ram_rdata_i;
			end if;
		end if;
	end process;
	
	 process(all)
    begin
        if (rst_i = '1') then
            comReadyRead <= '0';
            comRdata <= x"00";
        elsif(rising_edge(COMReceiveReady)) then
            comRdata <= COMReceiveData;
            if(comReadyRead = comLastRead) then  -- this should always happen, otherwise a data is ignored.
                comReadyRead <= not comReadyRead;
            end if;
        end if;
    end process;

    process(all)
    begin
        if (rst_i = '1') then
            COMTransmitStart1 <= '0';
            comReadySend <= '0';
        elsif ((comReadySend = comLastSend) and (COMTransmitStart1 = '0')) then
            COMTransmitStart1 <= '1';
        elsif(rising_edge(COMTransmitBusy)) then
            comReadySend <= not comLastSend;
            COMTransmitStart1 <= '0';
        end if;
    end process;
end bhv;

