add_ghdl_target(hdl_event_encoder HDL_PACKAGE event_encoder_pkg.vhdl
                                  HDL_SOURCE event_encoder.vhdl
                                  HDL_DEPENDS hdl_math
                                              hdl_types
                                              hdl_counter)
