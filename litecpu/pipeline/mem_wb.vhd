library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.consts.ALL;
use IEEE.NUMERIC_STD.ALL;


-- In fact there's no explicit WB stage
--	output of MEM_WB goes directly to other modules such as REGS
entity MEM_WB is
	port (
		rst_i: in std_logic;
		clk_i: in std_logic;

		active_i: in std_logic;
		active_o: out std_logic;

		regwr_addr_i: in reg_addr_t;
		regwr_en_i: in std_logic;
		regwr_data_i: in dword;

		jb_en_i: in std_logic;
		jb_pc_i: in mem_addr_t;

		--

		regwr_addr_o: out reg_addr_t;
		regwr_en_o: out std_logic;
		regwr_data_o: out dword;

		jb_en_o: out std_logic;
		jb_pc_o: out mem_addr_t
	);
end MEM_WB;


architecture behave of MEM_WB is

begin
	process (clk_i)
	begin
		if (rising_edge(clk_i)) then
			regwr_addr_o <= (others=> '0');
			regwr_en_o <= '0';
			regwr_data_o <= (others=> '0');
			active_o <= '0';
			jb_en_o <= '0';
			jb_pc_o <= (others=> '0');

			if ((rst_i = '1') or (active_i = '0')) then
				null;
			else 
				regwr_addr_o <= regwr_addr_i;
				regwr_en_o <= regwr_en_i;
				regwr_data_o <= regwr_data_i;
				jb_en_o <= jb_en_i;
				jb_pc_o <= jb_pc_i;
				active_o <= '1';
			end if;
		end if;
	end process;
end behave;
