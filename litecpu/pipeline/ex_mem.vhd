library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.consts.ALL;
use IEEE.NUMERIC_STD.ALL;


entity EX_MEM is
	port (
		clk_i: in std_logic;
		rst_i: in std_logic;

		active_i: in std_logic;
		active_o: out std_logic;

		regwr_en_i: in std_logic;
		regwr_addr_i: in reg_addr_t;
		alu_data_i: in dword;

		jb_en_i: std_logic;
		jb_pc_i: mem_addr_t;

		ram_mode_i: in rammode_t;
		ram_wdata_i: in dword;

		--

		regwr_en_o: out std_logic;
		regwr_addr_o: out reg_addr_t;
		alu_data_o: out dword;

		jb_en_o: out std_logic;
		jb_pc_o: out mem_addr_t;

		ram_mode_o: out rammode_t;
		ram_wdata_o: out dword
	);
end EX_MEM;


architecture behave of EX_MEM is
begin

	process (clk_i)
	begin
		if (rising_edge(clk_i)) then
			if ((rst_i = '1') or (active_i = '0')) then
				-- TODO: needn't make regwr_addr or alu_data empty here
				--	because regwr_en gates them.
				-- This could reduce resource usage.
				regwr_en_o <= '0';
				regwr_addr_o <= (others=> '0');
				alu_data_o <= (others=> '0');
				active_o <= '0';
				ram_mode_o <= RAM_NOP;
				ram_wdata_o <= (others=> '0');

				jb_en_o <= '0';
				jb_pc_o <= (others=> '0');
			else

				regwr_en_o <= regwr_en_i;
				regwr_addr_o <= regwr_addr_i;
				alu_data_o <= alu_data_i;
				active_o <= '1';

				jb_en_o <= jb_en_i;
				jb_pc_o <= jb_pc_i;

				ram_mode_o <= ram_mode_i;
				ram_wdata_o <= ram_wdata_i;
			end if;
		end if;
	end process;

end behave;
