library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.consts.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use STD.TEXTIO.ALL;
use IEEE.NUMERIC_STD.ALL;


entity RAM_TB is
	port (
		clk_i: in std_logic;
		rst_i: in std_logic;

		mode_i: in rammode_t;
		addr_i: in mem_addr_t;
		rdata_o: out dword;
		wdata_i: in dword;
		
		MEMMode_i: in rammode_t;
		MEMAddr_i: in mem_addr_t;
		MEMRData_o: out dword
	);
end RAM_TB;

architecture behave of RAM_TB is
	constant infile: string := "/home/hob/Desktop/raminfile";
	constant MEMSZ_DW: integer := 1024;

	type t_mem is array(0 to MEMSZ_DW-1) of byte;
	signal mem: t_mem;

	signal has_been_initialized: std_logic := '0';

begin

	-- write (happens on clk_i rising edges) (*** not a practical assump. ***)
	-- do not consider forwarding.
	-- because for the 5 insts. in pipeline,
	-- at most one of them is accessing the memory
	process (rst_i, clk_i)
		file InputFile: text;
		variable Iline: line;
		variable i : integer := 0;
		variable tmp: std_logic_vector(31 downto 0);
		variable ad0: integer;
	begin
		if (rst_i = '1') then
			if (has_been_initialized = '0') then
				i := 0;
				file_open(InputFile, infile, read_mode);
				while not endfile(InputFile) loop
					report "BAD!!!";
					if (i mod 1000 = 0) then
						report "init ram, at byte " & integer'image(i);
					end if;
					readline(InputFile, Iline);
					hread(Iline, tmp); -- Hexadecimal
					mem(i)     <= tmp(7 downto 0);
					mem(i + 1) <= tmp(15 downto 8);
					mem(i + 2) <= tmp(23 downto 16);
					mem(i + 3) <= tmp(31 downto 24);
					i := i + 4;
				end loop;
				has_been_initialized <= '1';
			end if;
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
	
	-- read for MEM
	process (all)
		variable ad1: integer;
	begin
		ad1 := to_integer(unsigned(MEMAddr_i));
		case MEMMode_i is
			when RAM_READ =>
				MEMRData_o <= mem(ad1 + 3)
						 & mem(ad1 + 2)
						 & mem(ad1 + 1)
						 & mem(ad1);
			when others=>
				MEMRData_o <= (others=> 'Z');
		end case;
	end process;

end behave;

