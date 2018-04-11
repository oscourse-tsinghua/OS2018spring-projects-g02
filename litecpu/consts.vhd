library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


package consts is
	subtype dword is std_logic_vector(31 downto 0);
	subtype byte is std_logic_vector(7 downto 0);
	subtype inst_t is std_logic_vector(31 downto 0);
	subtype mem_addr_t is std_logic_vector(31 downto 0);
	subtype reg_addr_t is std_logic_vector(8 downto 0); -- 512 registers
	subtype opcode_t is std_logic_vector(4 downto 0);


	constant REG_PC_ADDR: reg_addr_t := "000000000";
	constant REG_SP_ADDR: reg_addr_t := "000000001";
	constant REG_FP_ADDR: reg_addr_t := "000000010";
	constant REG_ZR_ADDR: reg_addr_t := "000000011";
	constant REG_FR_ADDR: reg_addr_t := "000000011";
	constant REG_WR_ADDR: reg_addr_t := "000000011";


	constant OPCODE_ADD: opcode_t := "00000";
	constant OPCODE_SUB: opcode_t := "00001";
	constant OPCODE_AND: opcode_t := "00100";
	constant OPCODE_OR:  opcode_t := "00101";

	constant BOOT_PC: mem_addr_t := x"00000000";

	constant INST_NOP: inst_t := "00000" & REG_ZR_ADDR & REG_ZR_ADDR & REG_ZR_ADDR;


	type alu_op_t is (
		ALUOP_ADD,
		ALUOP_SUB,
		ALUOP_AND,
		ALUOP_OR
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
