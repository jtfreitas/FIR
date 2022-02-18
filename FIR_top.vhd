library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity FIR_top is
    generic(clicks_per_baud : integer := 868;
            coeff_1 : signed(8 downto 0) := "000000000";
            coeff_2 : signed(8 downto 0) := "000000000";
            coeff_3 : signed(8 downto 0) := "000000000";
            coeff_4 : signed(8 downto 0) := "000000000");
    port(in_clk     :  in std_logic;
         in_serial  :  in std_logic;
         out_serial : out std_logic;
         out_busy   : out std_logic
    );
end entity FIR_top;

architecture top of FIR_top is


    component uart_rx is
        generic(clicks_per_baud : integer);
        port(
            in_clk     : in  std_logic;
            in_serial  : in  std_logic;
            out_val    : out std_logic;
            out_byte   : out signed(7 downto 0)
            );
    end component uart_rx;

    component uart_tx is
        generic(clicks_per_baud : integer);
        port(in_clk     : in  std_logic;
             in_val     : in  std_logic;
             in_byte    : in  signed(7 downto 0);
             out_busy   : out std_logic;
             out_serial : out std_logic;
             end_flag   : out std_logic
             );
    end component uart_tx;

    component fir_filter4 is
        generic(coeff_1 : signed(8 downto 0);
                coeff_2 : signed(8 downto 0);
                coeff_3 : signed(8 downto 0);
                coeff_4 : signed(8 downto 0));
        port(in_clk   : in std_logic;
             data_in  : in signed(7 downto 0);
             in_val   : in std_logic;
             out_val  : out std_logic;
             end_tx   : in std_logic;
             data_out : out signed(7 downto 0)
            );
    end component fir_filter4;
    
    signal rx_val, tx_val, end_tx : std_logic := '0';

    signal fir_in, fir_out : signed(7 downto 0) := (others => '0');
    begin
        rx : uart_rx
            generic map(clicks_per_baud => clicks_per_baud)
            port map(in_clk    => in_clk,
                     out_val   => rx_val,
                     in_serial => in_serial,
                     out_byte  => fir_in);
        
        tx : uart_tx
            generic map(clicks_per_baud => clicks_per_baud)
            port map(in_clk     => in_clk,
                     in_val     => tx_val,
                     in_byte    => fir_out,
                     out_serial => out_serial,
                     out_busy   => out_busy,
                     end_flag   => end_tx);

        FIR : fir_filter4
            generic map(coeff_1 => coeff_1,
                        coeff_2 => coeff_2,
                        coeff_3 => coeff_3,
                        coeff_4 => coeff_4)
            port map(in_clk   => in_clk,
                     data_in  => fir_in,
                     in_val   => rx_val,
                     data_out => fir_out,
                     end_tx   => end_tx,
                     out_val  => tx_val);

end architecture top;
