library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.consts.ALL;
use IEEE.NUMERIC_STD.ALL;


entity ID is
	port (
		fatal_o: out std_logic;

		pc_i: in mem_addr_t;
		inst_i: in inst_t;

		active_i: in std_logic;

		reg1_data_i: in dword;
		reg2_data_i: in dword;
		reg1_addr_o: out reg_addr_t;
		reg2_addr_o: out reg_addr_t;

		alu_v1_o: out dword;
		alu_v2_o: out dword;
		alu_op_o: out alu_op_t;

		regwr_addr_o: out reg_addr_t;
		regwr_en_o: out std_logic
	);
end ID;

architecture behave of ID is
	signal opcode: opcode_t;
	signal r1_addr: reg_addr_t;
	signal r2_addr: reg_addr_t;
	signal r3_addr: reg_addr_t;
	signal boffset: std_logic_vector(8 downto 0); -- branch offset
	signal liimm: std_logic_vector(15 downto 0);  -- imm of load imm

begin


	opcode <= inst_i(31 downto 27);
	r1_addr <= inst_i(26 downto 18);
	r2_addr <= inst_i(17 downto 9);
	r3_addr <= inst_i(8 downto 0);
	boffset <= r3_addr;
	liimm <= inst_i(15 downto 0);

	reg1_addr_o <= r1_addr;
	reg2_addr_o <= r2_addr;
	regwr_addr_o <= r3_addr;

	process (all)
	begin
		-- default values
		fatal_o <= '0';
		alu_v1_o <= (others=> '0');
		alu_v2_o <= (others=> '0');
		alu_op_o <= ALUOP_ADD;
		regwr_en_o <= '0';

		case opcode is
			when OPCODE_ADD =>
				alu_v1_o <= reg1_data_i;
				alu_v2_o <= reg2_data_i;
				alu_op_o <= ALUOP_ADD;
				regwr_en_o <= '1';

			when others =>
				fatal_o <= '1';
		end case;

	end process;

end behave;
