library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.consts.ALL;
use IEEE.NUMERIC_STD.ALL;


entity MMU is
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
end MMU;

architecture bhv of MMU is

begin

	-- write (happens on clk_i rising edges) (*** not a practical assump. ***)
	-- do not consider forwarding.
	-- because for the 5 insts. in pipeline,
	-- at most one of them is accessing the memory
	
	--	IFF
	process (all)
	begin
		rdata_o <= (others=>'0');
		ram_mode_o <= RAM_NOP;
		ram_addr_o <= (others=>'0');
		ram_wdata_o <= (others=>'0');

		if (addr_i(23 downto 20) = x"3") then 
			null;
		else -- RAM otherwise
			ram_mode_o <= mode_i;
			ram_addr_o <= addr_i;
			ram_wdata_o <= wdata_i;
			rdata_o <= ram_rdata_i;
		end if;
	end process;
	
	--	MEM
	process (all)
	begin
		ram_MEMMode_o <= RAM_NOP;
		ram_MEMAddr_o <= (others=>'0');
		MEMRData_o <= (others=>'0');
		ram_MEMWData_o <= (others=>'0');
		if (MEMAddr_i(23 downto 20) = x"3") then 
			null;
		else -- RAM otherwise
			ram_MEMMode_o <= MEMMode_i;
			ram_MEMAddr_o <= MEMAddr_i;
			ram_MEMWData_o <= MEMWData_i;
			MEMRdata_o <= ram_MEMRdata_i;
		end if;
	end process;
end bhv;

