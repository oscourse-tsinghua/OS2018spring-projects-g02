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
		
		-- Deal with interrupts or exceptions --
		halt_o: out std_logic;
		
		display_reg_o: out dword
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

begin
	real_wr_addr <= wr_addr_i(4 downto 0);
	real_r1_addr <= raddr1_i(4 downto 0);
	real_r2_addr <= raddr2_i(4 downto 0);
	halt_o <= regs(4)(0);
	display_reg_o <= regs(7);

	-- writing to ZR and WR will have no effect as their reads are
	--	hardcoded
	process (clk_i)
	begin
		if (rising_edge(clk_i)) then
			if (rst_i = '0') then
				if (wr_en_i = '1') then
					regs(to_integer(unsigned(real_wr_addr))) <= wr_data_i;
				end if;
			else 
				regs(4) <= x"00000200";
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
