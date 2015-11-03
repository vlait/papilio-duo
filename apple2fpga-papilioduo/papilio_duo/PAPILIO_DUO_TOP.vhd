-------------------------------------------------------------------------------
--
-- Papilio DUO with Classic computing shield  top-level module for the Apple ][
--
-- VLA
--
-- Based on DE2 top-level by Stephen A. Edwards, Columbia University, sedwards@cs.columbia.edu
--
-- From an original by Terasic Technology, Inc.
-- (DE2_TOP.v, part of the DE2 system board CD supplied by Altera)
--
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PAPILIO_DUO_TOP is

  port (
    -- Clocks
    
    CLOCK_32 : in std_logic;                      -- 

    -- Buttons and switches
    
    KEY : in std_logic_vector(3 downto 0);         -- Push buttons
    --SW  : in unsigned(9 downto 0);                 -- DPDT switches

    I_RESET : in std_logic;
    -- LED displays

 	LED : out std_logic_vector(3 downto 0); 		-- have only 4, not sure what to do with them
    -- RS-232 interface

  --  UART_TXD : out std_logic;                      -- UART transmitter   
  --  UART_RXD : in std_logic;                       -- UART receiver


    -- SRAM
    
    SRAM_DQ : inout unsigned(7 downto 0);         -- Data bus 8 Bits
    SRAM_ADDR : out unsigned(20 downto 0);         -- Address bus 20 Bits
    SRAM_WE_N,                                     -- Write Enable
    SRAM_CE_N,                                     -- Chip Enable
    SRAM_OE_N : out std_logic;                     -- Output Enable

    -- SD card interface
    
    SD_DAT : in std_logic;      -- SD Card Data      SD pin 7 "DAT 0/DataOut"
    SD_DAT3 : out std_logic;    -- SD Card Data 3    SD pin 1 "DAT 3/nCS"
    SD_CMD : out std_logic;     -- SD Card Command   SD pin 2 "CMD/DataIn"
    SD_CLK : out std_logic;     -- SD Card Clock     SD pin 5 "CLK"
		SD_CD : in std_logic;
    
    -- PS/2 port

    PS2_DAT,                    -- Data
    PS2_CLK : in std_logic;     -- Clock

    -- VGA output
    
    VGA_HS,                                        -- H_SYNC
    VGA_VS : out std_logic;                        -- V_SYNC
    VGA_R,                                         -- Red[3:0]
    VGA_G,                                         -- Green[3:0]
    VGA_B : out unsigned(3 downto 0);              -- Blue[3:0]

    -- Audio OUT
    
    O_AUDIO_L : out std_logic;                          -- ADC Data
	 O_AUDIO_R : out std_logic                          -- ADC Data
    
    );
  
end PAPILIO_DUO_TOP;

architecture datapath of PAPILIO_DUO_TOP is

 
 
  signal CLK_28M, CLK_14M, CLK_2M, PRE_PHASE_ZERO : std_logic;
  signal IO_SELECT, DEVICE_SELECT : std_logic_vector(7 downto 0);
  signal ADDR : unsigned(15 downto 0);
  signal D, PD : unsigned(7 downto 0);

  signal ram_we : std_logic;
  signal VIDEO, HBL, VBL, LD194 : std_logic;
  signal COLOR_LINE : std_logic;
  signal COLOR_LINE_CONTROL : std_logic;
  signal GAMEPORT : std_logic_vector(7 downto 0);
  signal cpu_pc : unsigned(15 downto 0);

  signal K : unsigned(7 downto 0);
  signal read_key : std_logic;

  signal flash_clk : unsigned(22 downto 0) := (others => '0');
  signal power_on_reset : std_logic := '1';
  signal reset : std_logic;

  signal speaker : std_logic;
  signal audio_bit : std_logic;

  signal track : unsigned(5 downto 0);
  signal image : unsigned(9 downto 0);
  signal trackmsb : unsigned(3 downto 0);
  signal D1_ACTIVE, D2_ACTIVE : std_logic;
  signal track_addr : unsigned(13 downto 0);
  signal TRACK_RAM_ADDR : unsigned(13 downto 0);
  signal tra : unsigned(15 downto 0);
  signal TRACK_RAM_DI : unsigned(7 downto 0);
  signal TRACK_RAM_WE : std_logic;
  signal R_10 : unsigned(9 downto 0);
  signal G_10 : unsigned(9 downto 0);
  signal B_10 : unsigned(9 downto 0);

  signal CS_N, MOSI, MISO, SCLK : std_logic;

begin

  reset <=  I_RESET or power_on_reset;

  power_on : process(CLK_14M)
  begin
    if rising_edge(CLK_14M) then
      if flash_clk(22) = '1' then
        power_on_reset <= '0';
      end if;
    end if;
  end process;

  -- In the Apple ][, this was a 555 timer
  flash_clkgen : process (CLK_14M)
  begin
    if rising_edge(CLK_14M) then
      flash_clk <= flash_clk + 1;
    end if;     
  end process;

  --  32 MHz down to 28 MHz and 14 MHz

	dcm : entity work.CLOCKGEN port map (
		I_CLK			=> CLOCK_32,
		I_RST 		=> '0',
		O_CLK_28M	=> CLK_28M,
		O_CLK_14M	=> CLK_14M
		);
  -- Paddle buttons
  GAMEPORT <=  "0000" & "0000"; -- (not KEY(2 downto 0)) & "0";

  COLOR_LINE_CONTROL <= COLOR_LINE ; --  could we use scroll lock ? and SW(9);  -- Color or B&W mode
  
  core : entity work.apple2 port map (
    CLK_14M        => CLK_14M,
    CLK_2M         => CLK_2M,
    PRE_PHASE_ZERO => PRE_PHASE_ZERO,
    FLASH_CLK      => flash_clk(22),
    reset          => reset,
    ADDR           => ADDR,
    ram_addr       => SRAM_ADDR(15 downto 0),
    D              => D,
    ram_do         => SRAM_DQ(7 downto 0),
    PD             => PD,
    ram_we         => ram_we,
    VIDEO          => VIDEO,
    COLOR_LINE     => COLOR_LINE,
    HBL            => HBL,
    VBL            => VBL,
    LD194          => LD194,
    K              => K,
    read_key       => read_key,
    AN             => open, -- LEDG(7 downto 4),
    GAMEPORT       => GAMEPORT,
    IO_SELECT      => IO_SELECT,
    DEVICE_SELECT  => DEVICE_SELECT,
    pcDebugOut     => cpu_pc,
    speaker        => speaker
    );

  vga : entity work.vga_controller port map (
    CLK_28M    => CLK_28M,
    VIDEO      => VIDEO,
    COLOR_LINE => COLOR_LINE_CONTROL,
    HBL        => HBL,
    VBL        => VBL,
    LD194      => LD194,
    VGA_HS     => VGA_HS,
    VGA_VS     => VGA_VS,
    VGA_R      => R_10,
    VGA_G      => G_10,
    VGA_B      => B_10
    );

  VGA_R <= R_10(9 downto 6);
  VGA_G <= G_10(9 downto 6);
  VGA_B <= B_10(9 downto 6);

  keyboard : entity work.keyboard port map (
    PS2_Clk  => PS2_CLK,
    PS2_Data => PS2_DAT,
    CLK_14M  => CLK_14M,
    reset    => reset,
    read     => read_key,
    K        => K
    );

  disk : entity work.disk_ii port map (
    CLK_14M        => CLK_14M,
    CLK_2M         => CLK_2M,
    PRE_PHASE_ZERO => PRE_PHASE_ZERO,
    IO_SELECT      => IO_SELECT(6),
    DEVICE_SELECT  => DEVICE_SELECT(6),
    RESET          => reset,
    A              => ADDR,
    D_IN           => D,
    D_OUT          => PD,
    TRACK          => TRACK,
    TRACK_ADDR     => TRACK_ADDR,
    D1_ACTIVE      => D1_ACTIVE,
    D2_ACTIVE      => D2_ACTIVE,
    ram_write_addr => TRACK_RAM_ADDR,
    ram_di         => TRACK_RAM_DI,
    ram_we         => TRACK_RAM_WE
    );

  sdcard_interface : entity work.spi_controller port map (
    CLK_14M        => CLK_14M,
    RESET          => RESET,

    CS_N           => CS_N,
    MOSI           => MOSI,
    MISO           => MISO,
    SCLK           => SCLK,
    
    track          => TRACK,
    image          => image,
    
    ram_write_addr => TRACK_RAM_ADDR,
    ram_di         => TRACK_RAM_DI,
    ram_we         => TRACK_RAM_WE
    );

  image <= "0" & "000000000"; -- ... this would be nice too, maybe ctrl-up/down and leds to show the image number? -- SW(8 downto 0);

  SD_DAT3 <= CS_N;
  SD_CMD  <= MOSI;
  MISO    <= SD_DAT;
  SD_CLK  <= SCLK;

  audio_output : entity work.dac port map (
   clk_i 			=> CLK_14M,
	res_n_i			=> not reset,
	dac_i			=> speaker & "0000000",
	dac_o			=> audio_bit
	);
	
	O_AUDIO_L <= audio_bit;
	O_AUDIO_R <= audio_bit;
	
  -- Current disk track on right two digits 
  trackmsb <= "00" & track(5 downto 4);
  
  SRAM_DQ(7 downto 0) <= D when ram_we = '1' else (others => 'Z');
  SRAM_ADDR(20 downto 16) <= "00000";
  SRAM_CE_N <= '0';
  SRAM_WE_N <= not ram_we;
  SRAM_OE_N <= ram_we;




	
  -- Set all other unused bidirectional ports to tri-state

end datapath;
