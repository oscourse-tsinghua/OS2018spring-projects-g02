library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.consts.ALL;


entity MEM is
    port ( 
		fatal_o: out std_logic;
		active_i: in std_logic;

		alu_data_i: in dword;

		regwr_addr_i: in reg_addr_t;
		regwr_addr_o: out reg_addr_t;
		regwr_en_i: in std_logic;
		regwr_en_o: out std_logic;

		regwr_data_o: out dword;
		
		ram_mode_i: in rammode_t;
		ramRData_i: in dword
	);
end MEM;


architecture behave of MEM is
begin

	-- TODO: pass-on signals like these could be ignored.
	-- But I'm not sure whether this would reduce resource usage.
	regwr_addr_o <= regwr_addr_i;
	regwr_en_o <= regwr_en_i;


	process (all)
	begin
		-- watchout for active_i here!
		fatal_o <= '0';

		if (ram_mode_i = RAM_READ) then
			regwr_data_o <= ramRData_i;
		else
			regwr_data_o <= alu_data_i;
		end if;
	end process;

end behave;
