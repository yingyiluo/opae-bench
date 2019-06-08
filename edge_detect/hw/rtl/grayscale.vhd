library ieee;
library altera_mf;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use altera_mf.altera_mf_components.all;

entity grayscale is
    generic(
        constant IMG_WIDTH : natural := 720;
        constant IMG_HEIGHT: natural := 540
    );
    port(
        clk             : in std_logic;
        rst             : in std_logic;
        start           : in std_logic;
        done            : out std_logic;

        pix_in          : in std_logic_vector(23 downto 0);
        pix_addr        : out std_logic_vector(natural(ceil(log2(real(IMG_HEIGHT*IMG_WIDTH))))-1 downto 0);

        gray_out        : out std_logic_vector(7 downto 0);
        buff_out_full   : in std_logic;
        buff_out_wr_en  : out std_logic
    );
end entity grayscale;

architecture behavioral of grayscale is

    type state_type is (S0, S1, S2);
    signal state, state_n : state_type;
    signal done_t, done_n : std_logic;
    signal i, i_n : std_logic_vector(pix_addr'range);

    function rgb2gray(RGB : std_logic_vector(23 downto 0))
        return std_logic_vector is variable val : std_logic_vector(7 downto 0);
        variable R, G, B : std_logic_vector(9 downto 0);
        variable RGB_sum : std_logic_vector(9 downto 0);
    begin
        R := "00" & RGB(23 downto 16);
        G := "00" & RGB(15 downto 8);
        B := "00" & RGB(7 downto 0);

        val := std_logic_vector(resize(((unsigned(R) + unsigned(G) + unsigned(B))/to_unsigned(3, R'length)), val'length));
        return val;
    end function rgb2gray;

begin

    -- Intermediate Signals to Outputs
    done <= done_t;

    -- Sequential Process
    grayscale_seq : process(clk, rst)
    begin
        if (rst = '1') then
            state <= S0;
            i <= (others => '0');
            done_t <= '0';
        elsif (rising_edge(clk)) then
            state <= state_n;
            i <= i_n;
            done_t <= done_n;
        end if;
    end process grayscale_seq;

    -- Grayscale FSM
    grayscale_comb : process(state, done_t, i, pix_in, start, buff_out_full)
    begin
        state_n <= state;
        done_n <= done_t;
        i_n <= i;

        pix_addr <= (others => '0');
        gray_out <= (others => '0');
        buff_out_wr_en <= '0';

        case (state) is
            when S0 => 
                i_n <= (others => '0');
                if (start = '1') then
                    state_n <= S2;
                    done_n <= '0';
                    pix_addr <= i;
                end if;
            
            when S1 =>
                pix_addr <= i;
                state_n <= S2;

            when S2 =>
                if (buff_out_full = '0') then
                    gray_out <= rgb2gray(pix_in);
                    buff_out_wr_en <= '1';
                    i_n <= std_logic_vector(unsigned(i) + to_unsigned(1,i'length));

                    if (unsigned(i) >= to_unsigned(IMG_HEIGHT*IMG_WIDTH-1, i'length)) then
                        done_n <= '1';
                        state_n <= S0;
                    else
                        state_n <= S1;
                    end if;
                end if;
        end case;
    end process grayscale_comb;




end architecture behavioral;