library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;

entity Neural_tb is
generic
(
	constant X_NAME : string(17 downto 1) := "Neural_weight.mif";
	constant Y_NAME : string(9 downto 1) := "Input.mif";
	constant Z_NAME : string(10 downto 1) := "Output.mif";
	constant CLOCK_PERIOD : time := 2 ns;
	constant DATA_SIZE : integer := 64;
	constant NODE_NUM  : integer := 8
);
end entity Neural_tb;

architecture behavior of Neural_tb is
	signal clock : std_logic := '1';
	signal reset : std_logic := '0';
	signal start : std_logic := '0';
	signal done : std_logic := '0';
	
	signal x_din : std_logic_vector(7 downto 0) := B"00000000";
	signal x_dout: std_logic_vector(7 downto 0) := B"00000000";
	signal x_rd_addr: std_logic_vector(5 downto 0) := B"000000";
	signal x_wr_addr: std_logic_vector(5 downto 0) := B"000000";
	signal x_wr_en: std_logic := '0';
	signal y_din : std_logic_vector(7 downto 0) := B"00000000";
	signal y_dout: std_logic_vector(7 downto 0) := B"00000000";
	signal y_rd_addr: std_logic_vector(5 downto 0) := B"000000";
	signal y_wr_addr: std_logic_vector(5 downto 0) := B"000000";
	signal y_wr_en: std_logic := '0';
	signal z_din: std_logic_vector(31 downto 0) := X"00000000";
	signal z_dout: std_logic_vector(31 downto 0) := X"00000000";
	signal z_rd_addr: std_logic_vector(5 downto 0) := B"000000";
	signal z_wr_addr: std_logic_vector(5 downto 0) := B"000000";
	signal z_wr_en: std_logic := '0';

	signal hold_clock : std_logic := '0';
	signal x_write_done : std_logic := '0';
	signal y_write_done : std_logic := '0';
	signal z_read_done : std_logic := '0';
	signal z_errors : integer := 0;

	component Neural_top
	port
	(
		signal clock : in std_logic;
		signal reset : in std_logic;
		signal start : in std_logic;
		signal done : out std_logic;
		--signal x_wr_addr: in std_logic_vector(5 downto 0);
		--signal x_wr_en: in std_logic;
		--signal x_din : in std_logic_vector(7 downto 0);
		--signal y_wr_addr : in std_logic_vector(5 downto 0);
		--signal y_wr_en: in std_logic;
		--signal y_din : in std_logic_vector(7 downto 0);
		signal z_rd_addr : in std_logic_vector(5 downto 0);
		signal z_dout : out std_logic_vector(31 downto 0)
	);
	end component;

	begin
	Neural_top_inst : component Neural_top
	port map
	(
		clock => clock,
		reset => reset,
		start => start,
		done => done,
		--x_wr_addr => x_wr_addr,
		--x_wr_en => x_wr_en,
		--x_din => x_din,
		--y_wr_addr => y_wr_addr,
		--y_wr_en => y_wr_en,
		--y_din => y_din,
		z_rd_addr => z_rd_addr,
		z_dout => z_dout
	);

	clock_process : process
	begin
		clock <= '1';
		wait for (CLOCK_PERIOD / 2);
		clock <= '0';
		wait for (CLOCK_PERIOD / 2);
		if(hold_clock = '1') then
			wait;
		end if;
	end process clock_process;

	reset_process : process
	begin
		reset <= '0';
		wait until (clock = '0');
		wait until (clock = '1');
		reset <= '1';
		wait until (clock = '0');
		wait until (clock = '1');
		reset <= '0';
		wait;
	end process reset_process;

	z_read_process : process
	file z_file : text;
	variable rdz : std_logic_vector(19 downto 0);
	variable in1, in2 : line;
	variable z : integer := 0;
	variable z_data_read: std_logic_vector(31 downto 0);
	variable z_data_cmp: std_logic_vector(19 downto 0);
	begin
		wait until (reset = '1');
		wait until (reset = '0');
		
		--wait until ((x_write_done= '1') and (y_write_done= '1'));

		wait until  (done = '1');
		wait until  (clock = '1');
		wait until  (clock = '0');
		wait until  (clock = '1');
		wait until  (clock = '0');
		
		write( in1, string'("@ "));
		write( in1, NOW );
		write( in1, string'(": Comparing file "));
		write( in1, Z_NAME );
		writeline( output, in1 );

		file_open( z_file, Z_NAME, read_mode);
		for z in 0 to 8 loop
			wait until  (clock = '0');
			z_rd_addr <= std_logic_vector(to_unsigned(z,6));
			wait until (clock = '1');
			wait until (clock = '0');
			wait until (clock = '1');
			wait until (clock = '0');
			readline( z_file, in2 );
			hread( in2, rdz);
			z_data_cmp := std_logic_vector(rdz);
			z_data_read := z_dout;
			if (to_integer(unsigned(z_data_read)) /= to_integer(unsigned(z_data_cmp))) then
				z_errors <= z_errors+ 1;
				write( in2, string'("@ ") );
				write( in2, NOW );
				write( in2, string'(": ") );
				write( in2, Z_NAME );
				write( in2, string'("(") );
				write( in2, z + 1 );	
				write( in2, string'("): ERROR: ") );
				hwrite( in2, z_data_read);
				write( in2, string'(" != ") );
				hwrite( in2, z_data_cmp);
				write( in2, string'(" at address 0x") );
				hwrite( in2, std_logic_vector(to_unsigned(z,32)) );
				write( in2, string'(".") );
				writeline( output, in2 );
			end if;
			wait until(clock = '1');
		end loop;

		file_close(z_file);
		z_read_done <= '1';
		wait;
	end process z_read_process;

	tb_process: process
		variable errors : integer := 0;
		variable warnings : integer := 0;
		variable start_time : time;
		variable end_time: time;
		variable in1, in2, in3, in4 : line;
	begin
		wait until (reset = '1');
		wait until (reset = '0');
		--wait until ((x_write_done= '1') and (y_write_done= '1'));
		wait until (clock = '0');
		wait until (clock = '1');
		start_time := NOW;
		write( in1, string'("@ ") );
		write( in1, start_time);
		write( in1, string'(": Beginning simulation...") );
		writeline( output, in1 );
		
		start <= '1';
		wait until (clock = '0');
		wait until (clock = '1');
		start <= '0';
		wait until  (done = '1');
		
		end_time := NOW;
		write( in2, string'("@ ") );
		write( in2, end_time);
		write( in2, string'(": Simulation completed.") );
		writeline( output, in2 );
	
		wait until (z_read_done = '1');
		errors := z_errors;
		
		write(in3, string'("Total simulation cycle count: "));
		write(in3, (end_time - start_time)/CLOCK_PERIOD);
		writeline(output, in3);
		write(in4, string'("Total error count: "));
		write(in4, errors);
		writeline(output, in4);

		hold_clock <= '1';
		wait;
	end process tb_process;
end architecture behavior;
