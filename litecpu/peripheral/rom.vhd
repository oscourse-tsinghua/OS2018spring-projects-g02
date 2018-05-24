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
	constant MEMSZ_DW: integer := 124;

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
mem(1) <= x"04";
mem(2) <= x"28";
mem(3) <= x"68";
mem(4) <= x"30";
mem(5) <= x"00";
mem(6) <= x"30";
mem(7) <= x"68";
mem(8) <= x"10";
mem(9) <= x"00";
mem(10) <= x"1c";
mem(11) <= x"68";
mem(12) <= x"00";
mem(13) <= x"0e";
mem(14) <= x"30";
mem(15) <= x"50";
mem(16) <= x"07";
mem(17) <= x"18";
mem(18) <= x"34";
mem(19) <= x"00";
mem(20) <= x"03";
mem(21) <= x"06";
mem(22) <= x"24";
mem(23) <= x"00";
mem(24) <= x"FF";
mem(25) <= x"FF";
mem(26) <= x"44";
mem(27) <= x"68";
mem(28) <= x"00";
mem(29) <= x"0e";
mem(30) <= x"44";
mem(31) <= x"50";
mem(32) <= x"FF";
mem(33) <= x"FB";
mem(34) <= x"48";
mem(35) <= x"68";
mem(36) <= x"11";
mem(37) <= x"24";
mem(38) <= x"48";
mem(39) <= x"00";
mem(40) <= x"03";
mem(41) <= x"06";
mem(42) <= x"2c";
mem(43) <= x"00";
mem(44) <= x"00";
mem(45) <= x"00";
mem(46) <= x"20";
mem(47) <= x"68";
mem(48) <= x"04";
mem(49) <= x"14";
mem(50) <= x"18";
mem(51) <= x"20";
mem(52) <= x"fe";
mem(53) <= x"07";
mem(54) <= x"18";
mem(55) <= x"58";
mem(56) <= x"00";
mem(57) <= x"1a";
mem(58) <= x"38";
mem(59) <= x"38";
mem(60) <= x"12";
mem(61) <= x"08";
mem(62) <= x"10";
mem(63) <= x"20";
mem(64) <= x"00";
mem(65) <= x"0a";
mem(66) <= x"2c";
mem(67) <= x"50";
mem(68) <= x"00";
mem(69) <= x"0a";
mem(70) <= x"2c";
mem(71) <= x"50";
mem(72) <= x"0e";
mem(73) <= x"16";
mem(74) <= x"2c";
mem(75) <= x"00";
mem(76) <= x"05";
mem(77) <= x"10";
mem(78) <= x"20";
mem(79) <= x"00";
mem(80) <= x"f7";
mem(81) <= x"0f";
mem(82) <= x"20";
mem(83) <= x"60";
mem(84) <= x"03";
mem(85) <= x"18";
mem(86) <= x"2c";
mem(87) <= x"58";
mem(88) <= x"00";
mem(89) <= x"16";
mem(90) <= x"24";
mem(91) <= x"40";
mem(92) <= x"05";
mem(93) <= x"12";
mem(94) <= x"24";
mem(95) <= x"00";
mem(96) <= x"f1";
mem(97) <= x"07";
mem(98) <= x"0c";
mem(99) <= x"58";
mem(100) <= x"00";
mem(101) <= x"00";
mem(102) <= x"00";
mem(103) <= x"68";


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
				rdata_o <= (others=> '0');
		end case;
	end process;

end bhv;

