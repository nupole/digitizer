from cocotb import start, test
from cocotb.clock import Clock

from cocotb.triggers import RisingEdge, Timer

from cocotb_bus.scoreboard import Scoreboard

from legos.sync_fifo import SyncFifoInstruction, SyncFifoModel
from event_manager.event_encoder import EventEncoderInfo, EventEncoderInfoDriver, EventEncoderInfoMonitor, EventFifoMonitor

class EventEncoderTB:
    def __init__(self, dut):
        self._dut = dut
        self._expected_output = []
        self._event_id_driver = EventEncoderInfoDriver(entity = dut, name = "event_id_fifo", clock = dut.clk)
        self._event_timestamp_driver = EventEncoderInfoDriver(entity = dut, name = "event_timestamp_fifo", clock = dut.clk)
        self._event_size_driver = EventEncoderInfoDriver(entity = dut, name = "event_size_fifo", clock = dut.clk)
        self._event_data_driver = EventEncoderInfoDriver(entity = dut, name = "event_data_fifo", clock = dut.clk)
        self._event_id_monitor = EventEncoderInfoMonitor(entity = dut, name = "event_id_fifo", clock = dut.clk, callback = self.EventIdHandler)
        self._event_timestamp_monitor = EventEncoderInfoMonitor(entity = dut, name = "event_timestamp_fifo", clock = dut.clk, callback = self.EventTimestampHandler)
        self._event_size_monitor = EventEncoderInfoMonitor(entity = dut, name = "event_size_fifo", clock = dut.clk, callback = self.EventSizeHandler)
        self._event_data_monitor = EventEncoderInfoMonitor(entity = dut, name = "event_data_fifo", clock = dut.clk, callback = self.EventDataHandler)
        self._event_id_fifo_model = SyncFifoModel(10)
        self._event_timestamp_fifo_model = SyncFifoModel(10)
        self._event_size_fifo_model = SyncFifoModel(10)
        self._event_data_fifo_model = SyncFifoModel(10)
        self._event_fifo_monitor = EventFifoMonitor(entity = dut, name = "event_fifo", clock = dut.clk)
        self._scoreboard = Scoreboard(dut)
        # self._scoreboard.add_interface(self._event_fifo_monitor, self._expected_output)
        self._last_event_id_read_data = 0
        self._last_event_timestamp_read_data = 0
        self._last_event_size_read_data = 0
        self._last_event_data_read_data = 0

    async def Start(self):
        await start(Clock(self._dut.clk, 10, units = "ns").start())
        await RisingEdge(self._dut.clk)
        self._dut.rst.value = 1
        await RisingEdge(self._dut.clk)
        self._dut.rst.value = 0

    def WriteEventId(self, event_id):
        is_empty = self._event_id_fifo_model.IsEmpty()
        sync_fifo_instruction = SyncFifoInstruction(SyncFifoInstruction.SyncFifoOpcode.SYNC_FIFO_OPCODE_ENABLED, event_id)
        self._event_id_fifo_model.Write(sync_fifo_instruction)
        if is_empty:
            self._event_id_driver.append(EventEncoderInfo(1, self._last_event_id_read_data))
            self._event_id_driver.append(EventEncoderInfo(0, self._last_event_id_read_data))
            self._last_event_id_read_data = event_id

    def EventIdHandler(self, transaction):
        if transaction == EventEncoderInfoMonitor.EventEncoderInfoDriveType.EVENT_ENCODER_INFO_DRIVE_TYPE_EMPTY:
            sync_fifo_instruction = SyncFifoInstruction(SyncFifoInstruction.SyncFifoOpcode.SYNC_FIFO_OPCODE_ENABLED)
            event_id = self._event_id_fifo_model.Read(sync_fifo_instruction)
            event_id_empty = 1 if self._event_id_fifo_model.IsEmpty() else 0
            print(event_id_empty)
            self._event_id_driver.append(EventEncoderInfo(event_id_empty, self._last_event_id_read_data))
            self._last_event_id_read_data = int(event_id)
        else:
            event_id_empty = 1 if self._event_id_fifo_model.IsEmpty() else 0
            self._event_id_driver.append(EventEncoderInfo(event_id_empty, self._last_event_id_read_data))

    def WriteEventTimestamp(self, event_timestamp):
        is_empty = self._event_timestamp_fifo_model.IsEmpty()
        sync_fifo_instruction = SyncFifoInstruction(SyncFifoInstruction.SyncFifoOpcode.SYNC_FIFO_OPCODE_ENABLED, event_timestamp)
        self._event_timestamp_fifo_model.Write(sync_fifo_instruction)
        if is_empty:
            self._event_timestamp_driver.append(EventEncoderInfo(1, self._last_event_timestamp_read_data))
            self._event_timestamp_driver.append(EventEncoderInfo(0, self._last_event_timestamp_read_data))
            self._event_timestamp_driver.append(EventEncoderInfo(0, self._last_event_timestamp_read_data))
            self._event_timestamp_driver.append(EventEncoderInfo(0, event_timestamp))
            self._last_event_timestamp_read_data = event_timestamp

    def EventTimestampHandler(self, transaction):
        if transaction == EventEncoderInfoMonitor.EventEncoderInfoDriveType.EVENT_ENCODER_INFO_DRIVE_TYPE_EMPTY:
            sync_fifo_instruction = SyncFifoInstruction(SyncFifoInstruction.SyncFifoOpcode.SYNC_FIFO_OPCODE_ENABLED)
            event_timestamp = self._event_timestamp_fifo_model.Read(sync_fifo_instruction)
            event_timestamp_empty = 1 if self._event_timestamp_fifo_model.IsEmpty() else 0
            self._event_timestamp_driver.append(EventEncoderInfo(event_timestamp_empty, self._last_event_timestamp_read_data))
            self._last_event_timestamp_read_data = int(event_timestamp)
        else:
            event_timestamp_empty = 1 if self._event_timestamp_fifo_model.IsEmpty() else 0
            self._event_timestamp_driver.append(EventEncoderInfo(event_timestamp_empty, self._last_event_timestamp_read_data))

    def EventSizeHandler(self, transaction):
        pass

    def EventDataHandler(self, transaction):
        pass

    async def Stop(self):
        await Timer(2, "us")
        raise self._scoreboard.result

@test()
async def test_event_encoder_one_events(dut):
    event_encoder_tb = EventEncoderTB(dut)
    await event_encoder_tb.Start()
    event_encoder_tb.WriteEventId(2)
    event_encoder_tb.WriteEventTimestamp(4)
    await event_encoder_tb.Stop()

@test()
async def test_event_encoder_two_events(dut):
    event_encoder_tb = EventEncoderTB(dut)
    await event_encoder_tb.Start()
    event_encoder_tb.WriteEventId(2)
    event_encoder_tb.WriteEventTimestamp(4)
    event_encoder_tb.WriteEventId(3)
    event_encoder_tb.WriteEventTimestamp(4)
    await event_encoder_tb.Stop()
