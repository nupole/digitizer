from random import choice, randint
from enum import Enum, auto

from cocotb.binary import BinaryValue
from cocotb.triggers import RisingEdge

from cocotb_bus.drivers import BusDriver
from cocotb_bus.monitors import BusMonitor

from legos.counter import CounterInstruction, CounterModel
from legos.dual_port_ram import DualPortRamInstruction, DualPortRamModel

class SyncFifoInstruction:
    class SyncFifoOpcode(Enum):
        def _generate_next_value_(name, start, count, last_values):
            return count

        SYNC_FIFO_OPCODE_DISABLED = auto()
        SYNC_FIFO_OPCODE_ENABLED = auto()

    def __init__(self, opcode = SyncFifoOpcode.SYNC_FIFO_OPCODE_DISABLED, operand = 0):
        self.opcode = opcode
        self.operand = operand

class RandomSyncFifoInstructionGenerator:
    _sync_fifo_opcodes = list(SyncFifoInstruction.SyncFifoOpcode)

    def __init__(self, min_data, max_data):
        self.min_data = min_data
        self.max_data = max_data

    def GenerateRandomSyncFifoInstruction(self, generate_data = True):
        opcode = choice(self._sync_fifo_opcodes)
        operand = 0
        if(generate_data):
            operand = randint(self.min_data, self.max_data)
        return SyncFifoInstruction(opcode, operand)

class SyncFifoDriver(BusDriver):
    _signals = ["enable", "data"]

    class SyncFifoDriverType(Enum):
        SYNC_FIFO_DRIVER_TYPE_MASTER_READ = auto()
        SYNC_FIFO_DRIVER_TYPE_MINION_READ = auto()
        SYNC_FIFO_DRIVER_TYPE_MASTER_WRITE = auto()

    def __init__(self, type, *args, **kwargs):
        self.type = type
        BusDriver.__init__(self, *args, **kwargs)

    async def _driver_send(self, transaction, sync):
        await RisingEdge(self.clock)
        if self.type in [self.SyncFifoDriverType.SYNC_FIFO_DRIVER_TYPE_MASTER_READ,
                         self.SyncFifoDriverType.SYNC_FIFO_DRIVER_TYPE_MASTER_WRITE]:
            self.bus.enable.value = BinaryValue(transaction.opcode.value)
        if self.type in [self.SyncFifoDriverType.SYNC_FIFO_DRIVER_TYPE_MASTER_WRITE,
                         self.SyncFifoDriverType.SYNC_FIFO_DRIVER_TYPE_MINION_READ]:
            self.bus.data.value = BinaryValue(transaction.operand)

class SyncFifoInstructionMonitor(BusMonitor):
    _signals = ["enable", "data"]

    class SyncFifoInstructionMonitorType(Enum):
        SYNC_FIFO_INSTRUCTION_MONITOR_TYPE_READ = auto()
        SYNC_FIFO_INSTRUCTION_MONITOR_TYPE_WRITE = auto()

    def __init__(self, type, *args, **kwargs):
        self.type = type
        BusMonitor.__init__(self, *args, **kwargs)

    async def _monitor_recv(self):
        while True:
            await RisingEdge(self.clock)
            if self.bus.enable.value.is_resolvable:
                opcode = SyncFifoInstruction.SyncFifoOpcode(self.bus.enable.value)
                if self.type == self.SyncFifoInstructionMonitorType.SYNC_FIFO_INSTRUCTION_MONITOR_TYPE_READ:
                    operand = 0
                else:
                    operand = int(self.bus.data.value)
                instruction = SyncFifoInstruction(opcode, operand)
                self._recv(instruction)

class SyncFifoReadDataMonitor(BusMonitor):
    _signals = ["enable", "data", "error"]

    async def _monitor_recv(self):
        delayed_read_valid_t1 = False
        delayed_read_valid_t2 = False
        while True:
            await RisingEdge(self.clock)
            if(delayed_read_valid_t2):
                self._recv(self.bus.data.value)
            delayed_read_valid_t2 = delayed_read_valid_t1
            if(self.bus.enable.value.is_resolvable):
                delayed_read_valid_t1 = (self.bus.enable.value == BinaryValue(SyncFifoInstruction.SyncFifoOpcode.SYNC_FIFO_OPCODE_ENABLED.value))

class SyncFifoModel:
    def __init__(self, address_width):
        pointer_width = (address_width + 1)
        self._pointer_msb_mask = (2 ** address_width)
        self._address_mask = (self._pointer_msb_mask - 1)
        self._write_pointer_model = CounterModel(pointer_width)
        self._read_pointer_model = CounterModel(pointer_width)
        self._dual_port_ram_model = DualPortRamModel(address_width)

    def Reset(self):
        self._write_pointer_model.Reset()
        self._read_pointer_model.Reset()

    def Write(self, instruction):
        if not self.IsFull():
            write_address = (self._write_pointer_model.count & self._address_mask)
            if instruction.opcode == SyncFifoInstruction.SyncFifoOpcode.SYNC_FIFO_OPCODE_ENABLED:
                counter_instruction = CounterInstruction(CounterInstruction.CounterOpcode.COUNTER_OPCODE_INCR)
                self._write_pointer_model.UpdateCount(counter_instruction)
            dual_port_ram_instruction = DualPortRamInstruction(DualPortRamInstruction.DualPortRamOpcode.DUAL_PORT_RAM_OPCODE_ENABLED,
                                                               DualPortRamInstruction.DualPortRamOperand(write_address, instruction.operand))
            self._dual_port_ram_model.Write(dual_port_ram_instruction)

    def Read(self, instruction):
        read_address = (self._read_pointer_model.count & self._address_mask)
        if not self.IsEmpty():
            if instruction.opcode == SyncFifoInstruction.SyncFifoOpcode.SYNC_FIFO_OPCODE_ENABLED:
                counter_instruction = CounterInstruction(CounterInstruction.CounterOpcode.COUNTER_OPCODE_INCR)
                self._read_pointer_model.UpdateCount(counter_instruction)
        dual_port_ram_instruction = DualPortRamInstruction(DualPortRamInstruction.DualPortRamOpcode.DUAL_PORT_RAM_OPCODE_ENABLED,
        DualPortRamInstruction.DualPortRamOperand(read_address))
        return self._dual_port_ram_model.Read(dual_port_ram_instruction)

    def IsEmpty(self):
        return (self._write_pointer_model.count == self._read_pointer_model.count)

    def IsAlmostEmpty(self):
        pass

    def IsAlmostFull(self):
        pass

    def IsFull(self):
        return (((self._write_pointer_model.count & self._pointer_msb_mask) != (self._read_pointer_model.count & self._pointer_msb_mask)) and
                ((self._write_pointer_model.count & self._address_mask) == (self._read_pointer_model.count & self._address_mask)))
