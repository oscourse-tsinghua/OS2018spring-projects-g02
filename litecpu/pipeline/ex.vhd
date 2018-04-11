library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.consts.ALL;
use IEEE.NUMERIC_STD.ALL;


entity EX is
    port (
		fatal_o: out std_logic;

		alu_op_i: in alu_op_t;
		alu_v1_i: in dword;
		alu_v2_i: in dword;

		regwr_en_i: in std_logic;
		regwr_en_o: out std_logic;
		regwr_addr_i: in reg_addr_t;
		regwr_addr_o: out reg_addr_t;

		alu_data_o: out dword
	);
end EX;


architecture behave of EX is
begin

	regwr_en_o <= regwr_en_i;
	regwr_addr_o <= regwr_addr_i;


	process (all)
	begin
		alu_data_o <= (others=> '0');
	 	fatal_o <= '0';

		case alu_op_i is
			when ALUOP_ADD =>
				alu_data_o <= std_logic_vector(unsigned(alu_v1_i) + unsigned(alu_v2_i));
			when ALUOP_SUB =>
				alu_data_o <= std_logic_vector(unsigned(alu_v1_i) - unsigned(alu_v2_i));
			when ALUOP_AND =>
				alu_data_o <= alu_v1_i and alu_v2_i;
			when ALUOP_OR =>
				alu_data_o <= alu_v1_i or alu_v2_i;
			
			when others =>
				fatal_o <= '1';
		end case;
	end process;

end behave;
