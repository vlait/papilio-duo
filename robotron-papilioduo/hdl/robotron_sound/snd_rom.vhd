library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.all;

library UNISIM;
	use UNISIM.Vcomponents.all;

entity SND_ROM_0F is
port (
	CLK  : in  std_logic;
	ENA  : in  std_logic;
	WE   : in  std_logic;
	ADDR : in  std_logic_vector(11 downto 0);
	DI   : in  std_logic_vector( 7 downto 0);
	DO   : out std_logic_vector( 7 downto 0)
	);
end;

architecture RTL of SND_ROM_0F is
	signal
		RAM0H_en, RAM0L_en
	: std_logic := '0';

	signal
		RAM0H_d, RAM0L_d
	: std_logic_vector(3 downto 0);

begin
	RAM0L_en <= '1' when (ENA = '1') else '0';

	RAM0H_en <= '1' when (ENA = '1') else '0';

	DO(7 downto 4) <=
		RAM0H_d when RAM0H_en = '1' else 
		x"0";

	DO(3 downto 0) <=
		RAM0L_d when RAM0H_en = '1' else 
		x"0";

	inst_RAM0L : RAMB16_S4 port map ( ADDR => ADDR(11 downto 0), CLK => CLK, DI => DI(3 downto 0), DO => RAM0L_d, EN => RAM0L_en, SSR => '0', WE => WE );

	inst_RAM0H : RAMB16_S4 port map ( ADDR => ADDR(11 downto 0), CLK => CLK, DI => DI(7 downto 4), DO => RAM0H_d, EN => RAM0H_en, SSR => '0', WE => WE );

end RTL;
