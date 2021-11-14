library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library hdl_dual_port_ram;

entity dual_port_ram_tb is
    generic(OUTPUT_REGISTER: boolean  := true;
            ADDRESS_WIDTH:   positive := 2;
            DATA_WIDTH:      positive := 2);
    port(write_clk:     in  std_logic;
         write_enable:  in  std_logic;
         write_address: in  unsigned((ADDRESS_WIDTH-1) downto 0);
         write_data:    in  std_logic_vector((DATA_WIDTH-1) downto 0);

         read_clk:     in  std_logic;
         read_enable:  in  std_logic;
         read_address: in  unsigned((ADDRESS_WIDTH-1) downto 0);
         read_data:    out std_logic_vector((DATA_WIDTH-1) downto 0));
end entity;

architecture rtl of dual_port_ram_tb is
begin
    dut: entity hdl_dual_port_ram.dual_port_ram generic map(OUTPUT_REGISTER => OUTPUT_REGISTER,
                                                            ADDRESS_WIDTH   => ADDRESS_WIDTH,
                                                            DATA_WIDTH      => DATA_WIDTH)
                                                port map(write_clk     => write_clk,
                                                         write_enable  => write_enable,
                                                         write_address => write_address,
                                                         write_data    => write_data,

                                                         read_clk      => read_clk,
                                                         read_enable   => read_enable,
                                                         read_address  => read_address,
                                                         read_data     => read_data);
end architecture;
