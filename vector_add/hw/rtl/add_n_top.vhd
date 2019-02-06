library IEEE;
library altera_mf;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use altera_mf.altera_mf_components.all;

entity add_n_top is
port
(
	signal clock : in std_logic;
	signal reset : in std_logic;
	signal start : in std_logic;
	signal done : out std_logic;
	--signal x_wr_addr: in std_logic_vector(5 downto 0);
	--signal x_wr_en: in std_logic_vector(3 downto 0);
	--signal x_din : in std_logic_vector(31 downto 0);
	--signal y_wr_addr : in std_logic_vector(5 downto 0);
	--signal y_wr_en: in std_logic_vector(3 downto 0);
	--signal y_din : in std_logic_vector(31 downto 0);
	signal z_rd_addr : in std_logic_vector(5 downto 0);
	signal z_dout : out std_logic_vector(31 downto 0)
);
end entity add_n_top;

architecture behavior of add_n_top is 
	component add_n
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
	end component;

	signal x_dout : std_logic_vector(31 downto 0);
	signal x_rd_addr : std_logic_vector(5 downto 0);
	signal y_dout : std_logic_vector(31 downto 0);
	signal y_rd_addr : std_logic_vector(5 downto 0);
	signal z_din : std_logic_vector(31 downto 0);
	signal z_wr_addr : std_logic_vector(5 downto 0);
	signal z_wr_en : std_logic;

	begin
		add_n_inst : component add_n
		port map (
			clock => clock,
			reset => reset,
			start => start,
			done => done,
			x_dout => x_dout,
			x_addr => x_rd_addr,
			y_dout => y_dout,
			y_addr => y_rd_addr,
			z_din => z_din,
			z_addr => z_wr_addr,
			z_wr_en => z_wr_en
		);

		x_inst: component altsyncram
		generic map (
			operation_mode => "ROM",
			width_a => 32,
			width_byteena_a => 4,
			widthad_a => 6,
			numwords_a => 64,
			init_file => "x.mif",
			init_file_layout => "PORT_A",
			lpm_type => "altsyncram",
			intended_device_family => "Arria 10",
			clock_enable_input_a => "BYPASS"
		)
		port map (
			address_a => x_rd_addr,
			clock0 => clock,
			clocken0 => '1', 			
			q_a => x_dout,
			aclr0 => '0',
			addressstall_a => '0',
			byteena_a => x"f",
			wren_a => '0'
		);

		y_inst: component altsyncram
		generic map (
			operation_mode => "ROM",
			width_a => 32,
			width_byteena_a => 4,
			widthad_a => 6,
			numwords_a => 64,
			init_file => "y.mif",
			init_file_layout => "PORT_A",
			lpm_type => "altsyncram",
			intended_device_family => "Arria 10",
			clock_enable_input_a => "BYPASS"
		)
		port map (
			address_a => y_rd_addr,
			clock0 => clock,
			clocken0 => '1', 			
			q_a => y_dout,
			aclr0 => '0',
			addressstall_a => '0',
			byteena_a => x"f",
			wren_a => '0'
		);

		z_inst: component altsyncram
		generic map (
			operation_mode => "DUAL_PORT",
			width_a => 32,
			width_byteena_a => 4,
			widthad_a => 6,
			numwords_a => 64,
			width_b => 32,
			width_byteena_b => 4,
			widthad_b => 6,
			numwords_b => 64,
			lpm_type => "altsyncram",
			intended_device_family => "Arria 10",
			clock_enable_input_a => "BYPASS",
			clock_enable_input_b => "BYPASS",
			clock_enable_output_b => "BYPASS",
			outdata_aclr_b => "NONE",
			outdata_reg_b => "CLOCK0",
			address_aclr_b => "NONE",
			address_reg_b => "CLOCK0"
		)
		port map (
			address_a => z_wr_addr,
			clock0 => clock,
			--clocken0 => '1', 			
			data_a => z_din,
			--aclr0 => '0',
			--addressstall_a => '0',
			byteena_a => x"f",
			wren_a => z_wr_en,
			address_b => z_rd_addr,
			q_b => z_dout
		);

end architecture behavior;

