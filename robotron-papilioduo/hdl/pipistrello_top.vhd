--	(c) 2012 d18c7db(a)hotmail
--
--	This program is free software; you can redistribute it and/or modify it under
--	the terms of the GNU General Public License version 3 or, at your option,
--	any later version as published by the Free Software Foundation.
--
--	This program is distributed in the hope that it will be useful,
--	but WITHOUT ANY WARRANTY; without even the implied warranty of
--	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
--
-- For full details, see the GNU General Public License at www.gnu.org/licenses

--------------------------------------------------------------------------------
--	Top level for Williams hardware arcade targeted for Pipistrello board, basic h/w specs:
--		Spartan 6 LX45 116 BRAMs (232KB)
--		50Mhz xtal oscillator
--		32Mx16 LPDDR 200MHz (not used here)
--		128Mbit SPI Flash

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_arith.all;
	use ieee.std_logic_unsigned.all;

library unisim;
	use unisim.vcomponents.all;

entity PIPISTRELLO_TOP is
port(
	I_RESET		: in		std_logic;								-- active high reset

	O_VSYNC		: out		std_logic;
	O_HSYNC		: out		std_logic;
	O_VIDEO_R	: out		std_logic_vector(3 downto 0);
	O_VIDEO_G	: out		std_logic_vector(3 downto 0);
	O_VIDEO_B	: out		std_logic_vector(3 downto 0);

	-- HDMI video output
--	TMDS_P		: out   std_logic_vector(3 downto 0);
--	TMDS_N		: out   std_logic_vector(3 downto 0);

	-- Sound out
	O_AUDIO_L	: out		std_logic;
	O_AUDIO_R	: out		std_logic;

	-- PS2 Keyboard
	PS2CLK1		: inout	std_logic;
	PS2DAT1		: inout	std_logic;

	-- 50MHz clock
	CLK50			: in		std_logic := '0'
);
end PIPISTRELLO_TOP;

architecture RTL of PIPISTRELLO_TOP is
	signal clock_50m_fb						: std_logic;
	signal int_reset							: std_logic := '0';
	signal reset_counter						: std_logic_vector(7 downto 0);

	-- PS2
	signal ps2_codeready						: std_logic := '1';
	signal ps2_scancode						: std_logic_vector(9 downto 0);

	-- buttons
	signal SW									: std_logic_vector(7 downto 0) := (others=>'1');
	signal JA, JB								: std_logic_vector(8 downto 0) := (others=>'1');

	-- Internal clocks
	signal clk12								: std_logic := '0';

	-- VIDEO
	signal HSync, VSync						: std_logic := '1';
	signal VideoR                       : std_logic_vector(2 downto 0);
	signal VideoG                       : std_logic_vector(2 downto 0);
	signal VideoB                       : std_logic_vector(1 downto 0);

	-- Audio
	signal snd_clk								: std_logic := '0';
	signal pwm_out								: std_logic := '0';
	signal P_SOUND								: std_logic_vector(6 downto 0);
	signal sound_to_dac						: std_logic_vector(7 downto 0);
	signal ctr									: std_logic_vector(5 downto 0) := (others => '0');
begin
	O_AUDIO_L  <= pwm_out;
	O_AUDIO_R  <= pwm_out;

	O_VIDEO_R  <= VideoR & "0";
	O_VIDEO_G  <= VideoG & "0";
	O_VIDEO_B  <= VideoB & "00";
	O_HSYNC    <= HSync;
	O_VSYNC    <= VSync;

	-------------------------------------------------------------------
	-- System Clock

	dcm_12m: DCM_SP
	generic map (
		CLKFX_DIVIDE   => 25,
		CLKFX_MULTIPLY => 6,
		CLKIN_PERIOD   => 20.0,
		STARTUP_WAIT   => true
	)
	port map(
		CLKIN => CLK50,
		CLKFX => clk12,
		CLK0  => clock_50m_fb,
		CLKFB => clock_50m_fb
	);

	-------------------------------------------------------------------
	-- Delayed Reset generator

	process
	begin
		wait until rising_edge(clk12);
		if I_RESET = '1' then
			reset_counter <= (others => '0');
			int_reset <= '1';
		else
			if reset_counter < x"80" then
				reset_counter <= reset_counter + 1;
			else
				int_reset <= '0';
			end if;
		end if;
	end process;

--	Derive a clock as close to 894886.25 Hz as possible for the sound board
	process
	begin
		wait until rising_edge(CLK50);
		ctr <= ctr + 1;
		if ctr = "111000" then
			ctr <= (others=> '0');
		end if;
	end process;
	snd_clk <= ctr(5);

	-----------------------------------------------------------------------------
	-- Keyboard - active low buttons
	-----------------------------------------------------------------------------
	inst_kbd : entity work.Keyboard
	port map (
		Reset     => int_reset,
		Clock     => clk12,
		PS2Clock  => PS2CLK1,
		PS2Data   => PS2DAT1,
		CodeReady => ps2_codeready,
		ScanCode  => ps2_scancode
	);

-- ScanCode(9)          : 1 = Extended  0 = Regular
-- ScanCode(8)          : 1 = Break     0 = Make
-- ScanCode(7 downto 0) : Key Code
	process
	begin
		wait until rising_edge(clk12);
		if int_reset = '1' then
			JA <= (others=>'1');
			JB <= (others=>'1');
			SW <= (others=>'1');
		elsif (ps2_codeready = '1') then
			case (ps2_scancode(7 downto 0)) is
				when x"76" =>	SW(3)   <= ps2_scancode(8);  -- "ESC"        HS reset
				when x"05" =>  SW(4)   <= ps2_scancode(8);  -- "F1"         left   coin
				when x"06" =>	SW(5)   <= ps2_scancode(8);  -- "F2"         center coin
				when x"04" =>	SW(2)   <= ps2_scancode(8);  -- "F3"         right  coin
				when x"0C" =>	SW(6)   <= ps2_scancode(8);  -- "F4"         slam

				when x"03" =>	JA(8)   <= ps2_scancode(8);  -- "F5"         P1 start
				when x"0B" =>	JB(8)   <= ps2_scancode(8);  -- "F6"         P2 start

				when x"83" =>	SW(0)   <= ps2_scancode(8);  -- "F7"         auto up
				when x"0A" =>	SW(1)   <= ps2_scancode(8);  -- "F8"         advance

				-- fire control
				when x"43" =>	JA(4)  <= ps2_scancode(8);   -- "I"          P1 fire up
									JB(4)  <= ps2_scancode(8);   -- "I"          P2 fire up
				when x"42" =>	JA(5)  <= ps2_scancode(8);   -- "K"          P1 fire down
									JB(5)  <= ps2_scancode(8);   -- "K"          P2 fire down
				when x"3B" =>	JA(6)  <= ps2_scancode(8);   -- "J"          P1 fire left
									JB(6)  <= ps2_scancode(8);   -- "J"          P2 fire left
				when x"4B" =>	JA(7)  <= ps2_scancode(8);   -- "L"          P1 fire right
									JB(7)  <= ps2_scancode(8);   -- "L"          P2 fire right

				-- movement control
				when x"75" =>	JA(0)  <= ps2_scancode(8);   -- arrow up     P1 up
									JB(0)  <= ps2_scancode(8);   -- arrow up     P2 up
				when x"72" =>	JA(1)  <= ps2_scancode(8);   -- arrow down   P1 down
									JB(1)  <= ps2_scancode(8);   -- arrow down   P2 down
				when x"6B" =>	JA(2)  <= ps2_scancode(8);   -- arrow left   P1 left
									JB(2)  <= ps2_scancode(8);   -- arrow left   P2 left
				when x"74" =>	JA(3)  <= ps2_scancode(8);   -- arrow right  P1 right
									JB(3)  <= ps2_scancode(8);   -- arrow right  P2 right
				when others => null;
			end case;
		end if;
	end process;

	-- Robotron
	inst_robotron : entity work.robotron_cpu
	port map(
		-- system clock 12MHz
		CLK12         => clk12,
		RST           => int_reset,

		-- Control inputs
		SW            => SW,
		JA            => JA,
		JB            => JB,

		-- Sound out
		PB            => P_SOUND,

		-- VGA out
		vgaR          => VideoR,
		vgaG          => VideoG,
		vgaB          => VideoB,
		Hsync         => HSync,
		Vsync         => VSync
	);

	inst_sound : entity work.robotron_sound
	port map (
		clk_cpu       => snd_clk, -- 3579545 Hz / 4 = 894886.25 Hz
		reset         => int_reset,
		diagnostic    => '0', -- active high
		pb            => P_SOUND(5 downto 0),
		hand          => P_SOUND(6),
		dac           => sound_to_dac
	);

	inst_dac : entity work.dac
	generic map ( msbi_g => 7 )
	port map (
		clk_i         => clk12,
		reset         => int_reset,
		dac_i         => sound_to_dac,
		dac_o         => pwm_out
	);
end RTL;
