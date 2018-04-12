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
		regwr_en_o: out std_logic;

		jb_en_o: out std_logic;
		jb_pc_o: out mem_addr_t;

		ram_mode_o: out rammode_t
	);
end ID;


architecture behave of ID is
	signal opcode: opcode_t;
	signal r1_addr: reg_addr_t;
	signal r2_addr: reg_addr_t;
	signal r3_addr: reg_addr_t;
	signal boffset: mem_addr_t; -- branch offset
	signal liimm: std_logic_vector(15 downto 0);  -- imm of load imm
	signal ram_mode: rammode_t;

begin
	ram_mode_o <= ram_mode;

	opcode <= inst_i(31 downto 27);
	r3_addr <= inst_i(26 downto 18);
	r1_addr <= inst_i(17 downto 9);
	r2_addr <= inst_i(8 downto 0);
	boffset <= sign_extend(r2_addr)(29 downto 0) & "00";
	liimm <= inst_i(15 downto 0);


	process (all)
	begin
		if (opcode = OPCODE_SHR or opcode = OPCODE_SHL or OPCODE = OPCODE_BEQ or OPCODE = OPCODE_BLT) then
			reg1_addr_o <= r3_addr;
			reg2_addr_o <= r1_addr;
		else
			reg1_addr_o <= r1_addr;
			reg2_addr_o <= r2_addr;
		end if;
	end process;
	regwr_addr_o <= r3_addr;

	process (all)
	begin
		-- default values
		fatal_o <= '0';
		alu_v1_o <= (others=> '0');
		alu_v2_o <= (others=> '0');
		alu_op_o <= ALUOP_ADD;
		regwr_en_o <= '0';
		jb_en_o <= '0';
		jb_pc_o <= (others=> '0');
		ram_mode <= RAM_NOP;

		case opcode is
			when OPCODE_ADD =>
				alu_v1_o <= reg1_data_i;
				alu_v2_o <= reg2_data_i;
				alu_op_o <= ALUOP_ADD;
				regwr_en_o <= '1';

			when OPCODE_SUB =>
				alu_v1_o <= reg1_data_i;
				alu_v2_o <= reg2_data_i;
				alu_op_o <= ALUOP_SUB;
				regwr_en_o <= '1';

			when OPCODE_AND =>
				alu_v1_o <= reg1_data_i;
				alu_v2_o <= reg2_data_i;
				alu_op_o <= ALUOP_AND;
				regwr_en_o <= '1';

			when OPCODE_OR =>
				alu_v1_o <= reg1_data_i;
				alu_v2_o <= reg2_data_i;
				alu_op_o <= ALUOP_OR;
				regwr_en_o <= '1';

			when OPCODE_NOT =>
				alu_v1_o <= reg1_data_i;
				alu_v2_o <= reg2_data_i; -- unused, for resources
				alu_op_o <= ALUOP_NOT;
				regwr_en_o <= '1';

			when OPCODE_LOA =>
				alu_v1_o <= reg1_data_i;
				alu_v2_o <= reg2_data_i;
				alu_op_o <= ALUOP_LOA;
				ram_mode <= RAM_READ;
				regwr_en_o <= '1';

			when OPCODE_SHR =>
				alu_v1_o <= reg1_data_i;
				alu_v2_o <= reg2_data_i;
				alu_op_o <= ALUOP_SHR;
				regwr_en_o <= '1';

			when OPCODE_SHL =>
				alu_v1_o <= reg1_data_i;
				alu_v2_o <= reg2_data_i;
				alu_op_o <= ALUOP_SHL;
				regwr_en_o <= '1';

			-- TODO: merge bxx so only 1 adder will be used
			when OPCODE_BEQ =>
				if (reg1_data_i = reg2_data_i) then
					jb_en_o <= '1';
					jb_pc_o <= std_logic_vector(unsigned(pc_i)
							   + 4 + unsigned(boffset));
				end if;

			-- unsigned comparison here: refer to emulators
			when OPCODE_BLT =>
				if (unsigned(reg1_data_i) < unsigned(reg2_data_i)) then
					jb_en_o <= '1';
					jb_pc_o <= std_logic_vector(unsigned(pc_i)
							   + 4 + unsigned(boffset));
				end if;

			when OPCODE_LL =>
				alu_v1_o <= x"0000" & liimm;
				alu_v2_o <= reg2_data_i;
				alu_op_o <= ALUOP_LL;
				regwr_en_o <= '1';

			when others =>
				fatal_o <= '1';
		end case;

	end process;

end behave;
