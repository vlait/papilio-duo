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

entity PAPILIO_DUO_TOP is
port(
	I_RESET		: in		std_logic;								-- active high reset

	O_VSYNC		: out		std_logic;
	O_HSYNC		: out		std_logic;
	O_VIDEO_R	: out		std_logic_vector(3 downto 0);
	O_VIDEO_G	: out		std_logic_vector(3 downto 0);
	O_VIDEO_B	: out		std_logic_vector(3 downto 0);


	-- Sound out
	O_AUDIO_LEFT	: out		std_logic;
	O_AUDIO_RIGHT	: out		std_logic;

	-- PS2 Keyboard
	PS2CLK1		: inout	std_logic;
	PS2DAT1		: inout	std_logic;
	
	-- SRAM
	SRAM_ADDR		: out		std_logic_vector(20 downto 0);
	SRAM_DATA		: inout	std_logic_vector(7 downto 0);
	SRAM_CE		: out 	std_logic := '0';
	SRAM_WE		: out		std_logic := '1';
	SRAM_OE		: out		std_logic := '0';
	
	--	SPI FLASH
	FLASH_CS		:	out std_logic;
	FLASH_CK		: out	std_logic;
	FLASH_SI		: out	std_logic;
	FLASH_SO 	: in std_logic := '0';
	
	-- LED
	LED1			: out std_logic;
	LED2			: out std_logic;
	LED3			: out std_logic;
	LED4			: out std_logic;
	-- 32MHz clock
	CLK			:	in std_logic
);
end PAPILIO_DUO_TOP;

architecture RTL of PAPILIO_DUO_TOP is

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
	
	--sram
	signal user_SRAM							: std_logic_vector(7 downto 0);
	signal user_ADDR							: std_logic_vector(20 downto 0);
	
	-- bootstrap
	
	signal bs_done								: std_logic := '0'; 
	signal bs_A					: std_logic_vector(17 downto 0) := (others => '0');
	signal bs_Dout				: std_logic_vector( 7 downto 0) := (others => '0');
	signal bs_nCS				: std_logic := '1';
	signal bs_nWE				: std_logic := '1';
	signal bs_nOE				: std_logic := '1';
	signal bs_SNDROM_w      : std_logic := '0';
	signal bs_DECODER_4_w	: std_logic := '0';
	signal bs_DECODER_6_w	: std_logic := '0';
	
begin
	O_AUDIO_LEFT  <= pwm_out;
	O_AUDIO_RIGHT  <= pwm_out;

	O_VIDEO_R  <= VideoR & "0";
	O_VIDEO_G  <= VideoG & "0";
	O_VIDEO_B  <= VideoB & "00";
	O_HSYNC    <= HSync;
	O_VSYNC    <= VSync;

	LED1 <= '0';
	LED2 <= '0';
	LED3 <= bs_done;
	LED4 <= '0';
   -------------------------------------------------------------------
	-- System Clock

	dcm_12m: DCM_SP
	generic map (
		CLKFX_DIVIDE   => 16,
		CLKFX_MULTIPLY => 6,
		CLKIN_PERIOD   => 31.25,
		STARTUP_WAIT   => true
	)
	port map(
		CLKIN => CLK,
		CLKFX => clk12,
		CLK0  => clock_50m_fb,
		CLKFB => clock_50m_fb
	);

	
	-- SRAM muxer, allows access to physical SRAM by either bootstrap or cpu board
	SRAM_DATA	<=  bs_Dout	when bs_done = '0' and bs_nWE = '0'	else (others => 'Z'); -- no need for user write
	SRAM_ADDR	<= "000" & bs_A					when bs_done = '0'							else user_ADDR;
	SRAM_CE	<= '0'; 
	SRAM_WE	<= bs_nWE				when bs_done = '0'							else '1';
	SRAM_OE	<= bs_nOE				when bs_done = '0'							else '0';
	
	user_SRAM	<= SRAM_DATA;
	-- bootstrap controls for sound and decoder roms
	-- bootstrap blob memory map (robotron, joust etc, NOT defender)
	-- 0x0000 - 0x9fff cpu board banked roms 0-9
	-- 0xa000 - 0xb000 filler, don't care
	-- 0xb000 - 0xbfff sound ROM
	-- 0xc000 - 0xc1ff decoder 4 prom
	-- 0xc200 - 0xc3ff decoder 6 prom
	-- 0xc400 - 0xcbff filler, don't care
	-- 0xcc00 - 0xcfff cmos ram (not wired in yet, press reset after "factory settings restored") 
	-- 0xd000 - 0xffff cpu board non-banked roms  
	-- the empty filler sections could be used to hold controller mappings but not done yet
	--
	-- with lx9 the start of the blob on the flash will be 0x053400
	--
	bs_SNDROM_w    <= '1' when ( bs_done = '0' and ( bs_A >= x"b000" and bs_A < x"c000" )) else '0';
	bs_DECODER_4_w <= '1' when ( bs_done = '0' and ( bs_A >= x"c000" and bs_A < x"c200" )) else '0';
	bs_DECODER_6_w <= '1' when ( bs_done = '0' and ( bs_A >= x"c200" and bs_A < x"c400" )) else '0';
	-- cmos ram r/w tbd
	--bs_CMOSRAM_w <= '1' when ( bs_done = '0' and ( bs_A >= x"cc00" and bs_A < x"cfff" )) else '0';
	
	--
	
	u_bs : entity work.bootstrap
	port map (
		I_CLK				=> snd_clk,
		I_RESET			=> I_RESET,
		-- FLASH interface
		I_FLASH_SO		=> FLASH_SO,	-- to FLASH chip SPI output
		O_FLASH_CK		=> FLASH_CK,	-- to FLASH chip SPI clock
		O_FLASH_CS		=> FLASH_CS,	-- to FLASH chip select
		O_FLASH_SI		=> FLASH_SI,	-- to FLASH chip SPI input
		-- SRAM interface
		O_A				=> bs_A,
		O_DOUT			=> bs_Dout,
		O_nCS				=> bs_nCS,
		O_nWE				=> bs_nWE,
		O_nOE				=> bs_nOE,
		O_BS_DONE		=> bs_done -- reset output to rest of machine
	);

	-------------------------------------------------------------------
	-- Delayed Reset generator

	process
	begin
		wait until rising_edge(clk12);
		if bs_done = '0' then -- if I_RESET = '1' or bs_done = '0' then
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
-- fixme, 888kHz doesn't sound ok
	process
	begin
		wait until rising_edge(CLK);
		ctr <= ctr + 1;
		if ctr = "100100" then -- 888888Hz... 
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
		
		-- SRAM access
		SRAM_A			=> user_ADDR,
		SRAM_D			=> user_SRAM,

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
		Vsync         => VSync,
		
		-- bootstrap signals
		bs_DECODER_4_w => bs_DECODER_4_w,
		bs_DECODER_6_w => bs_DECODER_6_w,
		bs_A				=> bs_A,
		bs_Dout			=> bs_Dout
		
	);

	inst_sound : entity work.robotron_sound
	port map (
		clk_cpu       => snd_clk, -- 3579545 Hz / 4 = 894886.25 Hz
		reset         => int_reset,
		diagnostic    => '0', -- active high
		pb            => P_SOUND(5 downto 0),
		hand          => P_SOUND(6),
		dac           => sound_to_dac,
		bs_done       => bs_done,
		bs_SNDROM_w   => bs_SNDROM_w,
		bs_SNDROM_a   => bs_A,
		bs_SNDROM_d   => bs_Dout 
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
