library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.consts.ALL;


entity CPU_CORE is
	port (
		rst_i: in std_logic;
		clk_i: in std_logic;

		ram_mode_o: out rammode_t;
		ram_addr_o: out mem_addr_t;
		ram_wdata_o: out dword;
		ram_rdata_i: in dword;

		MEMMode_o: out rammode_t;
		MEMAddr_o: out mem_addr_t;
		MEMRData_i: in dword
	);
end CPU_CORE;


architecture behave of CPU_CORE is

	signal if_active_i: std_logic;
	signal if_pc_o: mem_addr_t;
	signal if_inst: inst_t;

	signal id_reg1_addr_o: reg_addr_t;
	signal id_reg1_data_i: dword;
	signal id_reg2_addr_o: reg_addr_t;
	signal id_reg2_data_i: dword;
	signal id_regwr_addr_o: reg_addr_t;
	signal id_regwr_en_o: std_logic;
	signal id_active_i: std_logic;
	signal id_pc_i: mem_addr_t;
	signal id_inst_i: inst_t;
	signal id_fatal_o: std_logic;
	signal id_alu_v1_o: dword;
	signal id_alu_v2_o: dword;
	signal id_alu_op_o: alu_op_t;
	signal id_jb_en_o: std_logic;
	signal id_ram_mode_o: rammode_t;

	signal ex_active_i: std_logic;
	signal ex_alu_v1_i: dword;
	signal ex_alu_v2_i: dword;
	signal ex_alu_op_i: alu_op_t;
	signal ex_regwr_addr_i: reg_addr_t;
	signal ex_regwr_en_i: std_logic;
	signal ex_fatal_o: std_logic;
	signal ex_regwr_en_o: std_logic;
	signal ex_regwr_addr_o: reg_addr_t;
	signal ex_alu_data_o: dword;
	signal ex_jb_en_i: std_logic;
	signal ex_jb_en_o: std_logic;
	signal ex_jb_pc_o: mem_addr_t;
	signal ex_ram_mode_i: rammode_t;
	signal ex_ram_mode_o: rammode_t;

	signal mem_active_i: std_logic;
	signal mem_regwr_en_i: std_logic;
	signal mem_regwr_addr_i: reg_addr_t;
	signal mem_alu_data_i: dword;
	signal mem_fatal_o: std_logic;
	signal mem_regwr_addr_o: reg_addr_t;
	signal mem_regwr_en_o: std_logic;
	signal mem_regwr_data_o: dword;
	signal mem_jb_en_i: std_logic;
	signal mem_jb_pc_i: mem_addr_t;
	signal mem_ram_mode_i: rammode_t;

	signal wb_regwr_en_i: std_logic;
	signal wb_regwr_addr_i: reg_addr_t;
	signal wb_regwr_data_i: dword;
	signal wb_active_i: std_logic;
	signal wb_jb_en_i: std_logic;
	signal wb_jb_pc_i: mem_addr_t;

begin
	if_inst <= ram_rdata_i;
	ram_mode_o <= RAM_READ;
	ram_addr_o <= if_pc_o;
	ram_wdata_o <= (others=> '0'); -- never write ram now

	MEMMode_o <= mem_ram_mode_i;
	MEMAddr_o <= mem_alu_data_i;

	uregs:
	entity work.REGS
	port map (
		rst_i=> rst_i,
		clk_i=> clk_i,

		raddr1_i=> id_reg1_addr_o,
		rdata1_o=> id_reg1_data_i,
		raddr2_i=> id_reg2_addr_o,
		rdata2_o=> id_reg2_data_i,

		wr_en_i=> wb_active_i and wb_regwr_en_i, -- only when active
		wr_addr_i=> wb_regwr_addr_i,
		wr_data_i=> wb_regwr_data_i
	);


	uif:
	entity work.IFF
	port map (
		clk_i=> clk_i,
		rst_i=> rst_i,

		advance_i=> wb_active_i,

		active_o=> if_active_i,

		jb_en_i=> wb_jb_en_i,
		jb_pc_i=> wb_jb_pc_i,

		pc_o=> if_pc_o
	);


	uif_id:
	entity work.IF_ID
	port map (
		clk_i=> clk_i,
		rst_i=> rst_i,

		active_i=> if_active_i,
		active_o=> id_active_i,

		pc_i=> if_pc_o,
		inst_i=> if_inst,

		pc_o=> id_pc_i,
		inst_o=> id_inst_i
	);


	uid:
	entity work.ID
	port map (
		fatal_o=> id_fatal_o,

		pc_i=> id_pc_i,
		inst_i=> id_inst_i,

		active_i=> id_active_i,

		reg1_data_i=> id_reg1_data_i,
		reg2_data_i=> id_reg2_data_i,
		reg1_addr_o=> id_reg1_addr_o,
		reg2_addr_o=> id_reg2_addr_o,

		alu_v1_o=> id_alu_v1_o,
		alu_v2_o=> id_alu_v2_o,
		alu_op_o=> id_alu_op_o,

		regwr_addr_o=> id_regwr_addr_o,
		regwr_en_o=> id_regwr_en_o,

		jb_en_o=> id_jb_en_o,

		ram_mode_o=> id_ram_mode_o
	);


	uid_ex:
	entity work.ID_EX
	port map (
		clk_i=> clk_i,
		rst_i=> rst_i,

		active_i=> id_active_i,
		active_o=> ex_active_i,

		alu_v1_i=> id_alu_v1_o,
		alu_v2_i=> id_alu_v2_o,
		alu_op_i=> id_alu_op_o,
		regwr_addr_i=> id_regwr_addr_o,
		regwr_en_i=> id_regwr_en_o,
		jb_en_i=> id_jb_en_o,

		alu_v1_o=> ex_alu_v1_i,
		alu_v2_o=> ex_alu_v2_i,
		alu_op_o=> ex_alu_op_i,
		regwr_addr_o=> ex_regwr_addr_i,
		regwr_en_o=> ex_regwr_en_i,

		jb_en_o=> ex_jb_en_i,

		ram_mode_i=> id_ram_mode_o,
		ram_mode_o=> ex_ram_mode_i
	);


	uex:
	entity work.EX
	port map (
		fatal_o=> ex_fatal_o,

		alu_op_i=> ex_alu_op_i,
		alu_v1_i=> ex_alu_v1_i,
		alu_v2_i=> ex_alu_v2_i,

		regwr_en_i=> ex_regwr_en_i,
		regwr_en_o=> ex_regwr_en_o,
		regwr_addr_i=> ex_regwr_addr_i,
		regwr_addr_o=> ex_regwr_addr_o,

		alu_data_o=> ex_alu_data_o,

		jb_en_i=> ex_jb_en_i,
		jb_en_o=> ex_jb_en_o,
		jb_pc_o=> ex_jb_pc_o,

		ram_mode_i=> ex_ram_mode_i,
		ram_mode_o=> ex_ram_mode_o
	);


	uex_mem:
	entity work.EX_MEM
	port map (
		clk_i=> clk_i,
		rst_i=> rst_i,

		active_i=> ex_active_i,
		active_o=> mem_active_i,

		regwr_en_i=> ex_regwr_en_o,
		regwr_addr_i=> ex_regwr_addr_o,
		alu_data_i=> ex_alu_data_o,
		jb_en_i=> ex_jb_en_o,
		jb_pc_i=> ex_jb_pc_o,

		regwr_en_o=> mem_regwr_en_i,
		regwr_addr_o=> mem_regwr_addr_i,
		alu_data_o=> mem_alu_data_i,

		jb_en_o=> mem_jb_en_i,
		jb_pc_o=> mem_jb_pc_i,

		ram_mode_i=> ex_ram_mode_o,
		ram_mode_o=> mem_ram_mode_i
	);


	umem:
	entity work.MEM
	port map (
		fatal_o=> mem_fatal_o,
		active_i=> mem_active_i,

		alu_data_i=> mem_alu_data_i,

		regwr_addr_i=> mem_regwr_addr_i,
		regwr_addr_o=> mem_regwr_addr_o,
		regwr_en_i=> mem_regwr_en_i,
		regwr_en_o=> mem_regwr_en_o,
		regwr_data_o=> mem_regwr_data_o,

		ram_mode_i=> mem_ram_mode_i,
		ramRData_i=> MEMRData_i
	);


	umem_wb:
	entity work.MEM_WB
	port map (
		rst_i=> rst_i,
		clk_i=> clk_i,

		active_i=> mem_active_i,
		active_o=> wb_active_i,

		regwr_addr_i=> mem_regwr_addr_o,
		regwr_en_i=> mem_regwr_en_o,
		regwr_data_i=> mem_regwr_data_o,
		jb_en_i=> mem_jb_en_i,
		jb_pc_i=> mem_jb_pc_i,

		regwr_addr_o=> wb_regwr_addr_i,
		regwr_en_o=> wb_regwr_en_i,
		regwr_data_o=> wb_regwr_data_i,
		jb_en_o=> wb_jb_en_i,
		jb_pc_o=> wb_jb_pc_i
	);

end behave;
