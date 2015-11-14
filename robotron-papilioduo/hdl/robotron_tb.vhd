library std;
	use std.textio.all;

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_textio.all;

entity robotron_tb is
end robotron_tb;

architecture behavior of robotron_tb is 
	--Inputs
	signal I_RESET   : std_logic := '0';
	signal CLK50     : std_logic := '0';

	--BiDirs
	signal PS2CLK1   : std_logic;
	signal PS2DAT1   : std_logic;

	--Outputs
	signal TMDS_P    : std_logic_vector(3 downto 0);
	signal TMDS_N    : std_logic_vector(3 downto 0);
	signal O_AUDIO_L : std_logic;
	signal O_AUDIO_R : std_logic;

	-- 50MHz clock timings
	constant CLK50_frequency : integer := 50000000; -- Hertz
	constant CLK50_period : TIME := 1000 ms / CLK50_frequency;

	constant PS2CLK1_frequency : integer := 25000; -- Hertz
	constant PS2CLK1_period : time := 1000 ms / PS2CLK1_frequency;

begin
	-- Stimulus process
	tb_keyboard : process
		file file_in 		: text open read_mode is "../hdl/keypress.txt";
		variable line_in	: line;
		variable cmd		: character;
		variable delay		: time;
		variable char		: std_logic_vector(7 downto 0);
		variable ps2tx		: std_logic_vector(10 downto 0);
	begin

		loop                                   
			readline(file_in, line_in);           
			read(line_in, cmd);

			case cmd is

				-- Wait
				when 'W' =>
					read(line_in, delay);
					PS2CLK1 <= '1';
					PS2DAT1 <= '1';
					wait for delay;

				-- Key
				when 'K' =>
					hread(line_in, char);
					ps2tx := "11" & char & "0"; -- stop_bit + parity + byte + start_bit

					for i in 0 to 10 loop
						PS2DAT1 <= ps2tx(i);	-- LSB to MSB
						wait for PS2CLK1_period/2;
						PS2CLK1 <= '0';
						wait for PS2CLK1_period;
						PS2CLK1 <= '1';
						wait for PS2CLK1_period/2;
					end loop;

				-- End
				when 'E' =>
					PS2CLK1 <= '1';
					PS2DAT1 <= 'Z';
					wait;

				when others => null;

			end case;
		end loop;

	end process;

	uut: entity work.PIPISTRELLO_TOP PORT MAP (
		I_RESET   => I_RESET,
		PS2CLK1   => PS2CLK1,
		PS2DAT1   => PS2DAT1,
		CLK50     => CLK50
	);

	-- Clock process definitions
	CLK50_process :process
		begin
		CLK50 <= '0';
		wait for CLK50_period/2;
		CLK50 <= '1';
		wait for CLK50_period/2;
	end process;


	-- Stimulus process
	stim_proc: process
	begin		
		I_RESET <= '1';
		wait for CLK50_period*32;
		I_RESET <= '0';
		wait;
	end process;
end;
