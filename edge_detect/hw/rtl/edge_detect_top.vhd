library ieee;
library altera_mf;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use altera_mf.altera_mf_components.all;

entity edge_detect_top is
    generic(
        constant IMG_WIDTH : natural := 720;
        constant IMG_HEIGHT: natural := 540
    );

    port(
        clk             : in std_logic;
        rst             : in std_logic;
        start           : in std_logic;
        done            : out std_logic;

        exit_rd_addr    : in std_logic_vector(18 downto 0);
        exit_dout       : out std_logic_vector(23 downto 0)
    );
end entity edge_detect_top;

architecture structure of edge_detect_top is

    -- Component Declarations
    component grayscale is
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
    end component grayscale;

    component sobel_filter is
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
    end component sobel_filter;

    component fifo is
        generic(
            constant FIFO_DATA_WIDTH : integer := 32; -- Bits per element 
            constant FIFO_BUFFER_SIZE : integer := 32 -- Number of bytes
        );
        port(
            signal rd_clk : in std_logic;
            signal wr_clk : in std_logic;
            signal reset : in std_logic;
            signal rd_en : in std_logic;
            signal wr_en : in std_logic;
            signal din : in std_logic_vector ((FIFO_DATA_WIDTH - 1) downto 0);
            signal dout : out std_logic_vector ((FIFO_DATA_WIDTH - 1) downto 0);
            signal full : out std_logic;
            signal empty : out std_logic
        );
    end component fifo;

    -- RGB Input BRAM Signals
    signal rgb_rd_addr : std_logic_vector(natural(ceil(log2(real(IMG_HEIGHT*IMG_WIDTH))))-1 downto 0);
    signal rgb_out : std_logic_vector(23 downto 0);

    -- Grayscale Signals
    signal gray_out : std_logic_vector(7 downto 0);
    signal fifogray_rd_en : std_logic;
    signal fifogray_wr_en : std_logic;
    signal fifogray_full  : std_logic;
    signal fifogray_empty : std_logic;
    signal fifogray_out : std_logic_vector(7 downto 0);

    --Exit BRAM Signals
    signal sobel_out : std_logic_vector(7 downto 0);
    signal sobel24_out : std_logic_vector(23 downto 0);
    signal exit_wr_addr : std_logic_vector(natural(ceil(log2(real(IMG_HEIGHT*IMG_WIDTH))))-1 downto 0);
    signal exit_wr_en : std_logic;

begin
---------------------------------------------------------------------------------
   -- RGB Image BRAM
    rgb_bram_inst : component altsyncram
		generic map(
			operation_mode => "ROM",
			width_a => 24,
			widthad_a => 19,
			numwords_a => IMG_HEIGHT*IMG_WIDTH,
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
---------------------------------------------------------------------------------
    -- Grayscale Block
    grayscale_block : grayscale
        generic map(
            IMG_WIDTH       => IMG_WIDTH,
            IMG_HEIGHT      => IMG_HEIGHT
        )
        port map(
            clk             => clk,
            rst             => rst,
            start           => start,

            pix_in          => rgb_out,
            pix_addr        => rgb_rd_addr,

            gray_out        => gray_out,
            buff_out_full   => fifogray_full,
            buff_out_wr_en  => fifogray_wr_en
        );
---------------------------------------------------------------------------------
    -- FIFO
    fifogray : fifo
        generic map(
            FIFO_DATA_WIDTH     => 8,
            FIFO_BUFFER_SIZE    => (128*8)/8
        )
        port map(
            rd_clk              => clk,
            wr_clk              => clk,
            reset               => rst,
            rd_en               => fifogray_rd_en,
            wr_en               => fifogray_wr_en,
            din                 => gray_out,
            dout                => fifogray_out,
            full                => fifogray_full,
            empty               => fifogray_empty
        );
---------------------------------------------------------------------------------
    -- Sobel 
    sobel_block : sobel_filter
        generic map(
            N               => IMG_WIDTH*IMG_HEIGHT,
            COL             => IMG_WIDTH
        )
        port map(
            clock           => clk,
            reset           => rst,
            done            => done,
            start           => start,

            x_dout          => fifogray_out,
            x_empty         => fifogray_empty,
            x_rd_en         => fifogray_rd_en,

            r_din           => sobel_out,
            r_wr_addr       => exit_wr_addr,
            r_wr_en         => exit_wr_en
        );    

---------------------------------------------------------------------------------    
    -- Processed Image BRAM
    exit_bram_inst : component altsyncram
		generic map (
			operation_mode => "DUAL_PORT",
			width_a => 24,
			width_byteena_a => 3,
			widthad_a => 19,
			numwords_a => IMG_HEIGHT*IMG_WIDTH,
			width_b => 24,
			width_byteena_b => 3,
			widthad_b => 19,
			numwords_b => IMG_HEIGHT*IMG_WIDTH,
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
			data_a => sobel24_out,
			wren_a => exit_wr_en,
			address_b => exit_rd_addr,
			q_b => exit_dout
		);

    sobel24_out <= sobel_out & sobel_out & sobel_out;
            
end architecture structure;
