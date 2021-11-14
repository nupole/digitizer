library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dual_port_ram is
    generic(OUTPUT_REGISTER: boolean  := true;
            ADDRESS_WIDTH:   positive := 10;
            DATA_WIDTH:      positive := 8);
    port(write_clk:     in  std_logic;
         write_enable:  in  std_logic;
         write_address: in  unsigned((ADDRESS_WIDTH-1) downto 0);
         write_data:    in  std_logic_vector((DATA_WIDTH-1) downto 0);

         read_clk:     in  std_logic;
         read_enable:  in  std_logic;
         read_address: in  unsigned((ADDRESS_WIDTH-1) downto 0);
         read_data:    out std_logic_vector((DATA_WIDTH-1) downto 0));
end entity;

architecture rtl of dual_port_ram is
    type memory_type is array(0 to ((2**ADDRESS_WIDTH)-1)) of std_logic_vector((DATA_WIDTH-1) downto 0);

    signal ram:         memory_type := (others => (others => '0'));
    signal read_data_r: std_logic_vector((DATA_WIDTH-1) downto 0);
begin
    process(write_clk) begin
        if(rising_edge(write_clk)) then
            if(write_enable) then
                ram(to_integer(write_address)) <= write_data;
            end if;
        end if;
    end process;

    process(read_clk) begin
        if(rising_edge(read_clk)) then
            if(read_enable) then
                read_data_r <= ram(to_integer(read_address));
            end if;
        end if;
    end process;

    GEN_OUTPUT: if(OUTPUT_REGISTER) generate
        process(read_clk) begin
            if(rising_edge(read_clk)) then
                read_data <= read_data_r;
            end if;
        end process;
    else generate
        read_data <= read_data_r;
    end generate;
end architecture;
