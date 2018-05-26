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
	constant MEMSZ_DW: integer := 180;

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
mem(2) <= x"43";
mem(3) <= x"35";
mem(4) <= x"30";
mem(5) <= x"00";
mem(6) <= x"83";
mem(7) <= x"35";
mem(8) <= x"10";
mem(9) <= x"00";
mem(10) <= x"e3";
mem(11) <= x"34";
mem(12) <= x"00";
mem(13) <= x"38";
mem(14) <= x"8c";
mem(15) <= x"29";
mem(16) <= x"00";
mem(17) <= x"38";
mem(18) <= x"ac";
mem(19) <= x"01";
mem(20) <= x"00";
mem(21) <= x"18";
mem(22) <= x"23";
mem(23) <= x"01";
mem(24) <= x"FF";
mem(25) <= x"FF";
mem(26) <= x"23";
mem(27) <= x"36";
mem(28) <= x"00";
mem(29) <= x"38";
mem(30) <= x"31";
mem(31) <= x"2a";
mem(32) <= x"FF";
mem(33) <= x"FB";
mem(34) <= x"43";
mem(35) <= x"36";
mem(36) <= x"00";
mem(37) <= x"88";
mem(38) <= x"52";
mem(39) <= x"02";
mem(40) <= x"00";
mem(41) <= x"18";
mem(42) <= x"63";
mem(43) <= x"01";
mem(44) <= x"00";
mem(45) <= x"00";
mem(46) <= x"03";
mem(47) <= x"35";
mem(48) <= x"00";
mem(49) <= x"20";
mem(50) <= x"ca";
mem(51) <= x"10";
mem(52) <= x"f8";
mem(53) <= x"ff";
mem(54) <= x"c3";
mem(55) <= x"2c";
mem(56) <= x"00";
mem(57) <= x"00";
mem(58) <= x"cd";
mem(59) <= x"1d";
mem(60) <= x"00";
mem(61) <= x"90";
mem(62) <= x"84";
mem(63) <= x"10";
mem(64) <= x"00";
mem(65) <= x"28";
mem(66) <= x"6b";
mem(67) <= x"29";
mem(68) <= x"00";
mem(69) <= x"28";
mem(70) <= x"6b";
mem(71) <= x"29";
mem(72) <= x"00";
mem(73) <= x"70";
mem(74) <= x"6b";
mem(75) <= x"01";
mem(76) <= x"00";
mem(77) <= x"28";
mem(78) <= x"08";
mem(79) <= x"01";
mem(80) <= x"dc";
mem(81) <= x"ff";
mem(82) <= x"07";
mem(83) <= x"31";
mem(84) <= x"10";
mem(85) <= x"00";
mem(86) <= x"6c";
mem(87) <= x"2d";
mem(88) <= x"00";
mem(89) <= x"00";
mem(90) <= x"69";
mem(91) <= x"21";
mem(92) <= x"00";
mem(93) <= x"00";
mem(94) <= x"69";
mem(95) <= x"21";
mem(96) <= x"00";
mem(97) <= x"28";
mem(98) <= x"29";
mem(99) <= x"01";
mem(100) <= x"c0";
mem(101) <= x"ff";
mem(102) <= x"63";
mem(103) <= x"2c";
mem(104) <= x"00";
mem(105) <= x"02";
mem(106) <= x"83";
mem(107) <= x"34";
mem(108) <= x"00";
mem(109) <= x"00";
mem(110) <= x"03";
mem(111) <= x"34";

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

