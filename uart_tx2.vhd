library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tx is
    generic(clicks_per_baud : integer := 868); 
    port(in_clk     : in  std_logic;
         in_val     : in  std_logic;
         in_byte    : in  signed(7 downto 0);
         out_busy   : out std_logic;
         out_serial : out std_logic;
         end_flag   : out std_logic
         );
end entity uart_tx;

architecture RTL of uart_tx is
    -- state machine
    type tx_SM is (s_idle, start_tx, data_tx, stop_tx, s_reset);
    -- register signals
    signal reg_main_SM : tx_SM := s_idle; -- set initial state to idle
    signal reg_tx_byte  : signed(7 downto 0); -- register message
    signal reg_end_flag : std_logic := '0';

begin -- tx architecture
    
    tx_process : process(in_clk)
    variable clk_count  : integer range 0 to (clicks_per_baud-1) := 0; --track clicks.
    variable data_bauds : integer range 0 to 7 := 0; --track baud pulses during data tx phase.
    begin
        if rising_edge(in_clk) then
            case reg_main_SM is
                when s_idle =>
                    out_busy <= '0';
                    out_serial <= '1'; --output idle - high
                    reg_end_flag <= '0';
                    clk_count := 0;
                    data_bauds := 0;

                    if (in_val = '1') then -- validation is high, data incoming.
                        reg_tx_byte <= in_byte;
                        reg_main_SM <= start_tx;
                    else
                        reg_main_SM <= s_idle;
                    end if;
                
                when start_tx =>
                    out_busy <= '1';
                    out_serial <= '0'; --output start bit - low
                    if (clk_count = (clicks_per_baud-1)) then -- move to tx phase after one baud
                        reg_main_SM <= data_tx;
                        clk_count := 0;
                    else 
                        clk_count := clk_count + 1;
                        reg_main_SM <= start_tx;
                    end if;
                
                when data_tx =>
                    out_serial <= in_byte(data_bauds); -- set output to bit corresponding to baud count
                    if (clk_count < (clicks_per_baud-1)) then
                        clk_count := clk_count + 1;
                        reg_main_SM <= data_tx;
                    else
                        clk_count := 0;
                        if (data_bauds < 7) then
                            data_bauds := data_bauds + 1;
                            reg_main_SM <= data_tx;
                        else -- when reaching 8 bauds, move to stop phase
                            data_bauds := 0;
                            reg_main_SM <= stop_tx;
                        end if;
                    end if;
                
                when stop_tx =>
                    out_serial <= '1';
                    if (clk_count < (clicks_per_baud-1)) then  
                        clk_count := clk_count +1;
                        reg_main_SM <= stop_tx;
                    else -- after one baud, rise end flag, 
                        clk_count := 0;
                        reg_end_flag <='1';
                        reg_main_SM <= s_reset;
                    end if;
                when s_reset =>
                    out_busy <= '0';
                    reg_main_SM <= s_idle;

                when others =>
                    reg_main_SM <= s_idle;
            end case;
        end if;
        end_flag <= reg_end_flag;
    end process tx_process;
    
end architecture RTL;