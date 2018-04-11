library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.consts.ALL;
use IEEE.NUMERIC_STD.ALL;


entity IFF is
    port (
		clk_i: in std_logic;
		rst_i: in std_logic;

		active_o: out std_logic;

		advance_i: in std_logic;

		jb_pc_i: in mem_addr_t; -- jump/branch
		jb_en_i: in std_logic;

		pc_o: out mem_addr_t
	);
end IFF;

architecture behave of IFF is
	signal pc: std_logic_vector(31 downto 0);
begin
	pc_o <= pc;

	process (clk_i)
	begin
		if (rising_edge(clk_i)) then
			pc <= (others=> '0');
			active_o <= '0';

			if (rst_i = '1') then
				pc <= BOOT_PC;
				active_o <= '1';
            elsif (advance_i = '1') then
				if (jb_en_i = '1') then
					pc <= jb_pc_i;
				else
					pc <= std_logic_vector(unsigned(pc) + 4);
				end if;
				active_o <= '1';
			end if;
		end if;
	end process;

end behave;
