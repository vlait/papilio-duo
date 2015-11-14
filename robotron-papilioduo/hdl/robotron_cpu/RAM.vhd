library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.all;

library UNISIM;
	use UNISIM.Vcomponents.all;

entity RAMS is
port (
	CLK  : in  std_logic;
	ENL  : in  std_logic;
	ENH  : in  std_logic;
	WE   : in  std_logic;
	ADDR : in  std_logic_vector(15 downto 0);
	DI   : in  std_logic_vector( 7 downto 0);
	DO   : out std_logic_vector( 7 downto 0)
	);
end;

architecture RTL of RAMS is
	signal
		RAM0H_en, RAM0L_en, RAM1H_en, RAM1L_en, RAM2H_en, RAM2L_en, RAM3H_en, RAM3L_en,
		RAM4H_en, RAM4L_en, RAM5H_en, RAM5L_en, RAM6H_en, RAM6L_en, RAM7H_en, RAM7L_en, 
		RAM8H_en, RAM8L_en, RAM9H_en, RAM9L_en, RAMAH_en, RAMAL_en, RAMBH_en, RAMBL_en,
		RAMCH_en, RAMCL_en
	: std_logic := '0';

	signal
		RAM0H_d, RAM0L_d, RAM1H_d, RAM1L_d, RAM2H_d, RAM2L_d, RAM3H_d, RAM3L_d,
		RAM4H_d, RAM4L_d, RAM5H_d, RAM5L_d, RAM6H_d, RAM6L_d, RAM7H_d, RAM7L_d,
		RAM8H_d, RAM8L_d, RAM9H_d, RAM9L_d, RAMAH_d, RAMAL_d, RAMBH_d, RAMBL_d,
		RAMCH_d, RAMCL_d
	: std_logic_vector(3 downto 0);

begin
	RAM0L_en <= '1' when (ADDR(15 downto 12) = x"0") and (ENL = '1') else '0';
	RAM1L_en <= '1' when (ADDR(15 downto 12) = x"1") and (ENL = '1') else '0';
	RAM2L_en <= '1' when (ADDR(15 downto 12) = x"2") and (ENL = '1') else '0';
	RAM3L_en <= '1' when (ADDR(15 downto 12) = x"3") and (ENL = '1') else '0';
	RAM4L_en <= '1' when (ADDR(15 downto 12) = x"4") and (ENL = '1') else '0';
	RAM5L_en <= '1' when (ADDR(15 downto 12) = x"5") and (ENL = '1') else '0';
	RAM6L_en <= '1' when (ADDR(15 downto 12) = x"6") and (ENL = '1') else '0';
	RAM7L_en <= '1' when (ADDR(15 downto 12) = x"7") and (ENL = '1') else '0';
	RAM8L_en <= '1' when (ADDR(15 downto 12) = x"8") and (ENL = '1') else '0';
	RAM9L_en <= '1' when (ADDR(15 downto 12) = x"9") and (ENL = '1') else '0';
	RAMAL_en <= '1' when (ADDR(15 downto 12) = x"A") and (ENL = '1') else '0';
	RAMBL_en <= '1' when (ADDR(15 downto 12) = x"B") and (ENL = '1') else '0';
	RAMCL_en <= '1' when (ADDR(15 downto 12) = x"C") and (ENL = '1') else '0';

	RAM0H_en <= '1' when (ADDR(15 downto 12) = x"0") and (ENH = '1') else '0';
	RAM1H_en <= '1' when (ADDR(15 downto 12) = x"1") and (ENH = '1') else '0';
	RAM2H_en <= '1' when (ADDR(15 downto 12) = x"2") and (ENH = '1') else '0';
	RAM3H_en <= '1' when (ADDR(15 downto 12) = x"3") and (ENH = '1') else '0';
	RAM4H_en <= '1' when (ADDR(15 downto 12) = x"4") and (ENH = '1') else '0';
	RAM5H_en <= '1' when (ADDR(15 downto 12) = x"5") and (ENH = '1') else '0';
	RAM6H_en <= '1' when (ADDR(15 downto 12) = x"6") and (ENH = '1') else '0';
	RAM7H_en <= '1' when (ADDR(15 downto 12) = x"7") and (ENH = '1') else '0';
	RAM8H_en <= '1' when (ADDR(15 downto 12) = x"8") and (ENH = '1') else '0';
	RAM9H_en <= '1' when (ADDR(15 downto 12) = x"9") and (ENH = '1') else '0';
	RAMAH_en <= '1' when (ADDR(15 downto 12) = x"A") and (ENH = '1') else '0';
	RAMBH_en <= '1' when (ADDR(15 downto 12) = x"B") and (ENH = '1') else '0';
	RAMCH_en <= '1' when (ADDR(15 downto 12) = x"C") and (ENH = '1') else '0';

	DO(7 downto 4) <=
		RAM0H_d when RAM0H_en = '1' else 
		RAM1H_d when RAM1H_en = '1' else 
		RAM2H_d when RAM2H_en = '1' else 
		RAM3H_d when RAM3H_en = '1' else 
		RAM4H_d when RAM4H_en = '1' else 
		RAM5H_d when RAM5H_en = '1' else 
		RAM6H_d when RAM6H_en = '1' else 
		RAM7H_d when RAM7H_en = '1' else 
		RAM8H_d when RAM8H_en = '1' else 
		RAM9H_d when RAM9H_en = '1' else 
		RAMAH_d when RAMAH_en = '1' else 
		RAMBH_d when RAMBH_en = '1' else
		RAMCH_d when RAMCH_en = '1' else
		x"0";

	DO(3 downto 0) <=
		RAM0L_d when RAM0H_en = '1' else 
		RAM1L_d when RAM1H_en = '1' else 
		RAM2L_d when RAM2H_en = '1' else 
		RAM3L_d when RAM3H_en = '1' else 
		RAM4L_d when RAM4H_en = '1' else 
		RAM5L_d when RAM5H_en = '1' else 
		RAM6L_d when RAM6H_en = '1' else 
		RAM7L_d when RAM7H_en = '1' else 
		RAM8L_d when RAM8H_en = '1' else 
		RAM9L_d when RAM9H_en = '1' else 
		RAMAL_d when RAMAH_en = '1' else 
		RAMBL_d when RAMBH_en = '1' else
		RAMCL_d when RAMCH_en = '1' else
		x"0";

	inst_RAM0L : RAMB16_S4 port map ( ADDR => ADDR(11 downto 0), CLK => CLK, DI => DI(3 downto 0), DO => RAM0L_d, EN => RAM0L_en, SSR => '0', WE => WE );
	inst_RAM1L : RAMB16_S4 port map ( ADDR => ADDR(11 downto 0), CLK => CLK, DI => DI(3 downto 0), DO => RAM1L_d, EN => RAM1L_en, SSR => '0', WE => WE );
	inst_RAM2L : RAMB16_S4 port map ( ADDR => ADDR(11 downto 0), CLK => CLK, DI => DI(3 downto 0), DO => RAM2L_d, EN => RAM2L_en, SSR => '0', WE => WE );
	inst_RAM3L : RAMB16_S4 port map ( ADDR => ADDR(11 downto 0), CLK => CLK, DI => DI(3 downto 0), DO => RAM3L_d, EN => RAM3L_en, SSR => '0', WE => WE );
	inst_RAM4L : RAMB16_S4 port map ( ADDR => ADDR(11 downto 0), CLK => CLK, DI => DI(3 downto 0), DO => RAM4L_d, EN => RAM4L_en, SSR => '0', WE => WE );
	inst_RAM5L : RAMB16_S4 port map ( ADDR => ADDR(11 downto 0), CLK => CLK, DI => DI(3 downto 0), DO => RAM5L_d, EN => RAM5L_en, SSR => '0', WE => WE );
	inst_RAM6L : RAMB16_S4 port map ( ADDR => ADDR(11 downto 0), CLK => CLK, DI => DI(3 downto 0), DO => RAM6L_d, EN => RAM6L_en, SSR => '0', WE => WE );
	inst_RAM7L : RAMB16_S4 port map ( ADDR => ADDR(11 downto 0), CLK => CLK, DI => DI(3 downto 0), DO => RAM7L_d, EN => RAM7L_en, SSR => '0', WE => WE );
	inst_RAM8L : RAMB16_S4 port map ( ADDR => ADDR(11 downto 0), CLK => CLK, DI => DI(3 downto 0), DO => RAM8L_d, EN => RAM8L_en, SSR => '0', WE => WE );
	inst_RAM9L : RAMB16_S4 port map ( ADDR => ADDR(11 downto 0), CLK => CLK, DI => DI(3 downto 0), DO => RAM9L_d, EN => RAM9L_en, SSR => '0', WE => WE );
	inst_RAMAL : RAMB16_S4 port map ( ADDR => ADDR(11 downto 0), CLK => CLK, DI => DI(3 downto 0), DO => RAMAL_d, EN => RAMAL_en, SSR => '0', WE => WE );
	inst_RAMBL : RAMB16_S4 port map ( ADDR => ADDR(11 downto 0), CLK => CLK, DI => DI(3 downto 0), DO => RAMBL_d, EN => RAMBL_en, SSR => '0', WE => WE );
	-- CMOS RAM low nibble
	inst_RAMCL : RAMB16_S4 port map ( ADDR => ADDR(11 downto 0), CLK => CLK, DI => DI(3 downto 0), DO => RAMCL_d, EN => RAMCL_en, SSR => '0', WE => WE );

	inst_RAM0H : RAMB16_S4 port map ( ADDR => ADDR(11 downto 0), CLK => CLK, DI => DI(7 downto 4), DO => RAM0H_d, EN => RAM0H_en, SSR => '0', WE => WE );
	inst_RAM1H : RAMB16_S4 port map ( ADDR => ADDR(11 downto 0), CLK => CLK, DI => DI(7 downto 4), DO => RAM1H_d, EN => RAM1H_en, SSR => '0', WE => WE );
	inst_RAM2H : RAMB16_S4 port map ( ADDR => ADDR(11 downto 0), CLK => CLK, DI => DI(7 downto 4), DO => RAM2H_d, EN => RAM2H_en, SSR => '0', WE => WE );
	inst_RAM3H : RAMB16_S4 port map ( ADDR => ADDR(11 downto 0), CLK => CLK, DI => DI(7 downto 4), DO => RAM3H_d, EN => RAM3H_en, SSR => '0', WE => WE );
	inst_RAM4H : RAMB16_S4 port map ( ADDR => ADDR(11 downto 0), CLK => CLK, DI => DI(7 downto 4), DO => RAM4H_d, EN => RAM4H_en, SSR => '0', WE => WE );
	inst_RAM5H : RAMB16_S4 port map ( ADDR => ADDR(11 downto 0), CLK => CLK, DI => DI(7 downto 4), DO => RAM5H_d, EN => RAM5H_en, SSR => '0', WE => WE );
	inst_RAM6H : RAMB16_S4 port map ( ADDR => ADDR(11 downto 0), CLK => CLK, DI => DI(7 downto 4), DO => RAM6H_d, EN => RAM6H_en, SSR => '0', WE => WE );
	inst_RAM7H : RAMB16_S4 port map ( ADDR => ADDR(11 downto 0), CLK => CLK, DI => DI(7 downto 4), DO => RAM7H_d, EN => RAM7H_en, SSR => '0', WE => WE );
	inst_RAM8H : RAMB16_S4 port map ( ADDR => ADDR(11 downto 0), CLK => CLK, DI => DI(7 downto 4), DO => RAM8H_d, EN => RAM8H_en, SSR => '0', WE => WE );
	inst_RAM9H : RAMB16_S4 port map ( ADDR => ADDR(11 downto 0), CLK => CLK, DI => DI(7 downto 4), DO => RAM9H_d, EN => RAM9H_en, SSR => '0', WE => WE );
	inst_RAMAH : RAMB16_S4 port map ( ADDR => ADDR(11 downto 0), CLK => CLK, DI => DI(7 downto 4), DO => RAMAH_d, EN => RAMAH_en, SSR => '0', WE => WE );
	inst_RAMBH : RAMB16_S4 port map ( ADDR => ADDR(11 downto 0), CLK => CLK, DI => DI(7 downto 4), DO => RAMBH_d, EN => RAMBH_en, SSR => '0', WE => WE );
	-- CMOS RAM high nibble
	inst_RAMCH : RAMB16_S4 port map ( ADDR => ADDR(11 downto 0), CLK => CLK, DI => DI(7 downto 4), DO => RAMCH_d, EN => RAMCH_en, SSR => '0', WE => WE );

end RTL;
