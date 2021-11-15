library ieee;
use ieee.std_logic_1164.all;

package event_encoder_pkg is
    type event_encoder_state_enum is (EVENT_ENCODER_STATE_IDLE,
                                      EVENT_ENCODER_STATE_EVENT_ID_WAIT,
                                      EVENT_ENCODER_STATE_EVENT_ID,
                                      EVENT_ENCODER_STATE_EVENT_TIMESTAMP_WAIT,
                                      EVENT_ENCODER_STATE_EVENT_TIMESTAMP,
                                      EVENT_ENCODER_STATE_EVENT_SIZE_WAIT,
                                      EVENT_ENCODER_STATE_EVENT_SIZE,
                                      EVENT_ENCODER_STATE_EVENT_DATA_WAIT,
                                      EVENT_ENCODER_STATE_EVENT_DATA);
end package;
