library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_counter;
use lib_counter.counter_pkg.all;

entity counter_tb is
    generic(COUNT_WIDTH: positive := 8);
    port(clk:        in  std_logic;
         rst:        in  std_logic;
         opcode:     in  counter_opcode_enum;
         operand:    in  unsigned((COUNT_WIDTH-1) downto 0);
         next_count: out unsigned((COUNT_WIDTH-1) downto 0);
         count:      out unsigned((COUNT_WIDTH-1) downto 0));
end entity;

architecture rtl of counter_tb is
begin
    dut: entity lib_counter.counter generic map(COUNT_WIDTH => COUNT_WIDTH)
                                    port map(clk                 => clk,
                                             rst                 => rst,
                                             instruction.opcode  => opcode,
                                             instruction.operand => operand,
                                             next_count          => next_count,
                                             count               => count);
end architecture;
