library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


package consts is
	subtype dword is std_logic_vector(31 downto 0);
	subtype byte is std_logic_vector(7 downto 0);
	subtype inst_t is std_logic_vector(31 downto 0);
	subtype mem_addr_t is std_logic_vector(31 downto 0);
	subtype reg_addr_t is std_logic_vector(4 downto 0); -- 32 registers
	subtype opcode_t is std_logic_vector(5 downto 0);
	subtype ram_addr_t is std_logic_vector(12 downto 0);


	constant REG_PC_ADDR: reg_addr_t := "00000";
	constant REG_SP_ADDR: reg_addr_t := "00001";
	constant REG_FP_ADDR: reg_addr_t := "00010";
	constant REG_ZR_ADDR: reg_addr_t := "00011";
	constant REG_FR_ADDR: reg_addr_t := "00100";
	constant REG_WR_ADDR: reg_addr_t := "00101";


	constant OPCODE_ADD: opcode_t := "000000";
	constant OPCODE_SUB: opcode_t := "000001";
	constant OPCODE_MUL: opcode_t := "000010";
	constant OPCODE_AND: opcode_t := "000100";
	constant OPCODE_OR:  opcode_t := "000101";
	constant OPCODE_XOR: opcode_t := "000110";
	constant OPCODE_LOA: opcode_t := "000111";
	constant OPCODE_STO: opcode_t := "001000";
	constant OPCODE_SHR: opcode_t := "001001";
	constant OPCODE_SHL: opcode_t := "001010";
	constant OPCODE_BEQ: opcode_t := "001011";
	constant OPCODE_BLT: opcode_t := "001100";
	constant OPCODE_ADDIU: opcode_t := "001101";
	constant OPCODE_LUI: opcode_t := "001110";
	constant OPCODE_ORI: opcode_t := "010000";
	constant OPCODE_BNE: opcode_t := "010011";
	constant OPCODE_JR: opcode_t := "010100";
	constant OPCODE_JALR: opcode_t := "010101";
	constant OPCODE_JSUB: opcode_t := "010110";
	


	constant BOOT_PC: mem_addr_t := x"FFFFFF00";

	constant INST_NOP: inst_t := x"00000000";


	type alu_op_t is (
		ALUOP_ADD,
		ALUOP_SUB,
		ALUOP_MUL,
		ALUOP_AND,
		ALUOP_OR,
		ALUOP_XOR,
		ALUOP_LOA,
		ALUOP_STO,
		ALUOP_SHR,
		ALUOP_SHL,
		ALUOP_LUI
	);


	type rammode_t is (
		RAM_READ,
		RAM_WRITE,
		RAM_NOP
	);

	-- Returns: 32-bit, sign extended of x
	--	  *** undefined result on x(l to h) instead of (h downto l) ***
	function sign_extend(x: std_logic_vector)
		return std_logic_vector;
	function zero_extend(x: std_logic_vector)
		return std_logic_vector;
	-- Returns 2's complementary code
	function comp_code(x: std_logic_vector)
		return std_logic_vector;
	function to_std_logic(x: boolean)
		return std_logic;

end package;

package body consts is

	function zero_extend(x: std_logic_vector)
		return std_logic_vector
	is
		variable rv: std_logic_vector(31 downto 0);
	begin
		rv(x'length - 1 downto 0) := x;
		rv(rv'length - 1 downto x'length) := (others=> '0');
		return rv;
	end zero_extend;

	function sign_extend(x: std_logic_vector)
		return std_logic_vector
	is
		variable rv: std_logic_vector(31 downto 0);
	begin
		rv(x'length - 1 downto 0) := x;
		rv(rv'length - 1 downto x'length) := (others=> x(x'high));
		return rv;
	end sign_extend;

	function comp_code(x: std_logic_vector)
		return std_logic_vector
	is
		variable rv: std_logic_vector(31 downto 0);
		constant mask: std_logic_vector(31 downto 0) := (others=> '1');
	begin
		rv := mask xor x;
		rv := std_logic_vector(unsigned(rv) + 1);
		return rv;
	end;

	function to_std_logic(x: boolean)
		return std_logic
	is
	begin
		if(x) then
			return '1';
		else
			return '0';
		end if;
	end;

end consts;
