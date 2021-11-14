from random import choice, randint
from enum import Enum, auto

from cocotb.binary import BinaryValue
from cocotb.triggers import RisingEdge

from cocotb_bus.drivers import BusDriver
from cocotb_bus.monitors import BusMonitor

class CounterInstruction:
    class CounterOpcode(Enum):
        def _generate_next_value_(name, start, count, last_values):
            return count

        COUNTER_OPCODE_NOOP = auto()
        COUNTER_OPCODE_DECR = auto()
        COUNTER_OPCODE_INCR = auto()
        COUNTER_OPCODE_LOAD = auto()

    def __init__(self, opcode = CounterOpcode.COUNTER_OPCODE_NOOP, operand = 0):
        self.opcode = opcode
        self.operand = operand

class RandomCounterInstructionGenerator:
    _counter_opcodes = list(CounterInstruction.CounterOpcode)

    def __init__(self, min_operand, max_operand):
        self._min_operand = min_operand
        self._max_operand = max_operand

    def GenerateRandomCounterInstruction(self):
        opcode = choice(self._counter_opcodes)
        operand = randint(self._min_operand, self._max_operand)
        return CounterInstruction(opcode, operand)

class CounterInstructionDriver(BusDriver):
    _signals = ["opcode", "operand"]

    async def _driver_send(self, transaction, sync):
        await RisingEdge(self.clock)
        self.bus.opcode.value = BinaryValue(transaction.opcode.value)
        self.bus.operand.value = BinaryValue(transaction.operand)

class CounterInstructionMonitor(BusMonitor):
    _signals = ["opcode", "operand"]

    async def _monitor_recv(self):
        clock_edge = RisingEdge(self.clock)
        while True:
            await clock_edge
            if not self.in_reset:
                opcode = CounterInstruction.CounterOpcode(self.bus.opcode.value)
                operand = self.bus.operand.value
                instruction = CounterInstruction(opcode, operand)
                self._recv(instruction)

class CounterCountMonitor(BusMonitor):
    _signals = ["opcode", "next_count"]

    async def _monitor_recv(self):
        clock_edge = RisingEdge(self.clock)
        while True:
            await clock_edge
            if not self.in_reset:
                opcode = CounterInstruction.CounterOpcode(self.bus.opcode.value)
                if opcode in [CounterInstruction.CounterOpcode.COUNTER_OPCODE_DECR,
                              CounterInstruction.CounterOpcode.COUNTER_OPCODE_INCR,
                              CounterInstruction.CounterOpcode.COUNTER_OPCODE_LOAD]:
                    self._recv(self.bus.next_count.value)

class CounterModel:
    def __init__(self, count_width):
        self._max_count = (2 ** count_width)
        self.Reset()

    @property
    def count(self):
        return self._count

    def Reset(self):
        self._count = 0

    def UpdateCount(self, instruction):
        if instruction.opcode == CounterInstruction.CounterOpcode.COUNTER_OPCODE_DECR:
            self._count = ((self._count - 1) % self._max_count)
        elif instruction.opcode == CounterInstruction.CounterOpcode.COUNTER_OPCODE_INCR:
            self._count = ((self._count + 1) % self._max_count)
        elif instruction.opcode == CounterInstruction.CounterOpcode.COUNTER_OPCODE_LOAD:
            self._count = instruction.operand.value
