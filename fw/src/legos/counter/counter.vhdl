library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library hdl_counter;
use hdl_counter.counter_pkg.all;

entity counter is
    generic(COUNT_WIDTH: positive := 8);
    port(clk:         in  std_logic;
         rst:         in  std_logic;
         instruction: in  counter_instruction_struct(operand((COUNT_WIDTH-1) downto 0));
         next_count:  out unsigned((COUNT_WIDTH-1) downto 0);
         count:       out unsigned((COUNT_WIDTH-1) downto 0));
end entity;

architecture rtl of counter is
begin
    next_count <= get_next_count(instruction, count);

    process(clk) begin
        if(rising_edge(clk)) then
            if(rst) then
                count <= (others => '0');
            else
                count <= next_count;
            end if;
        end if;
    end process;
end architecture;
