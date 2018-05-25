library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.consts.ALL;
use IEEE.NUMERIC_STD.ALL;


entity ID_EX is
	port (
		clk_i: in std_logic;
		rst_i: in std_logic;
		halt_i: in std_logic;

		active_i: in std_logic;
		active_o: out std_logic;

		--

		alu_v1_i: in dword;
		alu_v2_i: in dword;
		alu_op_i: in alu_op_t;

		regwr_addr_i: in reg_addr_t;
		regwr_en_i: in std_logic;
		mod_lr_i: in std_logic;

		jb_en_i: in std_logic;

		ram_mode_i: in rammode_t;
		ram_wdata_i: in dword;

		--

		alu_v1_o: out dword;
		alu_v2_o: out dword;
		alu_op_o: out alu_op_t;

		regwr_addr_o: out reg_addr_t;
		regwr_en_o: out std_logic;
		mod_lr_o: out std_logic;
		
		jb_en_o: out std_logic;

		ram_mode_o: out rammode_t;
		ram_wdata_o: out dword
	);
end ID_EX;


architecture behave of ID_EX is
begin

	process (clk_i)
	begin
		if (rising_edge(clk_i)) then
			if (halt_i = '0') then 
				if ((rst_i = '1') or (active_i = '0')) then
					alu_v1_o <= (others=> '0');
					alu_v2_o <= (others=> '0');
					alu_op_o <= ALUOP_ADD;	-- ALUOP_NOP in fact, but ALUOP_ADD can save resources.

					regwr_addr_o <= (others=> '0');
					regwr_en_o <= '0';
					mod_lr_o <= '0';

					active_o <= '0';

					ram_mode_o <= RAM_NOP;
					ram_wdata_o <= (others=> '0');

					jb_en_o <= '0';
				else

					alu_v1_o <= alu_v1_i;
					alu_v2_o <= alu_v2_i;
					alu_op_o <= alu_op_i;

					regwr_addr_o <= regwr_addr_i;
					regwr_en_o <= regwr_en_i;
					mod_lr_o <= mod_lr_i;

					jb_en_o <= jb_en_i;

					active_o <= '1';

					ram_mode_o <= ram_mode_i;
					ram_wdata_o <= ram_wdata_i;
				end if;
			end if;
		end if;
	end process;

end behave;
