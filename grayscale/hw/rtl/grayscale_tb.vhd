library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity grayscale_tb is
    generic(
        constant IMG_WIDTH : natural := 72;
        constant IMG_HEIGHT: natural := 54;
        constant IMG_FILE_NAME : string(5 downto 1) := "a.bmp";
        constant OUTPUT_FILE_NAME : string(5 downto 1) := "b.bmp";
        constant CLOCK_PERIOD : time := 10 ns
    );
end entity grayscale_tb;

architecture behavior of grayscale_tb is
     --Clock, Reset, Start, Done Signals
    signal clk : std_logic := '1';
    signal rst : std_logic := '0';
    signal start : std_logic := '0';
    signal done : std_logic;

    -- Output Signal
    signal exit_dout : std_logic_vector(23 downto 0);
    signal exit_rd_addr : std_logic_vector(natural(ceil(log2(real(IMG_HEIGHT*IMG_WIDTH))))-1 downto 0);

     -- Process sync signals
    signal hold_clock : std_logic := '0';
    signal start_time, end_time : time;

    -- BMP File
    type array_char is array(0 to 53) of character;
    signal header : array_char;

    -- Grayscale Component
    component grayscale_top is
            generic(
            constant IMG_WIDTH : natural := 72;
            constant IMG_HEIGHT: natural := 54
        );

        port(
            clk             : in std_logic;
            rst             : in std_logic;
            start           : in std_logic;
            done            : out std_logic;

            exit_rd_addr    : in std_logic_vector(natural(ceil(log2(real(IMG_HEIGHT*IMG_WIDTH))))-1 downto 0);
            exit_dout       : out std_logic_vector(23 downto 0)
        );
    end component grayscale_top;

begin

    -- Edge Detect Instance
    dut : grayscale_top
        generic map(
            IMG_WIDTH => IMG_WIDTH,
            IMG_HEIGHT => IMG_HEIGHT
        )
        port map(
            clk             => clk,
            rst             => rst,
            start           => start,
            done            => done,

            exit_rd_addr    => exit_rd_addr,
            exit_dout       => exit_dout
            
        );
    
    -- Clock and Reset Process
    clock_process : process
    begin
        clk <= '1';
        wait for (CLOCK_PERIOD/2);
        clk <= '0';
        wait for (CLOCK_PERIOD/2);
        if (hold_clock = '1') then
            wait;
        end if;
    end process clock_process;

    reset_process : process
    begin
        rst <= '0';
        wait until (clk = '0');
        wait until (clk = '1');
        rst <= '1';
        wait until (clk = '0');
        wait until (clk = '1');
        rst <= '0';
        wait;
    end process reset_process;  

    start_process : process
    begin
        wait until rst = '1';
        wait until rst = '0';
        start <= '1';
        start_time <= NOW;
        wait until (clk = '0');
        wait until (clk = '1');
        start <= '0';
        wait;
    end process start_process; 

    -- Image Header Read Process
    file_read_process : process 
        type raw_file is file of character;
        file img_in_file : raw_file; 
        variable char0 : character;
        variable ii : natural := 0;
    begin
        wait until (rst = '1');
        wait until (rst = '0');
        file_open(img_in_file, IMG_FILE_NAME, read_mode);

        while (ii <= 53) loop
            read(img_in_file, char0);
            header(ii) <=  char0;
            ii := ii + 1;
        end loop;

        file_close(img_in_file);
        wait;
    end process file_read_process; 

    -- Output Image Write Process
    file_write_process : process 
        type raw_file is file of character;
        file img_out_file : raw_file; 
        variable wchar0, wchar1, wchar2 : character;
        variable ii : natural;
        variable pix_count : natural := 0;
    begin
        wait until (rst = '1');
        wait until (rst = '0');
        file_open(img_out_file, OUTPUT_FILE_NAME, write_mode);
        wait until (done = '1');
                    
        while (pix_count <= IMG_HEIGHT*IMG_WIDTH-1) loop
            if (ii <= 53) then
                write(img_out_file, header(ii));
                ii := ii + 1;
            else
                wait until (clk = '0');
                exit_rd_addr <= std_logic_vector(to_unsigned(pix_count, exit_rd_addr'length));
                wait until (clk = '1');
                wait until (clk = '0');

                wchar0 := character'val(to_integer(unsigned(exit_dout(23 downto 16))));
                wchar1 := character'val(to_integer(unsigned(exit_dout(15 downto 8))));
                wchar2 := character'val(to_integer(unsigned(exit_dout(7 downto 0))));
                
                write(img_out_file, wchar0);
                write(img_out_file, wchar1);
                write(img_out_file, wchar2);
    
                pix_count := pix_count + 1;
            end if;
        end loop;

        end_time <= NOW;
        hold_clock <= '1';
        file_close(img_out_file);
        wait;
    end process file_write_process;

end architecture behavior;

