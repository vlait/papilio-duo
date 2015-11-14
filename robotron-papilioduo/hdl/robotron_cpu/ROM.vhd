library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.all;

entity ROMS is
port (
	CLK  : in  std_logic;
	ENA  : in  std_logic;
	ADDR : in  std_logic_vector(15 downto 0);
	DO   : out std_logic_vector( 7 downto 0)
	);
end;

architecture RTL of ROMS is

	signal
		rom0D_d, rom0E_d, rom0F_d, rom10_d, rom11_d, rom12_d, rom13_d, rom14_d, rom15_d, rom16_d, rom17_d, rom18_d
	: std_logic_vector(7 downto 0);

begin

	--	ROM address decoding
	DO <=
		rom0D_d when (ENA = '1') and (ADDR(15 downto 12) = x"D") else -- 0D000
		rom0E_d when (ENA = '1') and (ADDR(15 downto 12) = x"E") else -- 0E000
		rom0F_d when (ENA = '1') and (ADDR(15 downto 12) = x"F") else -- 0F000
		rom10_d when (ENA = '1') and (ADDR(15 downto 12) = x"0") else -- 10000
		rom11_d when (ENA = '1') and (ADDR(15 downto 12) = x"1") else -- 11000
		rom12_d when (ENA = '1') and (ADDR(15 downto 12) = x"2") else -- 12000
		rom13_d when (ENA = '1') and (ADDR(15 downto 12) = x"3") else -- 13000
		rom14_d when (ENA = '1') and (ADDR(15 downto 12) = x"4") else -- 14000
		rom15_d when (ENA = '1') and (ADDR(15 downto 12) = x"5") else -- 15000
		rom16_d when (ENA = '1') and (ADDR(15 downto 12) = x"6") else -- 16000
		rom17_d when (ENA = '1') and (ADDR(15 downto 12) = x"7") else -- 17000
		rom18_d when (ENA = '1') and (ADDR(15 downto 12) = x"8") else -- 18000
		(others=>'0');

	-- ROMs
	inst_rom0D : entity work.CPU_ROM_0D port map ( CLK => CLK, ENA => ENA, ADDR => ADDR(11 downto 0), DATA => rom0D_d );
	inst_rom0E : entity work.CPU_ROM_0E port map ( CLK => CLK, ENA => ENA, ADDR => ADDR(11 downto 0), DATA => rom0E_d );
	inst_rom0F : entity work.CPU_ROM_0F port map ( CLK => CLK, ENA => ENA, ADDR => ADDR(11 downto 0), DATA => rom0F_d );
	inst_rom10 : entity work.CPU_ROM_10 port map ( CLK => CLK, ENA => ENA, ADDR => ADDR(11 downto 0), DATA => rom10_d );
	inst_rom11 : entity work.CPU_ROM_11 port map ( CLK => CLK, ENA => ENA, ADDR => ADDR(11 downto 0), DATA => rom11_d );
	inst_rom12 : entity work.CPU_ROM_12 port map ( CLK => CLK, ENA => ENA, ADDR => ADDR(11 downto 0), DATA => rom12_d );
	inst_rom13 : entity work.CPU_ROM_13 port map ( CLK => CLK, ENA => ENA, ADDR => ADDR(11 downto 0), DATA => rom13_d );
	inst_rom14 : entity work.CPU_ROM_14 port map ( CLK => CLK, ENA => ENA, ADDR => ADDR(11 downto 0), DATA => rom14_d );
	inst_rom15 : entity work.CPU_ROM_15 port map ( CLK => CLK, ENA => ENA, ADDR => ADDR(11 downto 0), DATA => rom15_d );
	inst_rom16 : entity work.CPU_ROM_16 port map ( CLK => CLK, ENA => ENA, ADDR => ADDR(11 downto 0), DATA => rom16_d );
	inst_rom17 : entity work.CPU_ROM_17 port map ( CLK => CLK, ENA => ENA, ADDR => ADDR(11 downto 0), DATA => rom17_d );
	inst_rom18 : entity work.CPU_ROM_18 port map ( CLK => CLK, ENA => ENA, ADDR => ADDR(11 downto 0), DATA => rom18_d );

end RTL;
