library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sim is
end entity sim;

architecture BHV of sim is

  component FIR_top is
    generic(clicks_per_baud : integer := 868;
            coeff_1 : signed(8 downto 0) := "000000001";
            coeff_2 : signed(8 downto 0) := "000000001";
            coeff_3 : signed(8 downto 0) := "000000001";
            coeff_4 : signed(8 downto 0) := "000000001");
    port(in_clk     :  in std_logic;
         in_serial  :  in std_logic;
         out_serial : out std_logic;
         out_busy   : out std_logic
        );
  end component FIR_top;

-- clock components
    constant half_cycle : time := 1 ns;
    constant clicks_specifier : integer := 10;
    constant baud_period : time := half_cycle*2*clicks_specifier;
    signal   clock : std_logic := '0';
-- data vector
    constant data1 : signed(7 downto 0) := "00000001";
    constant data2 : signed(7 downto 0) := "00000100";
    constant data3 : signed(7 downto 0) := "00010000";
    constant data4 : signed(7 downto 0) := "01000000";
-- FIR coefficients
    -- constant coeff_1 : signed(8 downto 0) := "000000000";
    -- constant coeff_2 : signed(8 downto 0) := "000000000";
    -- constant coeff_3 : signed(8 downto 0) := "000000000";
    -- constant coeff_4 : signed(8 downto 0) := "000000000";
-- sim component:
    type data is array (3 downto 0) of signed(7 downto 0);
    signal data_arr : data := (data1, data2, data3, data4);
    signal serial_in, serial_out : std_logic := '1';
    signal out_busy, out_end, flag_in : std_logic := '0';
-- :
    procedure UART_WRITE_BYTE (
        i_Data_In       : in  signed(7 downto 0);
        signal o_Serial : out std_logic) is
      begin
    
        -- Send Start Bit
        o_Serial <= '0';
        wait for baud_period;
    
        -- Send Data Byte
        for ii in 0 to 7 loop
          o_Serial <= i_Data_In(ii);
          wait for baud_period;
        end loop;  -- ii
    
        -- Send Stop Bit
        o_Serial <= '1';
        wait for baud_period;
    end UART_WRITE_BYTE;
  begin

    DUT : entity work.FIR_top
      generic map(clicks_per_baud => clicks_specifier)
                  -- coeff_1         => coeff_1,
                  -- coeff_2         => coeff_2,
                  -- coeff_3         => coeff_3,
                  -- coeff_4         => coeff_4
                  -- )
      port map(in_clk => clock,
               in_serial  => serial_in,
               out_serial => serial_out,
               out_busy => out_busy
               );

    clock <= not clock after half_cycle;

    alternate_message : process is
      begin
        send_data : for i in 0 to 3 loop
          UART_WRITE_BYTE(data_arr(i), serial_in);
          wait for half_cycle*10;

        end loop;
        -- UART_WRITE_BYTE(data1, serial_in);
        -- wait for half_cycle*4;
        -- UART_WRITE_BYTE(data2, serial_in);
        -- wait for half_cycle*4;
        -- UART_WRITE_BYTE(data3, serial_in);
        -- wait for half_cycle*4;
        -- UART_WRITE_BYTE(data4, serial_in);
        -- wait for half_cycle*4;

    end process alternate_message;
end architecture BHV;
        