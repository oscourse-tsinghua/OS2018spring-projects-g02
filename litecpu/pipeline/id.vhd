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
		mod_lr_o: out std_logic;

		jb_en_o: out std_logic;

		ram_mode_o: out rammode_t;
		ram_wdata_o: out dword;
		
		opcodeTEST: out opcode_t
	);
end ID;


architecture behave of ID is
	signal opcode: opcode_t;
	signal r1_addr: reg_addr_t;
	signal r2_addr: reg_addr_t;
	signal r3_addr: reg_addr_t;
	signal boffset: std_logic_vector(25 downto 0); -- branch offset
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

	opcode <= inst_i(31 downto 26);
	r3_addr <= inst_i(25 downto 21);
	r1_addr <= inst_i(20 downto 16);
	r2_addr <= inst_i(15 downto 11);
	boffset <= inst_i(25 downto 0);
	liimm <= inst_i(15 downto 0);

	pc_next <= std_logic_vector(unsigned(pc_i) + 4);

	opcodeTEST <= opcode;

	process (all)
	begin
		if (OPCODE = OPCODE_BEQ or OPCODE = OPCODE_BLT or OPCODE = OPCODE_BNE) then
			reg1_addr <= r3_addr;
			reg2_addr <= r1_addr;
		elsif (opcode = OPCODE_STO) then
			-- TODO: why here?
			reg1_addr <= r1_addr;
			reg2_addr <= r3_addr;
		elsif (opcode = OPCODE_JR or OPCODE = OPCODE_JALR) then 
			reg1_addr <= r3_addr;
			reg2_addr <= r1_addr;
		elsif (opcode = OPCODE_JSUB) then 
			reg1_addr <= "00000";
			reg2_addr <= r2_addr;
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


	reg1_data <= reg1_data_i;
	reg2_data <= reg2_data_i;


	process (all)
	begin
		-- default values
		fatal_o <= '0';
		alu_v1_o <= (others=> '0');
		alu_v2_o <= (others=> '0');
		alu_op_o <= ALUOP_ADD;
		regwr_en <= '0';
		jb_en_o <= '0';
		ram_wdata <= (others=> '0');
		mod_lr_o <= '0';

		case opcode is
			when OPCODE_ADD =>
				alu_v1_o <= reg1_data;
				alu_v2_o <= reg2_data;
				alu_op_o <= ALUOP_ADD;
				ram_mode <= RAM_NOP;
				regwr_en <= '1';

			when OPCODE_SUB =>
				alu_v1_o <= reg1_data;
				alu_v2_o <= reg2_data;
				alu_op_o <= ALUOP_SUB;
				ram_mode <= RAM_NOP;
				regwr_en <= '1';
				
			when OPCODE_MUL =>
				alu_v1_o <= reg1_data;
				alu_v2_o <= reg2_data;
				alu_op_o <= ALUOP_MUL;
				ram_mode <= RAM_NOP;
				regwr_en <= '1';

			when OPCODE_AND =>
				alu_v1_o <= reg1_data;
				alu_v2_o <= reg2_data;
				alu_op_o <= ALUOP_AND;
				ram_mode <= RAM_NOP;
				regwr_en <= '1';

			when OPCODE_OR =>
				alu_v1_o <= reg1_data;
				alu_v2_o <= reg2_data;
				alu_op_o <= ALUOP_OR;
				ram_mode <= RAM_NOP;
				regwr_en <= '1';

			when OPCODE_XOR =>
				alu_v1_o <= reg1_data;
				alu_v2_o <= reg2_data; -- unused, for resources
				alu_op_o <= ALUOP_XOR;
				ram_mode <= RAM_NOP;
				regwr_en <= '1';

			when OPCODE_LOA =>
				alu_v1_o <= reg1_data;
				alu_v2_o <= x"0000" & liimm;
				alu_op_o <= ALUOP_LOA;
				ram_mode <= RAM_READ;
				regwr_en <= '1';

			when OPCODE_STO =>
				alu_v1_o <= reg1_data;
				alu_v2_o <= x"0000" & liimm;
				alu_op_o <= ALUOP_STO;
				ram_mode <= RAM_WRITE;
				ram_wdata <= reg2_data;
				regwr_en <= '0';

			when OPCODE_SHR =>
				alu_v1_o <= reg1_data;
				alu_v2_o <= reg2_data;
				alu_op_o <= ALUOP_SHR;
				ram_mode <= RAM_NOP;
				regwr_en <= '1';

			when OPCODE_SHL =>
				alu_v1_o <= reg1_data;
				alu_v2_o <= reg2_data;
				alu_op_o <= ALUOP_SHL;
				ram_mode <= RAM_NOP;
				regwr_en <= '1';

			-- TODO: merge bxx so only 1 adder will be used
			when OPCODE_BEQ =>
				if (reg1_data = reg2_data) then
					jb_en_o <= '1';
					alu_op_o <= ALUOP_ADD;
					alu_v1_o <= std_logic_vector(
							   unsigned(pc_next) + unsigned(sign_extend(liimm)));
					alu_v2_o <= (others=> '0');
				end if;
				ram_mode <= RAM_NOP;

			-- unsigned comparison here: refer to emulators
			when OPCODE_BLT =>
				if (unsigned(reg1_data) < unsigned(reg2_data)) then
					jb_en_o <= '1';
					alu_op_o <= ALUOP_ADD;
					alu_v1_o <= std_logic_vector(
							   unsigned(pc_next) + unsigned(sign_extend(liimm)));
					alu_v2_o <= (others=> '0');
				end if;
				ram_mode <= RAM_NOP;

			when OPCODE_BNE =>
				if (reg1_data /= reg2_data) then 
					jb_en_o <= '1';
					alu_op_o <= ALUOP_ADD;
					alu_v1_o <= std_logic_vector(
							   unsigned(pc_next) + unsigned(sign_extend(liimm)));
					alu_v2_o <= (others=> '0');
				end if;
				ram_mode <= RAM_NOP;
				
			when OPCODE_JR =>
				jb_en_o <= '1';
				alu_op_o <= ALUOP_ADD;
				alu_v1_o <= reg1_data;
				alu_v2_o <= (others => '0');
				ram_mode <= RAM_NOP;
				
			when OPCODE_ADDIU =>
				alu_v1_o <= reg1_data;
				alu_v2_o <= sign_extend(liimm);
				alu_op_o <= ALUOP_ADD;
				ram_mode <= RAM_NOP;
				regwr_en <= '1';
			
			when OPCODE_LUI =>
				alu_v1_o <= reg1_data;
				alu_v2_o <= liimm & x"0000";
				alu_op_o <= ALUOP_LUI;
				ram_mode <= RAM_NOP;
				regwr_en <= '1';
				
			when OPCODE_ORI =>
				alu_v1_o <= reg1_data;
				alu_v2_o <= x"0000" & liimm;
				alu_op_o <= ALUOP_OR;
				ram_mode <= RAM_NOP;
				regwr_en <= '1';
				
			when OPCODE_JALR =>
				alu_v1_o <= reg1_data;
				alu_v2_o <= x"00000000";
				alu_op_o <= ALUOP_ADD;
				ram_mode <= RAM_NOP;
				mod_lr_o <= '1';
				
			when OPCODE_JSUB =>
				alu_v1_o <= pc_next;
				alu_v2_o <= sign_extend(boffset);
				alu_op_o <= ALUOP_ADD;
				ram_mode <= RAM_NOP;
				mod_lr_o <= '1';
			
			when others =>
				fatal_o <= '1';
				ram_mode <= RAM_NOP;
		end case;

		if ((reg3_addr = REG_PC_ADDR) and (regwr_en = '1')) then
			jb_en_o <= '1';
		end if;

	end process;

end behave;
