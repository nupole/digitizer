add_ghdl_target(hdl_event_encoder_tb HDL_SOURCE event_encoder_tb.vhdl
                                     COCOTB_MODULE event_encoder_tb.py
                                     HDL_DEPENDS hdl_event_encoder
                                     COCOTB_MODULE_DEPENDS python_sync_fifo
                                                           python_event_encoder)
