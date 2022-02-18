library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_rx is
    generic (clicks_per_baud : integer := 868);
    port(
        in_clk     : in  std_logic;
        in_serial  : in  std_logic;
        out_val    : out std_logic;
        out_byte   : out signed(7 downto 0)
        );
end entity uart_rx;

architecture RTL of uart_rx is
    --state machine
    type rx_SM is (s_idle, start_rx, data_rx, stop_rx, s_reset);
    --register signals
    signal reg_main_SM : rx_SM := s_idle;
    signal reg_rx_byte : signed(7 downto 0) := (others => '0');
    signal reg_out_val : std_logic := '0';

begin

    rx_process : process(in_clk)
    variable clk_count  : integer range 0 to (clicks_per_baud-1) := 0;
    variable data_bauds : integer range 0 to 7 := 0;
    begin
        if rising_edge(in_clk) then
            case reg_main_SM is
                when s_idle =>
                    reg_out_val <= '0';
                    clk_count   := 0;
                    data_bauds  := 0;

                    if (in_serial = '0') then -- detecting start bit
                        reg_main_SM <= start_rx;
                    else
                        reg_main_SM <= s_idle;
                    end if;
                
                when start_rx =>
                    if (clk_count = ((clicks_per_baud-1)/2)) then --scan at half baud
                        if (in_serial = '0') then                 --it will delay all subsequent bauds
                            clk_count := 0;
                            reg_main_SM <= data_rx;
                        else
                            reg_main_SM <= s_idle;
                        end if;
                    else
                        clk_count   := clk_count + 1;
                        reg_main_SM <= start_rx;
                    end if;

                when data_rx =>
                    if (clk_count < clicks_per_baud-1) then
                        clk_count := clk_count + 1;
                        reg_main_SM <= data_rx;
                    else
                        clk_count := 0;
                        reg_rx_byte(data_bauds) <= in_serial;
                        if (data_bauds < 7) then
                            data_bauds := data_bauds + 1;
                            reg_main_SM <= data_rx;
                        else
                            data_bauds := 0;
                            reg_main_SM <= stop_rx;
                        end if;
                    end if;

                when stop_rx =>
                    if (clk_count < clicks_per_baud-1) then
                        clk_count := clk_count + 1;
                        reg_main_SM <= stop_rx;
                    else
                        reg_out_val <= '1';
                        clk_count := 0;
                        reg_main_SM <= s_reset;
                    end if;
                
                when s_reset =>
                    reg_main_SM <= s_idle;
                    reg_out_val <= '0';
                
                when others =>
                    reg_main_SM <= s_idle;
                end case;
            end if;
            out_val <= reg_out_val;
            out_byte <= reg_rx_byte;
    end process rx_process;
end architecture RTL;