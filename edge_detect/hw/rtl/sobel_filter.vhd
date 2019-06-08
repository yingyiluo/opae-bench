library IEEE;
use IEEE.std_logic_1164.all;
--use IEEE.std_logic_arith.all;
use ieee.math_real.all;
use IEEE.numeric_std.all;

entity sobel_filter is
	generic (
		constant N 		: integer := 388800;
		constant COL 	: integer := 720
	);
	port (
		signal clock 	: in std_logic;
		signal reset 	: in std_logic;
		signal start 	: in std_logic;
		signal done 	: out std_logic;
		signal x_dout 	: in std_logic_vector (7 downto 0);
		signal x_empty 	: in std_logic;
		signal x_rd_en 	: out std_logic;
		signal r_din 	: out std_logic_vector (7 downto 0);
		signal r_wr_addr: out std_logic_vector(natural(ceil(log2(real(N))))-1 downto 0);
		signal r_wr_en 	: out std_logic
	);
end entity sobel_filter;

architecture behavior of sobel_filter is 
--varibale declarations
TYPE state_type is (s0,s1,s2,s3);
signal state : state_type;
signal next_state : state_type;
signal done_o, done_c : std_logic;
signal count, count_c : integer;
signal count_x, count_x_c : integer;
signal sf, sf_c: std_logic_vector (7 downto 0);
signal i, i_n : std_logic_vector(natural(ceil(log2(real(N))))-1 downto 0);

--pixel shift register  2*COL+3 elements
type SHREG_INT is array ( 0 to (2*COL+2) ) of integer;
--filter conefficients
type ARRAY_INT_3 is array ( 0 to 2 ) of integer;
type ARRAY_INT_3x3 is array ( 0 to 2 ) of ARRAY_INT_3;

signal horizontal : ARRAY_INT_3x3 := ((-1, 0, 1), (-2, 0, 2), (-1, 0, 1));
signal vertical : ARRAY_INT_3x3 := ((-1, -2, -1), (0, 0, 0), (1, 2, 1));
signal rows : SHREG_INT := (others => 0);

function edge_detect(rows: SHREG_INT; horizontal: ARRAY_INT_3x3; vertical : ARRAY_INT_3x3)
return std_logic_vector is
variable gx : integer;
variable gy : integer;
variable r_int : integer := 0;
variable r : std_logic_vector(7 downto 0) := (others => '0');
begin

-- FSM
gx := 0;
gy := 0;
for i in 0 to 2 loop
	for j in 0 to 2 loop
		gx := gx + horizontal(j)(i) * rows(i*COL+j);
		gy := gy + vertical(j)(i) * rows(i*COL+j);
	end loop;
end loop;
	r_int := (abs(gx) + abs(gy)) / 2;
	r := std_logic_vector(to_unsigned(r_int, r'length));
	return r;
end edge_detect;

begin
sobel_filter_fsm_process : process(x_empty, done_o, start, state, count, i)
--variable rows : SHREG_INT := (others => 0);
begin
r_din <= (others => '0');
done_c <= done_o;
next_state <= state;
count_c <= count;
sf_c <= (others => '0');
x_rd_en <= '0';
count_x_c <= count_x;
i_n <= i;
r_wr_en <= '0';
r_wr_addr <= (others => '0');


case ( state ) is
when s0 =>
	if ( start = '1' ) then
		done_c <= '0';
		next_state <= s1;
	else
		next_state <= s0;
	end if;

when s1 => 
	if(x_empty = '0' and count_x < 2*COL+3) then
		rows(count_x) <= to_integer(unsigned(x_dout));
		x_rd_en <= '1';
		count_x_c <= count_x + 1;
		if(count_x = 2*COL+2) then
			next_state <= s2;
		end if;
	end if;

when s2 =>
	if((count > COL) and count < (N-COL-1)) then
		if(x_empty = '0') then
			for i in 0 to (COL*2 + 1) loop
				rows(i) <= rows(i+1);
			end loop;
			rows(COL*2 + 2) <= to_integer(unsigned(x_dout));
			x_rd_en <= '1';
			--sf_c <= edge_detect(rows);
			next_state <= s3;
		else
			next_state <= s2;
		end if;
	else
		next_state <= s3;
	end if;

when s3 =>
	r_wr_en <= '1';
	r_wr_addr <= i;
	i_n <= std_logic_vector(unsigned(i) + to_unsigned(1,i'length));

	count_c <= count + 1;
	if(count < COL or ((count mod COL) = 0) or ((count mod COL) = (COL - 1)) or (count > (N - COL))) then
		r_din <= (others => '0');
	else
		r_din <= edge_detect(rows, horizontal, vertical);
	end if;
	
	if(count = N - 1) then
		next_state <= s0;
		done_c <= '1';
	else
		next_state <= s2;
	end if;

when OTHERS =>
	r_din <= (others => 'X');
	done_c <= 'X';
	r_wr_en <= 'X';
	next_state <= s0;
end case;
end process sobel_filter_fsm_process;

reg_process : process(reset, clock)
begin
if ( reset = '1' ) then
	state <= s0;
	done_o <= '0';
	count <= 0;
	sf <= (others => '0');
	count_x <= 1;
	i <= (others => '0');
elsif ( rising_edge(clock) ) then
	state <= next_state;
	done_o <= done_c;
	count <= count_c;
	sf <= sf_c;
	count_x <= count_x_c;
	i <= i_n;
end if;
end process reg_process;

done <= done_o;

end architecture behavior;
