library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.consts.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use STD.TEXTIO.ALL;
use IEEE.NUMERIC_STD.ALL;


entity ROM is
	port (
		clk_i: in std_logic;
		rst_i: in std_logic;

		mode_i: in rammode_t;
		addr_i: in mem_addr_t;
		rdata_o: out dword;
		wdata_i: in dword
	);
end ROM;

architecture bhv of ROM is
	constant MEMSZ_DW: integer := 64;

	type t_mem is array(0 to MEMSZ_DW-1) of byte;
	signal mem: t_mem;

	signal has_been_initialized: std_logic := '0';

begin
	-- write (happens on clk_i rising edges) (*** not a practical assump. ***)
	-- do not consider forwarding.
	-- because for the 5 insts. in pipeline,
	-- at most one of them is accessing the memory
	process (rst_i, clk_i)
		variable i : integer := 0;
		variable tmp: std_logic_vector(31 downto 0);
		variable ad0: integer;
		variable ad1: integer;
	begin
		if (rst_i = '1') then
			mem(0) <= x"00";	
			mem(1) <= x"02";
			mem(2) <= x"18";
			mem(3) <= x"68";
			mem(4) <= x"10";
			mem(5) <= x"00";
			mem(6) <= x"20";
			mem(7) <= x"68";
			mem(8) <= x"00";
			mem(9) <= x"0c";
			mem(10) <= x"20";
			mem(11) <= x"40";
			mem(12) <= x"00";
			mem(13) <= x"10";
			mem(14) <= x"1c";
			mem(15) <= x"38";
			mem(16) <= x"01";
			mem(17) <= x"00";
			mem(18) <= x"18";
			mem(19) <= x"68";
			mem(20) <= x"06";
			mem(21) <= x"08";
			mem(22) <= x"10";
			mem(23) <= x"28";

		elsif (rising_edge(clk_i)) then
			ad0 := to_integer(unsigned(addr_i));
			case mode_i is
				when RAM_WRITE =>
					mem(ad0 + 3) <= wdata_i(31 downto 24);
					mem(ad0 + 2) <= wdata_i(23 downto 16);
					mem(ad0 + 1) <= wdata_i(15 downto 8);
					mem(ad0) <= wdata_i(7 downto 0);
				when others =>
					null;
			end case;
		end if;
	end process;


	-- read is combinational logic
	process (all)
		variable ad0: integer;
	begin
		ad0 := to_integer(unsigned(addr_i));
		case mode_i is
			when RAM_READ =>
				rdata_o <= mem(ad0 + 3)
						 & mem(ad0 + 2)
						 & mem(ad0 + 1)
						 & mem(ad0);
			when others=>
				rdata_o <= (others=> 'Z');
		end case;
	end process;

end bhv;

