library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.consts.ALL;


entity IF_ID is
    port (
		rst_i: in std_logic; 
		clk_i: in std_logic;
		halt_i: in std_logic;

		active_i: in std_logic;
		active_o: out std_logic;

		pc_i: in mem_addr_t;
		inst_i: in inst_t;

		pc_o: out mem_addr_t;
		inst_o: out inst_t
    );
end IF_ID;


architecture BehavIFID of IF_ID is
begin

	process (clk_i)
	begin
		if (rising_edge(clk_i)) then
			if (halt_i = '0') then
				pc_o <= pc_i;
				inst_o <= INST_NOP;
				active_o <= '0';

				if (rst_i = '1') then
					null;
				elsif (active_i = '1') then
					inst_o <= inst_i;
					active_o <= '1';
				end if;
			end if;
		end if;
	end process;

end BehavIFID;
