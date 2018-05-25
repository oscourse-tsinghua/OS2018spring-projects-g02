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
		MEMRData_i: in dword;
		MEMWData_o: out dword;
		
/*		intMode_o: out rammode_t;
		intAddr_o: out mem_addr_t;
		intWData_o: out dword;
		intRData_i: in dword;
*/		
		display_reg_o: out std_logic_vector(103 downto 0);
		display_inst_o: out dword;
		
		IDModeTEST: out rammode_t;
		EXModeTEST: out rammode_t;
		
		IFActiveTEST: out std_logic;
		IDActiveTEST: out std_logic;
		EXActiveTEST: out std_logic;
		MEMActiveTEST: out std_logic;
		
		UART1_IN_ready_i: in std_logic;
		UART1_OUT_ready_i: in std_logic;
		
		opcodeTEST: out opcode_t;
		
		irq_i: in dword;
		timer_i: in dword;
		clear_count_i: in std_logic;
		reg_pcTEST: out dword;
		reg_pc_weTEST: out std_logic;
		
		pcTEST: out std_logic;
		
		fatal_o: out std_logic
	);
end CPU_CORE;


architecture behave of CPU_CORE is

	signal watch_reg: std_logic_vector(103 downto 0);
	
	signal halt: std_logic;

	signal reg_pc: dword;
	signal reg_pc_we: std_logic; 
	
	signal reg_active: std_logic;
	signal reg_halt: std_logic;
	signal recover: std_logic;
	
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
	signal id_ram_wdata_o: dword;

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
	signal ex_ram_wdata_i: dword;
	signal ex_ram_wdata_o: dword;

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
	signal mem_ram_wdata_i: dword;

	signal wb_regwr_en_i: std_logic;
	signal wb_regwr_addr_i: reg_addr_t;
	signal wb_regwr_data_i: dword;
	signal wb_active_i: std_logic;
	signal wb_jb_en_i: std_logic;
	signal wb_jb_pc_i: mem_addr_t;

begin
	if_inst <= ram_rdata_i;
	display_inst_o <= ram_rdata_i;
	
	ram_mode_o <= RAM_READ;
	ram_addr_o <= if_pc_o;
	ram_wdata_o <= (others=> '0'); -- never write ram now
	MEMWData_o <= mem_ram_wdata_i;

	MEMMode_o <= mem_ram_mode_i;
	MEMAddr_o <= mem_alu_data_i;
	
	IDModeTEST <= id_ram_mode_o;
	EXModeTEST <= ex_ram_mode_o;

	IFActiveTEST <= if_active_i;
	IDActiveTEST <= id_active_i;
	EXActiveTEST <= ex_active_i;
	MEMActiveTEST <= mem_active_i;
	
	display_reg_o <= watch_reg;
	reg_pcTEST <= reg_pc;
	reg_pc_weTEST <= reg_pc_we;
	
	fatal_o <= id_fatal_o;
	uregs:
	entity work.REGS
	port map (
		rst_i=> rst_i,
		clk_i=> not clk_i,
		halt_o => halt,

		raddr1_i=> id_reg1_addr_o,
		rdata1_o=> id_reg1_data_i,
		raddr2_i=> id_reg2_addr_o,
		rdata2_o=> id_reg2_data_i,

		wr_en_i=> wb_active_i and wb_regwr_en_i, -- only when active
		wr_addr_i=> wb_regwr_addr_i,
		wr_data_i=> wb_regwr_data_i,
		
		display_reg_o=> watch_reg,
		
		UART1_IN_ready_i => UART1_IN_ready_i,
		UART1_OUT_ready_i => UART1_OUT_ready_i,
		
		pc_i => if_pc_o,
		pc_o => reg_pc,
		pc_we_o => reg_pc_we,
		
		irq_i => irq_i,
		timer_i => timer_i,
		clear_count_i => clear_count_i,
--		reg_halt_o => reg_halt,
--		active_o => reg_active,
		active_i => wb_active_i
		
/*		int_mode_o => intMode_o,
		int_Addr_o => intAddr_o,
		int_wdata_o => intWdata_o,
		recover_o => recover*/
	);


	uif:
	entity work.IFF
	port map (
		clk_i=> clk_i,
		rst_i=> rst_i,
		halt_i=> halt,

		advance_i=> wb_active_i,

		active_o=> if_active_i,

		jb_en_i=> wb_jb_en_i,
		jb_pc_i=> wb_jb_pc_i,

		pc_o=> if_pc_o,
		
		pc_i=> reg_pc,
		pc_we_i=> reg_pc_we,
		
		pcTEST => pcTEST
		
	/*	reg_halt_i=> reg_halt,
		reg_active_i=> reg_active
		
		recover_i=> recover,
		intRdata_i=>intRdata_i*/
	);


	uif_id:
	entity work.IF_ID
	port map (
		clk_i=> clk_i,
		rst_i=> rst_i,
		halt_i=> halt,

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

		ram_mode_o=> id_ram_mode_o,
		ram_wdata_o=> id_ram_wdata_o,
		
		opcodeTEST => opcodeTEST
	);


	uid_ex:
	entity work.ID_EX
	port map (
		clk_i=> clk_i,
		rst_i=> rst_i,
		halt_i=> halt,

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
		ram_mode_o=> ex_ram_mode_i,
		ram_wdata_i=> id_ram_wdata_o,
		ram_wdata_o=> ex_ram_wdata_i
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
		ram_mode_o=> ex_ram_mode_o,
		ram_wdata_i=> ex_ram_wdata_i,
		ram_wdata_o=> ex_ram_wdata_o
	);


	uex_mem:
	entity work.EX_MEM
	port map (
		clk_i=> clk_i,
		rst_i=> rst_i,
		halt_i=> halt,

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
		ram_mode_o=> mem_ram_mode_i,
		ram_wdata_i=> ex_ram_wdata_o,
		ram_wdata_o=> mem_ram_wdata_i
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
		halt_i=> halt,

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
