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
--	Bootstrap driver
-- 
--	This will read the contents of the SPI FLASH from address stored in constant
--	'user_address' and write them to the external SRAM starting at address 0
--	On completion, it will raise 'O_BS_DONE' which could be used as a reset signal
--	by the user
--------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_arith.all;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.all;

entity bootstrap is
	port (
		I_CLK				: in  std_logic;	-- clock
		I_RESET			: in  std_logic;	-- reset input
		-- FLASH interface
		I_FLASH_SO		: in  std_logic;
		O_FLASH_CK		: out std_logic;
		O_FLASH_CS		: out std_logic;
		O_FLASH_SI		: out std_logic;
		-- SRAM interface
		O_A				: out std_logic_vector (17 downto 0);
		O_DOUT			: out std_logic_vector (7 downto 0) := (others => '0');
		O_nCS				: out std_logic := '0';
		O_nWE				: out std_logic := '1';
		O_nOE				: out std_logic := '1';
		--
		O_BS_DONE		: out std_logic := '0'	-- low when FLASH is being copied to SRAM, can be used by user as active low reset
	);
end bootstrap;

architecture RTL of bootstrap is
--	signal patch_idx			: integer range 0 to 15 := 0;
--	type array_16x8  is array (0 to 15) of std_logic_vector( 7 downto 0);
--	type array_16x16 is array (0 to 15) of std_logic_vector(15 downto 0);
---- this small patch table can be used to patch the game ROM during testing to cause the game
---- for example to skip to a certain point, see game disassembly for suitable patch locations
---- currently this patch table bypasses the console power on self test and on power on jumps
---- straight to title screen and remains there (no looping to game demo or high scores)
---- if you want to use this, uncomment state machine FLASH1 state also
----															nop,		nop,		nop,		nop,		nop,		nop,		nop,	jump vector 0x4750, unused values
--	signal patch_A				: array_16x16 := (x"0120", x"0121", x"0122", x"0123", x"0124", x"0125", x"4605", x"4622", x"4623", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000");
--	signal patch_D				: array_16x8  := (  x"00",   x"00",   x"00",   x"00",   x"00",   x"00",   x"00",   x"50",   x"47",   x"00",   x"00",   x"00",   x"00",   x"00",   x"00",   x"00");

	-- start address of user data in FLASH as obtained from bitmerge.py
	constant user_address	: std_logic_vector(23 downto 0) := x"053400";
	-- user_length = "max FLASH addr" - user_address = 07FFFF - 053500 = 02CAFF
	constant user_length		: std_logic_vector(23 downto 0) := x"01CAFF";

	--
	-- bootstrap signals
	--
	signal flash_data			: std_logic_vector( 7 downto 0) := (others => '0');
	signal flash_init			: std_logic := '0';	-- when low places FLASH driver in init state
	signal flash_done			: std_logic := '0';	-- FLASH init finished when high

	-- bootstrap control of SRAM, these signals connect to SRAM when boostrap_busy = '1'
	signal bs_A					: std_logic_vector(17 downto 0) := (others => '0');

	-- for bootstrap state machine
	type	BS_STATE_TYPE is (
				INIT, START_READ_FLASH, READ_FLASH,
				FLASH0, FLASH1, FLASH2, FLASH3, FLASH4, FLASH5, FLASH6, FLASH7,
				WAIT0, WAIT1, WAIT2, WAIT3, WAIT4, WAIT5, WAIT6, WAIT7, WAIT8
			);
	signal bs_state, bs_state_next : BS_STATE_TYPE;

begin
	O_A <= bs_A;

	-- FLASH chip SPI driver
	u_flash : entity work.spi_flash
	port map (
		O_FLASH_CK		=> O_FLASH_CK,	-- to FLASH chip SPI clock
		O_FLASH_CS		=> O_FLASH_CS,	-- to FLASH chip select
		O_FLASH_SI		=> O_FLASH_SI,	-- to FLASH chip SPI input
		O_FLASH_DONE	=> flash_done,
		O_FLASH_DATA	=> flash_data,

		I_FLASH_SO		=> I_FLASH_SO,	-- to FLASH chip SPI output
		I_FLASH_CLK		=> I_CLK,
		I_FLASH_INIT	=> flash_init,
		I_FLASH_ADDR	=> user_address
	);

	-- bootstrap state machine
	state_bootstrap : process(I_CLK, I_RESET, bs_state_next)
	begin
		bs_state <= bs_state_next;									-- advance bootstrap state machine
		if I_RESET = '1' then										-- external reset pin
			bs_state_next <= INIT;									-- move state machine to INIT state
		elsif rising_edge(I_CLK) then
			case bs_state is
				when INIT =>
					O_BS_DONE <= '0';							-- indicate bootstrap in progress (holds user in reset)
					flash_init <= '0';								-- signal FLASH to begin init
					bs_A   <= (others => '1');						-- SRAM address all ones (becomes zero on first increment)
					O_nCS <= '0';										-- SRAM always selected during bootstrap
					O_nOE <= '1';										-- SRAM output disabled during bootstrap
					O_nWE <= '1';										-- SRAM write enable inactive default state
					bs_state_next <= START_READ_FLASH;
				when START_READ_FLASH =>
					flash_init <= '1';								-- allow FLASH to exit init state
					if flash_done = '0' then						-- wait for FLASH init to begin
						bs_state_next <= READ_FLASH;
					end if;
				when READ_FLASH =>
					if flash_done = '1' then						-- wait for FLASH init to complete
						bs_state_next <= WAIT0;
					end if;
				when WAIT0 =>											-- wait for the first FLASH byte to be available
					bs_state_next <= WAIT1;
				when WAIT1 =>
					bs_state_next <= WAIT2;
				when WAIT2 =>
					bs_state_next <= WAIT3;
				when WAIT3 =>
					bs_state_next <= WAIT4;
				when WAIT4 =>
					bs_state_next <= WAIT5;
				when WAIT5 =>
					bs_state_next <= WAIT6;
				when WAIT6 =>
					bs_state_next <= WAIT7;
				when WAIT7 =>
					bs_state_next <= WAIT8;
				when WAIT8 =>
					bs_state_next <= FLASH0;

				-- every 8 clock cycles (32M/8 = 2Mhz) we have a new byte from FLASH
				-- use this ample time to write it to SRAM, we just have to toggle nWE
				when FLASH0 =>
					bs_A <= bs_A + 1;									-- increment SRAM address
					bs_state_next <= FLASH1;						-- idle
				when FLASH1 =>
--					-- apply patch table here
--					if bs_A = "01" & patch_A(patch_idx) then
--						O_DOUT( 7 downto 0) <= patch_D(patch_idx);
--						patch_idx <= patch_idx + 1;
--					else
						O_DOUT( 7 downto 0) <= flash_data;		-- place byte on SRAM data bus
--					end if;
					bs_state_next <= FLASH2;						-- idle
				when FLASH2 =>
					O_nWE <= '0';										-- SRAM write enable
					bs_state_next <= FLASH3;
				when FLASH3 =>
					bs_state_next <= FLASH4;						-- idle
				when FLASH4 =>
					bs_state_next <= FLASH5;						-- idle
				when FLASH5 =>
					bs_state_next <= FLASH6;						-- idle
				when FLASH6 =>
					O_nWE <= '1';										-- SRAM write disable
					bs_state_next <= FLASH7;
				when FLASH7 =>
					if bs_A = user_length then						-- when we've reached end address
						O_BS_DONE <= '1';						-- indicate bootsrap is done
						flash_init <= '0';							-- place FLASH in init state
						bs_state_next <= FLASH7;					-- remain in this state until reset
					else
						bs_state_next <= FLASH0;					-- else loop back
					end if;
				when others =>											-- catch all, never reached
					bs_state_next <= INIT;
			end case;
		end if;
	end process;
end RTL;
