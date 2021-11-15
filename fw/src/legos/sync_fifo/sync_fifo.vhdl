library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library hdl_counter;
use hdl_counter.counter_pkg.all;

library hdl_dual_port_ram;

entity sync_fifo is
    generic(OUTPUT_REGISTER:   boolean  := true;
            ADDRESS_WIDTH:     positive := 10;
            ALMOST_EMPTY_SIZE: positive := 1;
            ALMOST_FULL_SIZE:  positive := ((2**ADDRESS_WIDTH)-1);
            DATA_WIDTH:        positive := 8);
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

architecture rtl of sync_fifo is
    signal write_pointer_opcode_c: counter_opcode_enum;
    signal read_pointer_opcode_c:  counter_opcode_enum;

    signal next_write_pointer_c: unsigned(ADDRESS_WIDTH downto 0);
    signal write_pointer_r:      unsigned(ADDRESS_WIDTH downto 0);
    signal next_read_pointer_c:  unsigned(ADDRESS_WIDTH downto 0);
    signal read_pointer_r:       unsigned(ADDRESS_WIDTH downto 0);

    signal write_error_c:  std_logic;
    signal read_error_c:   std_logic;

    signal empty_c:        std_logic;
    signal almost_empty_c: std_logic;
    signal almost_full_c:  std_logic;
    signal full_c:         std_logic;
begin
    write_pointer_opcode_c <= COUNTER_OPCODE_INCR when (write_enable and (read_enable or (not full))) else COUNTER_OPCODE_NOOP;

    write_pointer: entity hdl_counter.counter generic map(COUNT_WIDTH => (ADDRESS_WIDTH + 1))
                                              port map(clk                 => clk,
                                                       rst                 => rst,
                                                       instruction.opcode  => write_pointer_opcode_c,
                                                       instruction.operand => (others => '0'),
                                                       next_count          => next_write_pointer_c,
                                                       count               => write_pointer_r);

    read_pointer_opcode_c <= COUNTER_OPCODE_INCR when (read_enable and (not empty)) else COUNTER_OPCODE_NOOP;

    read_pointer: entity hdl_counter.counter generic map(COUNT_WIDTH => (ADDRESS_WIDTH + 1))
                                             port map(clk                 => clk,
                                                      rst                 => rst,
                                                      instruction.opcode  => read_pointer_opcode_c,
                                                      instruction.operand => (others => '0'),
                                                      next_count          => next_read_pointer_c,
                                                      count               => read_pointer_r);

    write_error_c  <= '1' when (write_enable and (not read_enable) and full) else '0';
    read_error_c   <= '1' when (read_enable and empty) else '0';

    empty_c        <= '1' when (next_write_pointer_c = next_read_pointer_c) else '0';
    almost_empty_c <= '1' when (to_integer(next_write_pointer_c - next_read_pointer_c) < (ALMOST_EMPTY_SIZE + 1)) else '0';
    almost_full_c  <= '1' when (to_integer(next_write_pointer_c - next_read_pointer_c) > (ALMOST_FULL_SIZE - 1)) else '0';
    full_c         <= '1' when ((next_write_pointer_c(ADDRESS_WIDTH) /= next_read_pointer_c(ADDRESS_WIDTH)) and
                                (next_write_pointer_c((ADDRESS_WIDTH-1) downto 0) = next_read_pointer_c((ADDRESS_WIDTH-1) downto 0))) else '0';

    process(clk) begin
        if(rising_edge(clk)) then
            if(rst) then
                write_error  <= '0';
                read_error   <= '0';
                empty        <= '1';
                almost_empty <= '1';
                almost_full  <= '0';
                full         <= '0';
            else
                write_error  <= write_error_c;
                read_error   <= read_error_c;
                empty        <= empty_c;
                almost_empty <= almost_empty_c;
                almost_full  <= almost_full_c;
                full         <= full_c;
            end if;
        end if;
    end process;

    ram: entity hdl_dual_port_ram.dual_port_ram generic map(OUTPUT_REGISTER => OUTPUT_REGISTER,
                                                            ADDRESS_WIDTH   => ADDRESS_WIDTH,
                                                            DATA_WIDTH      => DATA_WIDTH)
                                                port map(write_clk     => clk,
                                                         write_enable  => (read_enable or (not full)),
                                                         write_address => write_pointer_r((ADDRESS_WIDTH-1) downto 0),
                                                         write_data    => write_data,

                                                         read_clk      => clk,
                                                         read_enable   => '1',
                                                         read_address  => read_pointer_r((ADDRESS_WIDTH-1) downto 0),
                                                         read_data     => read_data);
end architecture;
