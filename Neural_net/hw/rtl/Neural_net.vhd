library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Neural_net is
generic
(
	constant W      : integer:= 8;
	constant H      : integer:= 8;
	constant threshold_one : integer := 150;
	constant threshold_two : integer := 20000;
	constant threshold_three : integer := 80000 
);
port 
(
	signal clock : in std_logic;
	signal reset : in std_logic;
	signal start : in std_logic;
	signal done : out std_logic;
	signal x_dout: in std_logic_vector(7 downto 0);
	signal x_addr: out std_logic_vector(5 downto 0);
	signal y_dout: in std_logic_vector(7 downto 0);
	signal y_addr: out std_logic_vector(5 downto 0);
	signal z_din: out std_logic_vector(31 downto 0);
	signal z_addr: out std_logic_vector(5 downto 0);
	signal z_wr_en: out std_logic
);
end entity Neural_net;

architecture behavior of Neural_net is
	TYPE state_type is (s0, s1, s2, s3);
	signal state, next_state : state_type;
	signal i, i_c, j, j_c : std_logic_vector(5 downto 0);
	signal done_o, done_c : std_logic;
	signal x, x_c, y, y_c : integer;

     TYPE matrix is array(0 to (H*W - 1)) of integer;
     TYPE node_array is array (0 to (H - 1)) of integer;
     signal M_weight : matrix;
     signal Node_in,Node_out : node_array; 
     signal temp : integer;
     
begin
Neural_fsm_process : 
        process(state, y_dout, x_dout, i, j, done_o, start)

variable Mul,Sum,M_dout,temp_out  : integer;
	begin
		z_din <= X"00000000";
		z_wr_en <= '0';
		i_c <= i;
		j_c <= j;
		done_c <= done_o;
		next_state <= state;
		
		case(state) is
		when s0 =>
			
			z_addr <= (others => '0');
			x_addr <= (others => '0');
			y_addr <= (others => '0');
			M_weight <= (others => 0);
			Node_in <= (others => 0);
			Node_out <= (others => 0);
			i_c <= (others => '0');
			j_c <= (others => '0');
			x_c <= 0;
                        y_c <= 0;
			if(start = '1') then
				done_c <= '0';
				next_state <= s1;
			end if;
		when s1 =>
			x_addr <= i;
			if( to_integer(unsigned(i)) < H) then
			y_addr <= i;
			--Node_in(x) <= to_integer(unsigned(y_dout));
			end if;
			next_state <= s2;
		when s2 =>
			if( to_integer(unsigned(i)) < (W*H)) then
			z_wr_en <= '0';
			--x_addr <= i;
			
			i_c <= std_logic_vector(unsigned(i) + to_unsigned(1,6));
			M_weight(x + W*y) <= to_integer(unsigned(x_dout));
			if( to_integer(unsigned(i)) < H) then
			--y_addr <= i;
			Node_in(x) <= to_integer(unsigned(y_dout));
			end if;
			x_c <= x + 1;
			next_state <= s1;
			if (x = (W -1) ) then
				x_c <= 0;
                          	y_c <= y + 1;
				
			end if;
			if((x = (W - 1)) AND (y = (H - 1))) then
				x_c <= 0;
				y_c <= 0;
				next_state <= s3;
			end if;
			end if;
		when s3 =>
		     if (to_integer(unsigned(j)) < H) then
			z_addr <= j;
			j_c <= std_logic_vector(unsigned(j) + to_unsigned(1,6));
			Sum := 0;
		     for t in 0 to 7 loop
			if(Node_in(t) > threshold_one) then
			Mul := M_weight(t + 8*y)*Node_in(t);
			Sum := Sum + Mul;
			end if;
		     end loop;
			M_dout := Sum;
			Node_out(y) <= M_dout;
             		if(M_dout > threshold_two) then
			z_din <= std_logic_vector(to_unsigned(M_dout, 32));
			else
			z_din <= (others => '0');
			end if;
			z_wr_en <= '1';
			y_c <= y + 1;
		     elsif (to_integer(unsigned(j)) = H) then
			z_addr <= j;
			j_c <= std_logic_vector(unsigned(j) + to_unsigned(1,6));
			temp_out := 0;
			for k in 0 to 7 loop
			if(Node_out(k) > threshold_two) then
			temp_out := temp_out + Node_out(k);
			end if;
		     	end loop;
			if (temp_out > threshold_three)then
			z_din <= std_logic_vector(to_unsigned(1, 32));
			else
			z_din <= std_logic_vector(to_unsigned(0, 32));
			end if;
			z_wr_en <= '1';
			done_c <= '1';
			x_c <= 0;
			y_c <= 0;
			
		     end if;
		
		when OTHERS =>
			z_din <= (others => 'X');
			z_wr_en <= 'X';
			z_addr <= (others => 'X');
			x_addr <= (others => 'X');
			y_addr <= (others => 'X');
			i_c <= (others => 'X');
			done_c <= 'X';
			next_state <= s0;
		end case;
	end process Neural_fsm_process;

	Neural_reg_process: process(reset, clock)
	begin
		if(reset = '1') then
			state <= s0;
			i <= (others => '0');
			j <= (others => '0');
			x <= 0;
			y <= 0;
			done_o <= done_c;
		elsif(rising_edge(clock)) then
			state <= next_state;
			x <= x_c;
                        y <= y_c;
			i <= i_c;
			j <= j_c;
			done_o <= done_c;
		end if;
	end process Neural_reg_process;

	done <= done_o;
end architecture behavior;