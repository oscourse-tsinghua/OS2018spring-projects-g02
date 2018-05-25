library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.consts.ALL;
use IEEE.NUMERIC_STD.ALL;


entity REGS is
    port (
		rst_i: in std_logic;
		clk_i: in std_logic;

		raddr1_i: in reg_addr_t;
		rdata1_o: out dword;
		raddr2_i: in reg_addr_t;
		rdata2_o: out dword;

		wr_en_i: in std_logic;
		wr_addr_i: in reg_addr_t;
		wr_data_i: in dword;
		 		
		pc_i: in dword;
		pc_we_o: out std_logic;
		pc_o: out dword;		
		
		-- Deal with interrupts or exceptions --
		halt_o: out std_logic;
		
		display_reg_o: out std_logic_vector(103 downto 0);
		
		UART1_IN_ready_i: in std_logic;
		UART1_OUT_ready_i: in std_logic;
		
		irq_i: in dword;
		timer_i: in dword;
		clear_count_i: in std_logic;
		
		-- halt the cpu for a clk period to handle interrupt
		active_i: in std_logic
--		reg_halt_o: out std_logic;
--	   active_o: out std_logic;
		
--		int_mode_o: out rammode_t;
--		int_addr_o: out mem_addr_t;
--		int_wdata_o: out dword;
		
--		recover_o: out std_logic
	);
end REGS;

architecture behave of REGS is
	-- TODO: probably fixing this bug? or feature?
	-- pretend there are 512 registers when there are only 32
	type t_reg_regs is array(32 downto 0) of dword;
	signal regs: t_reg_regs;

	-- real address: the lowest 5 bit of expected address
	signal real_r1_addr: std_logic_vector(4 downto 0);
	signal real_r2_addr: std_logic_vector(4 downto 0);
	signal real_wr_addr: std_logic_vector(4 downto 0);

	signal UART1_IN_ready: std_logic := '0';
	signal UART1_IN_last_ready: std_logic := '0';
	signal UART1_OUT_ready: std_logic := '0';
	signal UART1_OUT_last_ready: std_logic := '0';
	
--	signal reg_halt: std_logic;
	
	signal pc_we: std_logic;
	
	signal current_sp: dword;
	signal current_pc: dword;
	signal recover_int: std_logic;
	signal assert_int: std_logic;
	
	signal count: dword;
begin
	pc_o <= regs(0);
	pc_we_o <= pc_we;
	real_wr_addr <= wr_addr_i(4 downto 0);
	real_r1_addr <= raddr1_i(4 downto 0);
	real_r2_addr <= raddr2_i(4 downto 0);
	halt_o <= regs(4)(0);
	display_reg_o <=  
	regs(18)(7 downto 0) &
	regs(4)(15 downto 8) &
	regs(4)(7 downto 0) &
	regs(14)(7 downto 0) & 
	regs(13)(7 downto 0) & 
	regs(12)(7 downto 0) &
	regs(11)(7 downto 0) &
	regs(10)(15 downto 8) &
	regs(9)(7 downto 0) &
	regs(8)(7 downto 0) &
	regs(7)(7 downto 0) &
	regs(6)(15 downto 8) &
	regs(0)(7 downto 0)
	;
--	reg_halt_o <= reg_halt;
	-- writing to ZR and WR will have no effect as their reads are
	--	hardcoded
	
	process (UART1_IN_ready_i, rst_i)
	begin
		if (rst_i = '1') then 
			UART1_IN_last_ready <= '0';
		elsif (rising_edge(UART1_IN_ready_i)) then 
			UART1_IN_last_ready <= not UART1_IN_last_ready;
		end if;
	end process;
	
	process (UART1_OUT_ready_i, rst_i)
	begin
		if (rst_i = '1') then 
			UART1_OUT_last_ready <= '0';
		elsif (rising_edge(UART1_OUT_ready_i)) then 
			UART1_OUT_last_ready <= not UART1_OUT_last_ready;
		end if;
	end process;

	process (rst_i, clk_i)
	begin
		if (rst_i = '1') then 
			regs(4) <= x"00000200";
			UART1_IN_ready <= '0';
			UART1_OUT_ready <= '1';
			assert_int <= '0';
		elsif (rising_edge(clk_i)) then
/*			int_mode_o <= RAM_NOP;
			int_addr_o <= (others=> '0');
			int_wdata_o <= (others=> '0');
			recover_o <= '0';
			active_o <= '0';
*/			if (pc_we = '1') then 
				pc_we <= '0';
			else 
				regs(0) <= pc_i;
			end if;
			if (wr_en_i = '1') then
				regs(to_integer(unsigned(real_wr_addr))) <= wr_data_i;
				if (real_wr_addr = "00000") then 
					pc_we <= '1';
				elsif ((real_wr_addr = "00100") and (wr_data_i(2) = '1')) then 
					regs(4)(1) <= '1';
					regs(4)(2) <= '0';
									
					regs(0) <= regs(18);
					pc_we <= '1';
				elsif ((real_wr_addr = "00100") and (wr_data_i(3) = '1')) then 
					count <= x"00000000";
				end if;
			end if;
			if (UART1_IN_last_ready /= UART1_IN_ready) then 
				regs(4)(10) <= '1';
				if ((regs(4)(7) = '1') and regs(4)(1) = '1') then	-- if interrupt is enabled, emit interrupt signal
					regs(4)(8) <= '1';
					regs(4)(1) <= '0';

					assert_int <= '1';
				end if;
				UART1_IN_ready <= UART1_IN_last_ready;
			end if;
			if (UART1_OUT_last_ready /= UART1_OUT_ready) then
				regs(4)(9) <= '1';
				if ((regs(4)(5) = '1') and regs(4)(1) = '1') then	-- if interrupt is enabled, emit interrupt signal
					regs(4)(6) <= '1';
					regs(4)(1) <= '0';

					assert_int <= '1';
				end if;
				UART1_OUT_ready <= UART1_OUT_last_ready;
			end if;
			if (active_i = '1') then 
				if (clear_count_i = '1') then 
					count <= x"00000000";
				elsif ((regs(4)(3) = '1') and (regs(4)(1) <= '1') and (timer_i /= x"00000000")) then 
					count <= std_logic_vector(unsigned(count) + 1);
					if (count = timer_i) then 
						count <= x"00000000";
						regs(18) <= regs(0);
						regs(0) <= irq_i;
						pc_we <= '1';
						regs(4)(4) <= '1';
						regs(4)(1) <= '0';
					end if;
				else 
					count <= x"00000000";
				end if;
				if (assert_int = '1') then 
					assert_int <= '0';
					regs(18) <= regs(0);
					regs(0) <= irq_i;
					pc_we <= '1';
				end if;
			end if;
		end if;
	end process;

	process (all)
	begin
		if (rst_i = '1') then
			rdata1_o <= (others=> '0');
		elsif (raddr1_i = REG_ZR_ADDR) then
			rdata1_o <= (others=> '0');
		elsif (raddr1_i = REG_WR_ADDR) then
			rdata1_o <= x"00000004";
		elsif ((raddr1_i = wr_addr_i) and (wr_en_i = '1')) then
			-- write before read
			rdata1_o <= wr_data_i;
		else
			rdata1_o <= regs(to_integer(unsigned(real_r1_addr)));
		end if;
	end process;


	process (all)
	begin
		if (rst_i = '1') then
			rdata2_o <= (others=> '0');
		elsif (raddr2_i = REG_ZR_ADDR) then
			rdata2_o <= (others=> '0');
		elsif (raddr2_i = REG_WR_ADDR) then
			rdata2_o <= x"00000004";
		elsif ((raddr2_i = wr_addr_i) and (wr_en_i = '1')) then
			-- write before read
			rdata2_o <= wr_data_i;
		else
			rdata2_o <= regs(to_integer(unsigned(real_r2_addr)));
		end if;
	end process;
end behave;
