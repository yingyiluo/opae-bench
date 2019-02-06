library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity add_n is
port 
(
	signal clock : in std_logic;
	signal reset : in std_logic;
	signal start : in std_logic;
	signal done : out std_logic;
	signal x_dout: in std_logic_vector(31 downto 0);
	signal x_addr: out std_logic_vector(5 downto 0);
	signal y_dout: in std_logic_vector(31 downto 0);
	signal y_addr: out std_logic_vector(5 downto 0);
	signal z_din: out std_logic_vector(31 downto 0);
	signal z_addr: out std_logic_vector(5 downto 0);
	signal z_wr_en: out std_logic
);
end entity add_n;

architecture behavior of add_n is
	TYPE state_type is (s0, s1, s2);
	signal state, next_state : state_type;
	signal i, i_c : std_logic_vector(5 downto 0);
	signal done_o, done_c : std_logic;
begin
	add_n_fsm_process : process(state, y_dout, x_dout, i, done_o, start)
	begin
		z_din <= X"00000000";
		z_wr_en <= '0';
		z_addr <= (others => '0');
		x_addr <= (others => '0');
		y_addr <= (others => '0');
		i_c <= i;
		done_c <= done_o;
		next_state <= state;

		case(state) is
		when s0 =>
			i_c <= (others => '0');
			if(start = '1') then
				done_c <= '0';
				next_state <= s1;
			end if;
		when s1 =>
			x_addr <= i;
			y_addr <= i;
			next_state <= s2;
		when s2 =>
			z_din <= std_logic_vector(signed(y_dout) + signed(x_dout));
			z_addr <= i;
			z_wr_en <= '1';
			i_c <= std_logic_vector(unsigned(i) + to_unsigned(1,6));
			if(unsigned(i) >= to_unsigned(63, 6)) then
				done_c <= '1';
				next_state <= s0;
			else
				next_state <= s1;
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
	end process add_n_fsm_process;

	add_n_reg_process: process(reset, clock)
	begin
		if(reset = '1') then
			state <= s0;
			i <= (others => '0');
			done_o <= done_c;
		elsif(rising_edge(clock)) then
			state <= next_state;
			i <= i_c;
			done_o <= done_c;
		end if;
	end process add_n_reg_process;

	done <= done_o;
end architecture behavior;
