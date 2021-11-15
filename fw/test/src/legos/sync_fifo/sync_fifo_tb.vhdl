library ieee;
use ieee.std_logic_1164.all;

library hdl_sync_fifo;

entity sync_fifo_tb is
    generic(OUTPUT_REGISTER:   boolean  := true;
            ADDRESS_WIDTH:     positive := 2;
            DATA_WIDTH:        positive := 2);
    port(clk:          in  std_logic;
         rst:          in  std_logic;
         write_enable: in  std_logic;
         write_error:  out std_logic;
         write_data:   in  std_logic_vector((DATA_WIDTH-1) downto 0);
         read_enable:  in  std_logic;
         read_error:   out std_logic;
         read_data:    out std_logic_vector((DATA_WIDTH-1) downto 0);
         empty:        out std_logic;
         almost_empty: out std_logic;
         almost_full:  out std_logic;
         full:         out std_logic);
end entity;

architecture rtl of sync_fifo_tb is
begin
    dut: entity hdl_sync_fifo.sync_fifo generic map(OUTPUT_REGISTER => OUTPUT_REGISTER,
                                                    ADDRESS_WIDTH   => ADDRESS_WIDTH,
                                                    DATA_WIDTH      => DATA_WIDTH)
                                        port map(clk          => clk,
                                                 rst          => rst,
                                                 write_enable => write_enable,
                                                 write_error  => write_error,
                                                 write_data   => write_data,
                                                 read_enable  => read_enable,
                                                 read_error   => read_error,
                                                 read_data    => read_data,
                                                 empty        => empty,
                                                 almost_empty => almost_empty,
                                                 almost_full  => almost_full,
                                                 full         => full);
end architecture;
