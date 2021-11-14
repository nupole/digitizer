from random import choice, randint
from enum import Enum, auto

from numpy import zeros

from cocotb.binary import BinaryValue
from cocotb.triggers import RisingEdge

from cocotb_bus.drivers import BusDriver
from cocotb_bus.monitors import BusMonitor
from cocotb_bus.scoreboard import Scoreboard

class DualPortRamInstruction:
    class DualPortRamOpcode(Enum):
        def _generate_next_value_(name, start, count, last_values):
            return count

        DUAL_PORT_RAM_OPCODE_DISABLED = auto()
        DUAL_PORT_RAM_OPCODE_ENABLED = auto()

    class DualPortRamOperand:
        def __init__(self, address = 0, data = 0):
            self.address = address
            self.data = data

    def __init__(self, opcode = DualPortRamOpcode.DUAL_PORT_RAM_OPCODE_DISABLED, operand = DualPortRamOperand()):
        self.opcode = opcode
        self.operand = operand

class RandomDualPortRamInstructionGenerator:
    _dual_port_ram_opcodes = list(DualPortRamInstruction.DualPortRamOpcode)

    def __init__(self, min_address, max_address, min_data, max_data):
        self.min_address = min_address
        self.max_address = max_address
        self.min_data = min_data
        self.max_data = max_data

    def GenerateRandomDualPortRamInstruction(self, generate_data = True):
        opcode = choice(self._dual_port_ram_opcodes)
        address = randint(self.min_address, self.max_address)
        data = 0
        if(generate_data):
            data = randint(self.min_data, self.max_data)
        operand = DualPortRamInstruction.DualPortRamOperand(address, data)
        return DualPortRamInstruction(opcode, operand)

class DualPortRamDriver(BusDriver):
    _signals = ["enable", "address", "data"]

    class DualPortRamDriverType(Enum):
        DUAL_PORT_RAM_DRIVER_TYPE_READ = auto()
        DUAL_PORT_RAM_DRIVER_TYPE_WRITE = auto()

    def __init__(self, type, *args, **kwargs):
        self.type = type
        BusDriver.__init__(self, *args, **kwargs)

    async def _driver_send(self, transaction, sync):
        await RisingEdge(self.clock)
        self.bus.enable.value = BinaryValue(transaction.opcode.value)
        self.bus.address.value = BinaryValue(transaction.operand.address)
        if(self.type == self.DualPortRamDriverType.DUAL_PORT_RAM_DRIVER_TYPE_WRITE):
            self.bus.data.value = BinaryValue(transaction.operand.data)

class DualPortRamInstructionMonitor(BusMonitor):
    _signals = ["enable", "address", "data"]

    class DualPortRamInstructionMonitorType(Enum):
        DUAL_PORT_RAM_INSTRUCTION_MONITOR_TYPE_READ = auto()
        DUAL_PORT_RAM_INSTRUCTION_MONITOR_TYPE_WRITE = auto()

    def __init__(self, type, *args, **kwargs):
        self.type = type
        BusMonitor.__init__(self, *args, **kwargs)

    async def _monitor_recv(self):
        while True:
            await RisingEdge(self.clock)
            if self.bus.enable.value.is_resolvable and self.bus.address.value.is_resolvable:
                opcode = DualPortRamInstruction.DualPortRamOpcode(self.bus.enable.value)
                if self.type == self.DualPortRamInstructionMonitorType.DUAL_PORT_RAM_INSTRUCTION_MONITOR_TYPE_READ:
                    operand = DualPortRamInstruction.DualPortRamOperand(int(self.bus.address.value))
                else:
                    operand = DualPortRamInstruction.DualPortRamOperand(int(self.bus.address.value),
                                                                        int(self.bus.data.value))
                instruction = DualPortRamInstruction(opcode, operand)
                self._recv(instruction)

class DualPortRamReadDataMonitor(BusMonitor):
    _signals = ["enable", "data"]

    async def _monitor_recv(self):
        delayed_read_valid_t1 = False
        delayed_read_valid_t2 = False
        while True:
            await RisingEdge(self.clock)
            if(delayed_read_valid_t2):
                self._recv(self.bus.data.value)
            delayed_read_valid_t2 = delayed_read_valid_t1
            if(self.bus.enable.value.is_resolvable):
                delayed_read_valid_t1 = (self.bus.enable.value == BinaryValue(DualPortRamInstruction.DualPortRamOpcode.DUAL_PORT_RAM_OPCODE_ENABLED.value))

class DualPortRamModel:
    def __init__(self, address_width):
        self._ram = zeros(2 ** address_width, dtype = int)

    def Write(self, instruction):
        if(instruction.opcode == DualPortRamInstruction.DualPortRamOpcode.DUAL_PORT_RAM_OPCODE_ENABLED):
            self._ram[instruction.operand.address] = instruction.operand.data

    def Read(self, instruction):
        if(instruction.opcode == DualPortRamInstruction.DualPortRamOpcode.DUAL_PORT_RAM_OPCODE_ENABLED):
            return self._ram[instruction.operand.address]
