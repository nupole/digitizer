library ieee;
use ieee.std_logic_1164.all;

library hdl_event_encoder;

entity event_encoder_tb is
    generic(OUTPUT_REGISTER:                 boolean  := true;
            EVENT_ID_FIFO_DATA_WIDTH:        positive := 4;
            EVENT_TIMESTAMP_FIFO_DATA_WIDTH: positive := 8;
            EVENT_SIZE_FIFO_DATA_WIDTH:      positive := 2;
            EVENT_DATA_FIFO_DATA_WIDTH:      positive := 4;
            EVENT_FIFO_DATA_WIDTH:           positive := 1);
    port(clk:                              in  std_logic;
         rst:                              in  std_logic;
         event_id_fifo_empty:              in  std_logic;
         event_id_fifo_read_enable:        out std_logic;
         event_id_fifo_read_data:          in  std_logic_vector((EVENT_ID_FIFO_DATA_WIDTH-1) downto 0);
         event_timestamp_fifo_empty:       in  std_logic;
         event_timestamp_fifo_read_enable: out std_logic;
         event_timestamp_fifo_read_data:   in  std_logic_vector((EVENT_TIMESTAMP_FIFO_DATA_WIDTH-1) downto 0);
         event_size_fifo_empty:            in  std_logic;
         event_size_fifo_read_enable:      out std_logic;
         event_size_fifo_read_data:        in  std_logic_vector((EVENT_SIZE_FIFO_DATA_WIDTH-1) downto 0);
         event_data_fifo_empty:            in  std_logic;
         event_data_fifo_read_enable:      out std_logic;
         event_data_fifo_read_data:        in  std_logic_vector((EVENT_DATA_FIFO_DATA_WIDTH-1) downto 0);
         event_fifo_write_enable:          out std_logic;
         event_fifo_write_data:            out std_logic_vector((EVENT_FIFO_DATA_WIDTH-1) downto 0));
end entity;

architecture rtl of event_encoder_tb is
begin
    dut: entity hdl_event_encoder.event_encoder generic map(OUTPUT_REGISTER                 => OUTPUT_REGISTER,
                                                            EVENT_ID_FIFO_DATA_WIDTH        => EVENT_ID_FIFO_DATA_WIDTH,
                                                            EVENT_TIMESTAMP_FIFO_DATA_WIDTH => EVENT_TIMESTAMP_FIFO_DATA_WIDTH,
                                                            EVENT_SIZE_FIFO_DATA_WIDTH      => EVENT_SIZE_FIFO_DATA_WIDTH,
                                                            EVENT_DATA_FIFO_DATA_WIDTH      => EVENT_DATA_FIFO_DATA_WIDTH,
                                                            EVENT_FIFO_DATA_WIDTH           => EVENT_FIFO_DATA_WIDTH)
                                                port map(clk                              => clk,
                                                         rst                              => rst,
                                                         event_id_fifo_empty              => event_id_fifo_empty,
                                                         event_id_fifo_read_enable        => event_id_fifo_read_enable,
                                                         event_id_fifo_read_data          => event_id_fifo_read_data,
                                                         event_timestamp_fifo_empty       => event_timestamp_fifo_empty,
                                                         event_timestamp_fifo_read_enable => event_timestamp_fifo_read_enable,
                                                         event_timestamp_fifo_read_data   => event_timestamp_fifo_read_data,
                                                         event_size_fifo_empty            => event_size_fifo_empty,
                                                         event_size_fifo_read_enable      => event_size_fifo_read_enable,
                                                         event_size_fifo_read_data        => event_size_fifo_read_data,
                                                         event_data_fifo_empty            => event_data_fifo_empty,
                                                         event_data_fifo_read_enable      => event_data_fifo_read_enable,
                                                         event_data_fifo_read_data        => event_data_fifo_read_data,
                                                         event_fifo_write_enable          => event_fifo_write_enable,
                                                         event_fifo_write_data            => event_fifo_write_data);
end architecture;
