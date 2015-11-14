-----------------------------------------------------------------------
--
-- Copyright 2009-2013 ShareBrained Technology, Inc.
--
-- This file is part of robotron-fpga.
--
-- robotron-fpga is free software: you can redistribute
-- it and/or modify it under the terms of the GNU General
-- Public License as published by the Free Software
-- Foundation, either version 3 of the License, or (at your
-- option) any later version.
--
-- robotron-fpga is distributed in the hope that it will
-- be useful, but WITHOUT ANY WARRANTY; without even the
-- implied warranty of MERCHANTABILITY or FITNESS FOR A
-- PARTICULAR PURPOSE. See the GNU General Public License
-- for more details.
--
-- You should have received a copy of the GNU General
-- Public License along with robotron-fpga. If not, see
-- <http://www.gnu.org/licenses/>.
--
-----------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
library UNISIM;
	use UNISIM.Vcomponents.all;

entity robotron_sound is
port(
	clk_cpu     : in     std_logic;
	reset       : in     std_logic;
	diagnostic  : in     std_logic;
	pb          : in     std_logic_vector (5 downto 0);
	hand        : in     std_logic;
	dac         : out    std_logic_vector (7 downto 0);
	--
	-- bootstrap signals
	--
	bs_done     : in     std_logic;
	bs_SNDROM_w : in     std_logic;
	bs_SNDROM_a : in     std_logic_vector(17 downto 0);
	bs_SNDROM_d : in     std_logic_vector(7 downto 0)
	
);
end robotron_sound;

architecture Behavioral of robotron_sound is
	signal CPU_ADDRESS_OUT   : std_logic_vector (15 downto 0);
	signal ROM_ADDRESS       : std_logic_vector (11 downto 0);
	signal CPU_DATA_IN       : std_logic_vector ( 7 downto 0);
	signal CPU_DATA_OUT      : std_logic_vector ( 7 downto 0);
	signal CPU_RW            : std_logic;
	signal CPU_IRQ           : std_logic;
	signal CPU_VMA           : std_logic;

	signal ROM_CS            : std_logic;
	signal ROM_DATA_OUT      : std_logic_vector ( 7 downto 0);

	signal RAM_CS            : std_logic;
	signal RAM_RW            : std_logic;
	signal RAM_DATA_IN       : std_logic_vector ( 7 downto 0);
	signal RAM_DATA_OUT      : std_logic_vector ( 7 downto 0);

	signal PIA_RW            : std_logic;
	signal PIA_CS            : std_logic;
	signal PIA_IRQA          : std_logic;
	signal PIA_IRQB          : std_logic;
	signal PIA_DATA_IN       : std_logic_vector ( 7 downto 0);
	signal PIA_DATA_OUT      : std_logic_vector ( 7 downto 0);
	signal PIA_CB1           : std_logic;
	signal PIA_CA2_I         : std_logic;
	signal PIA_CB2_I         : std_logic;
	signal PIA_PA_O          : std_logic_vector ( 7 downto 0);
	signal PIA_PB_I          : std_logic_vector ( 7 downto 0);

	signal BCD_DEMUX_INPUT   : std_logic_vector ( 3 downto 0);
	signal BCD_DEMUX_OUTPUT  : std_logic_vector ( 9 downto 0);

	signal SPEECH_CLOCK      : std_logic;
	signal SPEECH_DATA       : std_logic;

begin

	SPEECH_CLOCK <= '0';
	SPEECH_DATA  <= '0';

	CPU : entity work.cpu68
	port map (
		clk      => clk_cpu,
		data_in  => CPU_DATA_IN,
		halt     => '0',        -- active high
		hold     => '0',        -- active high
		irq      => CPU_IRQ,
		nmi      => diagnostic, -- active high
		rst      => reset,      -- active high
		address  => CPU_ADDRESS_OUT,
		data_out => CPU_DATA_OUT,
		rw       => CPU_RW,
		test_alu => open,
		test_cc  => open,
		vma      => CPU_VMA
	);

	ROM_ADDRESS <= CPU_ADDRESS_OUT(11 downto 0) when bs_done='1' else bs_SNDROM_a(11 downto 0);
	
	ROM : entity work.SND_ROM_0F port map ( 
	   ADDR => ROM_ADDRESS (11 downto 0),
		CLK => clk_cpu,
		DI => bs_SNDROM_d,
		DO => ROM_DATA_OUT,
		ENA => ROM_CS,
		WE => bs_SNDROM_w );
		
	--ROM : entity work.SND_ROM_0F
	--port map (
	--	addr     => CPU_ADDRESS_OUT(11 downto 0),
	--	clk      => clk_cpu,
	--	ena      => ROM_CS,
	--	data     => ROM_DATA_OUT
	--);

	RAM : entity work.m6810
	port map (
		clk      => clk_cpu,
--		rst      => reset,
		address  => CPU_ADDRESS_OUT(6 downto 0),
		cs       => RAM_CS,
		rw       => RAM_RW,
		data_in  => RAM_DATA_IN,
		data_out => RAM_DATA_OUT
	);

	PIA : entity work.pia6821
	port map (
		addr     => CPU_ADDRESS_OUT(1 downto 0),
		ca1      => '1',
		cb1      => PIA_CB1,
		clk      => clk_cpu,
		cs       => PIA_CS,
		data_in  => PIA_DATA_IN,
		rst      => reset,
		rw       => PIA_RW,
		data_out => PIA_DATA_OUT,
		irqa     => PIA_IRQA,
		irqb     => PIA_IRQB,
		ca2_i    => PIA_CA2_I,
		ca2_o    => open,
		cb2_i    => PIA_CB2_I,
		cb2_o    => open,
		pa_i     => x"00",
		pa_o     => PIA_PA_O,
		pb_i     => PIA_PB_I,
		pb_o     => open
	);

	BCD_DEMUX_INPUT <= (not CPU_ADDRESS_OUT(15)) & CPU_ADDRESS_OUT(14 downto 12);

	-- address decoder
	logic7442 : process(BCD_DEMUX_INPUT)
	begin
		case BCD_DEMUX_INPUT is
			when "0000" => BCD_DEMUX_OUTPUT <= "1111111110";
			when "0001" => BCD_DEMUX_OUTPUT <= "1111111101";
			when "0010" => BCD_DEMUX_OUTPUT <= "1111111011";
			when "0011" => BCD_DEMUX_OUTPUT <= "1111110111";
			when "0100" => BCD_DEMUX_OUTPUT <= "1111101111";
			when "0101" => BCD_DEMUX_OUTPUT <= "1111011111";
			when "0110" => BCD_DEMUX_OUTPUT <= "1110111111";
			when "0111" => BCD_DEMUX_OUTPUT <= "1101111111";
			when "1000" => BCD_DEMUX_OUTPUT <= "1011111111";
			when "1001" => BCD_DEMUX_OUTPUT <= "0111111111";
			when others => BCD_DEMUX_OUTPUT <= "1111111111";
		end case;
	end process;

	CPU_IRQ <= PIA_IRQA or PIA_IRQB;

	ROM_CS  <=  '1' when (((BCD_DEMUX_OUTPUT(7) = '0' )  and CPU_VMA = '1'  ) or (  bs_done ='0'  and bs_SNDROM_W ='1' )) else '0';

	RAM_CS  <= CPU_VMA and
		(not CPU_ADDRESS_OUT( 8)) and
		(not CPU_ADDRESS_OUT( 9)) and
		(not CPU_ADDRESS_OUT(10)) and
		(not CPU_ADDRESS_OUT(11)) and
		(not BCD_DEMUX_OUTPUT(8)) ;
	RAM_RW      <= CPU_RW;
	RAM_DATA_IN <= CPU_DATA_OUT;

	PIA_CA2_I   <= SPEECH_DATA;
	PIA_CB1     <= not (HAND and pb(5) and pb(4) and pb(3) and pb(2) and pb(1) and pb(0));
	PIA_CB2_I   <= SPEECH_CLOCK;
	PIA_CS      <= (not (BCD_DEMUX_OUTPUT(0) and BCD_DEMUX_OUTPUT(8))) and CPU_ADDRESS_OUT(10) and CPU_VMA;
	PIA_DATA_IN <= CPU_DATA_OUT;
	PIA_RW      <= CPU_RW;
	PIA_PB_I    <= "00" & pb(5 downto 0);
	dac         <= PIA_PA_O;

	process (PIA_CS, PIA_DATA_OUT, RAM_CS, RAM_DATA_OUT, ROM_DATA_OUT)
	begin
		if (PIA_CS = '1') then
			CPU_DATA_IN <= PIA_DATA_OUT;
		elsif (RAM_CS = '1') then
			CPU_DATA_IN <= RAM_DATA_OUT;
		else
			CPU_DATA_IN <= ROM_DATA_OUT;
		end if;
	end process;

end Behavioral;
