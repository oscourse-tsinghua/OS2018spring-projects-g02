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

		ram_mode_o: out rammode_t;
		ram_wdata_o: out dword
	);
end ID;


architecture behave of ID is
	signal opcode: opcode_t;
	signal r1_addr: reg_addr_t;
	signal r2_addr: reg_addr_t;
	signal r3_addr: reg_addr_t;
	signal boffset: mem_addr_t; -- branch offset
	signal pc_next: mem_addr_t; -- i.e. pc+4
	signal liimm: std_logic_vector(15 downto 0);  -- imm of load imm
	signal ram_mode: rammode_t;

	signal reg1_addr: reg_addr_t;
	signal reg2_addr: reg_addr_t;
	signal reg1_data: dword;
	signal reg2_data: dword;
	signal reg3_addr: reg_addr_t;
	signal regwr_en: std_logic;

	signal ram_wdata: dword;

begin
	ram_mode_o <= ram_mode;
	ram_wdata_o <= ram_wdata;

	opcode <= inst_i(31 downto 27);
	r3_addr <= inst_i(26 downto 18);
	r1_addr <= inst_i(17 downto 9);
	r2_addr <= inst_i(8 downto 0);
	boffset <= sign_extend(r2_addr)(29 downto 0) & "00";
	liimm <= inst_i(15 downto 0);

	pc_next <= std_logic_vector(unsigned(pc_i) + 4);


	process (all)
	begin
		if (opcode = OPCODE_SHR or opcode = OPCODE_SHL
				or OPCODE = OPCODE_BEQ or OPCODE = OPCODE_BLT) then
			reg1_addr <= r3_addr;
			reg2_addr <= r1_addr;
		elsif (opcode = OPCODE_STO) then
			-- TODO: why here?
			reg1_addr <= r1_addr;
			reg2_addr <= r3_addr;
		else
			reg1_addr <= r1_addr;
			reg2_addr <= r2_addr;
		end if;
	end process;


	reg1_addr_o <= reg1_addr;
	reg2_addr_o <= reg2_addr;
	reg3_addr <= r3_addr;
	regwr_addr_o <= reg3_addr;
	regwr_en_o <= regwr_en;


	-- if we read from PC we don't actually read from REGS(0)
	process (all)
	begin
		if (reg1_addr = REG_PC_ADDR) then
			reg1_data <= pc_next;
		else
			reg1_data <= reg1_data_i;
		end if;
	end process;


	process (all)
	begin
		if (reg2_addr = REG_PC_ADDR) then
			reg2_data <= pc_next;
		else
			reg2_data <= reg2_data_i;
		end if;
	end process;


	process (all)
	begin
		-- default values
		fatal_o <= '0';
		alu_v1_o <= (others=> '0');
		alu_v2_o <= (others=> '0');
		alu_op_o <= ALUOP_ADD;
		regwr_en <= '0';
		jb_en_o <= '0';
		ram_mode <= RAM_NOP;
		ram_wdata <= (others=> '0');

		case opcode is
			when OPCODE_ADD =>
				alu_v1_o <= reg1_data;
				alu_v2_o <= reg2_data;
				alu_op_o <= ALUOP_ADD;
				regwr_en <= '1';

			when OPCODE_SUB =>
				alu_v1_o <= reg1_data;
				alu_v2_o <= reg2_data;
				alu_op_o <= ALUOP_SUB;
				regwr_en <= '1';
				
			when OPCODE_MUL =>
				alu_v1_o <= reg1_data;
				alu_v2_o <= reg2_data;
				alu_op_o <= ALUOP_MUL;
				regwr_en <= '1';

			when OPCODE_DIV =>
				-- DIV_ZERO should be set, but FR is not supported now --
				alu_v1_o <= reg1_data;
				alu_v2_o <= reg2_data;
				alu_op_o <= ALUOP_DIV;
				regwr_en <= '1';
				
			when OPCODE_AND =>
				alu_v1_o <= reg1_data;
				alu_v2_o <= reg2_data;
				alu_op_o <= ALUOP_AND;
				regwr_en <= '1';

			when OPCODE_OR =>
				alu_v1_o <= reg1_data;
				alu_v2_o <= reg2_data;
				alu_op_o <= ALUOP_OR;
				regwr_en <= '1';

			when OPCODE_NOT =>
				alu_v1_o <= reg1_data;
				alu_v2_o <= reg2_data; -- unused, for resources
				alu_op_o <= ALUOP_NOT;
				regwr_en <= '1';

			when OPCODE_LOA =>
				alu_v1_o <= reg1_data;
				alu_v2_o <= reg2_data;
				alu_op_o <= ALUOP_LOA;
				ram_mode <= RAM_READ;
				regwr_en <= '1';

			when OPCODE_STO =>
				alu_v1_o <= reg1_data;
				alu_v2_o <= reg2_data;
				alu_op_o <= ALUOP_STO;
				ram_mode <= RAM_WRITE;
				ram_wdata <= reg1_data;
				regwr_en <= '0';

			when OPCODE_SHR =>
				alu_v1_o <= reg1_data;
				alu_v2_o <= reg2_data;
				alu_op_o <= ALUOP_SHR;
				regwr_en <= '1';

			when OPCODE_SHL =>
				alu_v1_o <= reg1_data;
				alu_v2_o <= reg2_data;
				alu_op_o <= ALUOP_SHL;
				regwr_en <= '1';

			-- TODO: merge bxx so only 1 adder will be used
			when OPCODE_BEQ =>
				if (reg1_data = reg2_data) then
					jb_en_o <= '1';
					alu_op_o <= ALUOP_ADD;
					alu_v1_o <= std_logic_vector(
							   unsigned(pc_next) + unsigned(boffset));
					alu_v2_o <= (others=> '0');
				end if;

			-- unsigned comparison here: refer to emulators
			when OPCODE_BLT =>
				if (unsigned(reg1_data) < unsigned(reg2_data)) then
					jb_en_o <= '1';
					alu_op_o <= ALUOP_ADD;
					alu_v1_o <= std_logic_vector(
							   unsigned(pc_next) + unsigned(boffset));
					alu_v2_o <= (others=> '0');
				end if;

			when OPCODE_LL =>
				alu_v1_o <= x"0000" & liimm;
				alu_v2_o <= reg2_data;
				alu_op_o <= ALUOP_LL;
				regwr_en <= '1';

			when others =>
				fatal_o <= '1';
		end case;

		if ((reg3_addr = REG_PC_ADDR) and (regwr_en = '1')) then
			jb_en_o <= '1';
		end if;

	end process;

end behave;
