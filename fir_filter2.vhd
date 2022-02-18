library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fir_filter4 is
    generic(coeff_1, coeff_2, coeff_3, coeff_4 : signed(8 downto 0));
    port(in_clk   : in std_logic;
         data_in  : in signed(7 downto 0);
         in_val   : in std_logic;
         out_val  : out std_logic;
         data_out : out signed(7 downto 0);
         end_tx   : in std_logic
         );
end entity fir_filter4;

architecture RTL of fir_filter4 is

    constant coeff1 : signed(8 downto 0) := coeff_1;
    constant coeff2 : signed(8 downto 0) := coeff_2;
    constant coeff3 : signed(8 downto 0) := coeff_3;
    constant coeff4 : signed(8 downto 0) := coeff_4;
    
    -- signal in_data : signed(7 downto 0);

    type memory_in  is array (3 downto 0) of signed(7 downto 0);-- := (others => '00000000');
    type memory_out is array (3 downto 0) of signed(7 downto 0);-- := (others => '00000000');
    type mem_state  is (s_rx, s_apply, s_tx, s_reset);
    signal reg_mem_state : mem_state := s_reset;
    signal reg_mem_in : memory_in;
    signal reg_mem_out : memory_out;

    -- performs the FIR filter arithmetic
    procedure apply_FIR (
        signal x_in : in memory_in;
        signal y_out : out memory_out
    ) is
        type temp_prod is array (9 downto 0) of signed(16 downto 0);-- := (others => '0000000000000000000');
        variable prods : temp_prod;-- := (others => '00000000000000000');
        type temp_ys is array (3 downto 0) of signed(19 downto 0);-- := (others => '0000000000000000000');
        variable temp_y : temp_ys;
        begin
            --products:
            prods(0) := x_in(0)*coeff1;
            prods(1) := x_in(1)*coeff1;
            prods(2) := x_in(2)*coeff1;
            prods(3) := x_in(3)*coeff1;
            prods(4) := x_in(0)*coeff2;
            prods(5) := x_in(1)*coeff2;
            prods(6) := x_in(2)*coeff2;
            prods(7) := x_in(0)*coeff3;
            prods(8) := x_in(1)*coeff3;
            prods(9) := x_in(0)*coeff4;

            temp_y(0) := resize(prods(0), 19);
            temp_y(1) := resize(prods(1), 19) + resize(prods(4), 19);
            temp_y(2) := resize(prods(2), 19) + resize(prods(5), 19) + resize(prods(7), 19);
            temp_y(3) := resize(prods(3), 19) + resize(prods(6), 19) + resize(prods(8), 19) + resize(prods(9), 19);

            y_out(0) <= resize(shift_right(temp_y(0), 11), 8);
            y_out(1) <= resize(shift_right(temp_y(1), 11), 8);
            y_out(2) <= resize(shift_right(temp_y(2), 11), 8);
            y_out(3) <= resize(shift_right(temp_y(3), 11), 8);
        end apply_FIR;

    begin
    FIR : process(in_clk) is
        variable rx_count : integer range 0 to 4 := 0;
        variable tx_count : integer range 0 to 4 := 0;
        begin
            if rising_edge(in_clk) then
                case reg_mem_state is
                    when s_rx =>
                        if (rx_count < 4) then
                            if (in_val = '1') then
                                reg_mem_in(rx_count) <= data_in;
                                rx_count := rx_count + 1;
                                reg_mem_state <= s_rx;
                            else
                                reg_mem_state <= s_rx;
                            end if;
                        else
                            rx_count := 0;
                            reg_mem_state <= s_apply;
                        end if;
                    when s_apply =>
                        apply_FIR(reg_mem_in, reg_mem_out);
                        reg_mem_state <= s_tx;
                        out_val <= '1';
                    when s_tx =>
                        if (tx_count < 4) then
                            if (end_tx = '0') then
                                data_out <= reg_mem_out(tx_count);
                            elsif (end_tx = '1') then
                                tx_count := tx_count + 1;
                            end if;
                            reg_mem_state <= s_tx;
                        else
                            if (end_tx = '1') then
                                reg_mem_state <= s_reset;
                            end if;
                        end if;

                    when s_reset =>
                        reg_mem_in  <= (others => "00000000");
                        reg_mem_out <= (others => "00000000");
                        reg_mem_state <= s_rx;
                end case;
            end if;
        end process FIR;
end architecture RTL;