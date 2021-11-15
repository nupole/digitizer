library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library hdl_math;
use hdl_math.math_pkg.all;

library hdl_types;
use hdl_types.types_pkg.all;

library hdl_counter;
use hdl_counter.counter_pkg.all;

library hdl_event_encoder;
use hdl_event_encoder.event_encoder_pkg.all;

entity event_encoder is
    generic(OUTPUT_REGISTER:                 boolean  := true;
            EVENT_ID_FIFO_DATA_WIDTH:        positive := 32;
            EVENT_TIMESTAMP_FIFO_DATA_WIDTH: positive := 64;
            EVENT_SIZE_FIFO_DATA_WIDTH:      positive := 16;
            EVENT_DATA_FIFO_DATA_WIDTH:      positive := 32;
            EVENT_FIFO_DATA_WIDTH:           positive := 8);
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

architecture rtl of event_encoder is
    constant NUMBER_EVENT_ID_WRITES:               positive := EVENT_ID_FIFO_DATA_WIDTH / EVENT_FIFO_DATA_WIDTH;
    constant LOG_NUMBER_EVENT_ID_WRITES:           positive := log2(NUMBER_EVENT_ID_WRITES);
    constant NUMBER_EVENT_TIMESTAMP_WRITES:        positive := EVENT_TIMESTAMP_FIFO_DATA_WIDTH / EVENT_FIFO_DATA_WIDTH;
    constant LOG_NUMBER_EVENT_TIMESTAMP_WRITES:    positive := log2(NUMBER_EVENT_TIMESTAMP_WRITES);
    constant NUMBER_EVENT_SIZE_WRITES:             positive := EVENT_SIZE_FIFO_DATA_WIDTH / EVENT_FIFO_DATA_WIDTH;
    constant LOG_NUMBER_EVENT_SIZE_WRITES:         positive := log2(NUMBER_EVENT_SIZE_WRITES);
    constant NUMBER_EVENT_DATA_WRITES:             positive := EVENT_DATA_FIFO_DATA_WIDTH / EVENT_FIFO_DATA_WIDTH;
    constant LOG_NUMBER_EVENT_DATA_WRITES:         positive := log2(NUMBER_EVENT_DATA_WRITES);

    signal number_event_id_writes_opcode_c:        counter_opcode_enum;
    signal number_event_id_writes_r:               unsigned((LOG_NUMBER_EVENT_ID_WRITES-1) downto 0);
    signal event_id_words:                         array_std_logic_vector_type(0 to (NUMBER_EVENT_ID_WRITES-1))((EVENT_FIFO_DATA_WIDTH-1) downto 0);

    signal number_event_timestamp_writes_opcode_c: counter_opcode_enum;
    signal number_event_timestamp_writes_r:        unsigned((LOG_NUMBER_EVENT_TIMESTAMP_WRITES-1) downto 0);
    signal event_timestamp_words:                  array_std_logic_vector_type(0 to (NUMBER_EVENT_TIMESTAMP_WRITES-1))((EVENT_FIFO_DATA_WIDTH-1) downto 0);

    signal number_event_size_writes_opcode_c:      counter_opcode_enum;
    signal number_event_size_writes_r:             unsigned((LOG_NUMBER_EVENT_SIZE_WRITES-1) downto 0);
    signal event_size_words:                       array_std_logic_vector_type(0 to (NUMBER_EVENT_SIZE_WRITES-1))((EVENT_FIFO_DATA_WIDTH-1) downto 0);

    signal number_event_data_writes_opcode_c:      counter_opcode_enum;
    signal number_event_data_writes_r:             unsigned((LOG_NUMBER_EVENT_DATA_WRITES-1) downto 0);
    signal event_data_words:                       array_std_logic_vector_type(0 to (NUMBER_EVENT_DATA_WRITES-1))((EVENT_FIFO_DATA_WIDTH-1) downto 0);

    signal event_fifo_write_enable_c:              std_logic;
    signal event_fifo_write_enable_r:              std_logic;
    signal event_fifo_write_data_c:                std_logic_vector((EVENT_FIFO_DATA_WIDTH-1) downto 0);
    signal event_fifo_write_data_r:                std_logic_vector((EVENT_FIFO_DATA_WIDTH-1) downto 0);

    signal state_c:                                event_encoder_state_enum;
    signal state_r:                                event_encoder_state_enum := EVENT_ENCODER_STATE_IDLE;
begin
    number_event_id_writes_counter: entity hdl_counter.counter generic map(COUNT_WIDTH => LOG_NUMBER_EVENT_ID_WRITES)
                                                               port map(clk                 => clk,
                                                                        rst                 => rst,
                                                                        instruction.opcode  => number_event_id_writes_opcode_c,
                                                                        instruction.operand => (others => '0'),
                                                                        next_count          => open,
                                                                        count               => number_event_id_writes_r);

    number_event_timestamp_writes_counter: entity hdl_counter.counter generic map(COUNT_WIDTH => LOG_NUMBER_EVENT_TIMESTAMP_WRITES)
                                                                      port map(clk                 => clk,
                                                                               rst                 => rst,
                                                                               instruction.opcode  => number_event_timestamp_writes_opcode_c,
                                                                               instruction.operand => (others => '0'),
                                                                               next_count          => open,
                                                                               count               => number_event_timestamp_writes_r);

    number_event_size_writes_counter: entity hdl_counter.counter generic map(COUNT_WIDTH => LOG_NUMBER_EVENT_SIZE_WRITES)
                                                                 port map(clk                 => clk,
                                                                          rst                 => rst,
                                                                          instruction.opcode  => number_event_size_writes_opcode_c,
                                                                          instruction.operand => (others => '0'),
                                                                          next_count          => open,
                                                                          count               => number_event_size_writes_r);

    number_event_data_writes_counter: entity hdl_counter.counter generic map(COUNT_WIDTH => LOG_NUMBER_EVENT_DATA_WRITES)
                                                                 port map(clk                 => clk,
                                                                          rst                 => rst,
                                                                          instruction.opcode  => number_event_data_writes_opcode_c,
                                                                          instruction.operand => (others => '0'),
                                                                          next_count          => open,
                                                                          count               => number_event_data_writes_r);

    process(all) begin
        number_event_id_writes_opcode_c                <= COUNTER_OPCODE_NOOP;
        event_id_words                                 <= to_words(NUMBER_EVENT_ID_WRITES,
                                                                   EVENT_FIFO_DATA_WIDTH,
                                                                   event_id_fifo_read_data);
        number_event_timestamp_writes_opcode_c         <= COUNTER_OPCODE_NOOP;
        event_timestamp_words                          <= to_words(NUMBER_EVENT_TIMESTAMP_WRITES,
                                                                   EVENT_FIFO_DATA_WIDTH,
                                                                   event_timestamp_fifo_read_data);
        number_event_size_writes_opcode_c              <= COUNTER_OPCODE_NOOP;
        event_size_words                               <= to_words(NUMBER_EVENT_SIZE_WRITES,
                                                                   EVENT_FIFO_DATA_WIDTH,
                                                                   event_size_fifo_read_data);
        number_event_data_writes_opcode_c              <= COUNTER_OPCODE_NOOP;
        event_data_words                               <= to_words(NUMBER_EVENT_DATA_WRITES,
                                                                   EVENT_FIFO_DATA_WIDTH,
                                                                   event_data_fifo_read_data);
        event_id_fifo_read_enable                      <= '0';
        event_timestamp_fifo_read_enable               <= '0';
        event_size_fifo_read_enable                    <= '0';
        event_data_fifo_read_enable                    <= '0';
        event_fifo_write_enable_c                      <= '0';
        event_fifo_write_data_c                        <= (others => '0');
        state_c                                        <= state_r;
        case state_r is
            when EVENT_ENCODER_STATE_IDLE =>
                if(not event_id_fifo_empty) then
                    event_id_fifo_read_enable          <= '1';
                    state_c                            <= EVENT_ENCODER_STATE_EVENT_ID_WAIT;
                end if;

            when EVENT_ENCODER_STATE_EVENT_ID_WAIT =>
                state_c                                <= EVENT_ENCODER_STATE_EVENT_ID;

            when EVENT_ENCODER_STATE_EVENT_ID =>
                number_event_id_writes_opcode_c        <= COUNTER_OPCODE_INCR;
                event_fifo_write_enable_c              <= '1';
                event_fifo_write_data_c                <= event_id_words(to_integer(number_event_id_writes_r));
                if(to_integer(number_event_id_writes_r) = (NUMBER_EVENT_ID_WRITES - 1)) then
                    event_timestamp_fifo_read_enable   <= '1';
                    state_c                            <= EVENT_ENCODER_STATE_EVENT_TIMESTAMP_WAIT;
                end if;

            when EVENT_ENCODER_STATE_EVENT_TIMESTAMP_WAIT =>
                state_c                                <= EVENT_ENCODER_STATE_EVENT_TIMESTAMP;

            when EVENT_ENCODER_STATE_EVENT_TIMESTAMP =>
                number_event_timestamp_writes_opcode_c <= COUNTER_OPCODE_INCR;
                event_fifo_write_enable_c              <= '1';
                event_fifo_write_data_c                <= event_timestamp_words(to_integer(number_event_timestamp_writes_r));
                if(to_integer(number_event_timestamp_writes_r) = (NUMBER_EVENT_TIMESTAMP_WRITES - 1)) then
                    event_size_fifo_read_enable        <= '1';
                    state_c                            <= EVENT_ENCODER_STATE_EVENT_SIZE_WAIT;
                end if;

            when EVENT_ENCODER_STATE_EVENT_SIZE_WAIT =>
                state_c                                <= EVENT_ENCODER_STATE_EVENT_SIZE;

            when EVENT_ENCODER_STATE_EVENT_SIZE =>
                number_event_size_writes_opcode_c      <= COUNTER_OPCODE_INCR;
                event_fifo_write_enable_c              <= '1';
                event_fifo_write_data_c                <= event_size_words(to_integer(number_event_size_writes_r));
                if(to_integer(number_event_size_writes_r) = (NUMBER_EVENT_SIZE_WRITES - 1)) then
                    event_data_fifo_read_enable        <= '1';
                    state_c                            <= EVENT_ENCODER_STATE_EVENT_DATA_WAIT;
                end if;

            when EVENT_ENCODER_STATE_EVENT_DATA_WAIT =>
                state_c                                <= EVENT_ENCODER_STATE_EVENT_DATA;

            when EVENT_ENCODER_STATE_EVENT_DATA =>
                number_event_data_writes_opcode_c      <= COUNTER_OPCODE_INCR;
                event_fifo_write_enable_c              <= '1';
                event_fifo_write_data_c                <= event_data_words(to_integer(number_event_data_writes_r));
                if(to_integer(number_event_data_writes_r) = (NUMBER_EVENT_DATA_WRITES - 1)) then
                    event_data_fifo_read_enable        <= '1';
                    state_c                            <= EVENT_ENCODER_STATE_IDLE;
                end if;
        end case;
    end process;

    process(clk) begin
        if(rising_edge(clk)) then
            if(rst) then
                event_fifo_write_enable_r              <= '0';
                state_r                                <= EVENT_ENCODER_STATE_IDLE;
            else
                event_fifo_write_enable_r              <= event_fifo_write_enable_c;
                state_r                                <= state_c;
            end if;
            event_fifo_write_data_r                    <= event_fifo_write_data_c;
        end if;
    end process;

    GEN_OUTPUT: if(OUTPUT_REGISTER) generate
        event_fifo_write_enable                        <= event_fifo_write_enable_r;
        event_fifo_write_data                          <= event_fifo_write_data_r;
    else generate
        event_fifo_write_enable                        <= event_fifo_write_enable_c;
        event_fifo_write_data                          <= event_fifo_write_data_c;
    end generate;
end architecture;
