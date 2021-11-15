from enum import Enum, auto

from cocotb.binary import BinaryValue

from cocotb.triggers import RisingEdge

from cocotb_bus.drivers import BusDriver
from cocotb_bus.monitors import BusMonitor

class EventEncoderInfo:
    def __init__(self, empty, data):
        self.empty = empty
        self.data = data

class EventEncoderInfoDriver(BusDriver):
    _signals = ["empty", "read_data"]

    async def _driver_send(self, transaction, sync):
        self.bus.empty.value = BinaryValue(transaction.empty)
        self.bus.read_data.value = BinaryValue(transaction.data)

class EventEncoderInfoMonitor(BusMonitor):
    _signals = ["read_enable"]

    class EventEncoderInfoDriveType(Enum):
        EVENT_ENCODER_INFO_DRIVE_TYPE_EMPTY = auto()
        EVENT_ENCODER_INFO_DRIVE_TYPE_DATA = auto()

    async def _monitor_recv(self):
        delayed_read_valid_t1 = False
        while True:
            await RisingEdge(self.clock)
            if delayed_read_valid_t1:
                self._recv(self.EventEncoderInfoDriveType.EVENT_ENCODER_INFO_DRIVE_TYPE_DATA)
            if self.bus.read_enable.value.is_resolvable:
                delayed_read_valid_t1 = (self.bus.read_enable.value == BinaryValue(1))
                if delayed_read_valid_t1:
                    self._recv(self.EventEncoderInfoDriveType.EVENT_ENCODER_INFO_DRIVE_TYPE_EMPTY)

class EventFifoMonitor(BusMonitor):
    _signals = ["write_enable", "write_data"]

    async def _monitor_recv(self):
        while True:
            await RisingEdge(self.clock)
            if self.bus.write_enable.value.is_resolvable:
                if self.bus.write_enable.value:
                    self._recv(self.bus.write_data.value)
