library ieee;
library altera_mf;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use altera_mf.altera_mf_components.all;

entity grayscale_top is
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
end entity grayscale_top;

architecture structure of grayscale_top is

    -- Component Declarations
    component grayscale is
        generic(
            constant IMG_WIDTH : natural := 72;
            constant IMG_HEIGHT: natural := 54
        );
        port(
            clk             : in std_logic;
            rst             : in std_logic;
            start           : in std_logic;
            done            : out std_logic;

            pix_in          : in std_logic_vector(23 downto 0);
            pix_addr        : out std_logic_vector(natural(ceil(log2(real(IMG_HEIGHT*IMG_WIDTH))))-1 downto 0);

            gray_out        : out std_logic_vector(7 downto 0);
            gray_addr       : out std_logic_vector(natural(ceil(log2(real(IMG_HEIGHT*IMG_WIDTH))))-1 downto 0);
            gray_wr_en      : out std_logic 
        );
    end component grayscale;

    -- RGB Input BRAM Signals
    signal rgb_rd_addr : std_logic_vector(natural(ceil(log2(real(IMG_HEIGHT*IMG_WIDTH))))-1 downto 0);
    signal rgb_out : std_logic_vector(23 downto 0);

    --Exit BRAM Signals
    signal gray_out : std_logic_vector(7 downto 0);
    signal gray24_out : std_logic_vector(23 downto 0);
    signal exit_wr_addr : std_logic_vector(natural(ceil(log2(real(IMG_HEIGHT*IMG_WIDTH))))-1 downto 0);
    signal exit_wr_en : std_logic;

begin

    -- RGB Image BRAM
    rgb_bram_inst : component altsyncram
		generic map(
			operation_mode => "ROM",
			width_a => 24,
			widthad_a => 12, --19,
			numwords_a => 3888,--388800,
			init_file => "a.mif",
			init_file_layout => "PORT_A",
			lpm_type => "altsyncram",
			intended_device_family => "Arria 10", --"Cyclone IV", 
			clock_enable_input_a => "BYPASS"
		)
		port map(
            clock0 => clk,	
			address_a => rgb_rd_addr,	
			q_a => rgb_out,
			wren_a => '0',
            aclr0 => '0',
			addressstall_a => '0'
		);


    -- Grayscale Block
    grayscale_block : grayscale
        generic map(
            IMG_WIDTH => IMG_WIDTH,
            IMG_HEIGHT => IMG_HEIGHT
        )
        port map(
            clk => clk,
            rst => rst,
            start => start,
            done => done,
            pix_in => rgb_out,
            pix_addr => rgb_rd_addr,
            gray_out => gray_out,
            gray_addr => exit_wr_addr,
            gray_wr_en => exit_wr_en
        );

    -- Processed Image BRAM
    exit_bram_inst : component altsyncram
		generic map (
			operation_mode => "DUAL_PORT",
			width_a => 24,
			width_byteena_a => 3,
			widthad_a => 12, --19,
			numwords_a => 3888,--388800,
			width_b => 24,
			width_byteena_b => 3,
			widthad_b => 12, --19,
			numwords_b => 3888,--388800,
			lpm_type => "altsyncram",
			intended_device_family => "Arria 10", --"Cyclone IV", 
			clock_enable_input_a => "BYPASS",
			clock_enable_input_b => "BYPASS",
			clock_enable_output_b => "BYPASS",
			outdata_aclr_b => "NONE",
			outdata_reg_b => "CLOCK0",
			address_aclr_b => "NONE",
			address_reg_b => "CLOCK0"
		)
		port map (
            clock0 => clk, 
			address_a => exit_wr_addr,			
			data_a => gray24_out,
			wren_a => exit_wr_en,
			address_b => exit_rd_addr,
			q_b => exit_dout
		);

    gray24_out <= gray_out & gray_out & gray_out;
            
end architecture structure;