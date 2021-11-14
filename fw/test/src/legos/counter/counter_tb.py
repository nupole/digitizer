from random import randint

from cocotb import start, test
from cocotb.binary import BinaryValue
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

from cocotb_bus.scoreboard import Scoreboard

from legos.counter import CounterInstruction, RandomCounterInstructionGenerator, CounterInstructionDriver, CounterInstructionMonitor, CounterCountMonitor, CounterModel

class CounterTB:
    def __init__(self, dut):
        self._dut = dut
        self._clock = Clock(dut.clk, 10, units = "ns")
        self._expected_output = []
        self._instruction_driver = CounterInstructionDriver(entity = dut, name = None, clock = dut.clk)
        self._instruction_monitor = CounterInstructionMonitor(entity = dut, name = None, clock = dut.clk, reset = dut.rst, callback = self.AddExpected)
        self._count_monitor = CounterCountMonitor(entity = dut, name = None, clock = dut.clk, reset = dut.rst)
        self._model = CounterModel(dut.COUNT_WIDTH.value)
        self._scoreboard = Scoreboard(dut)
        self._scoreboard.add_interface(self._count_monitor, self._expected_output)

    async def Start(self):
        await start(self._clock.start())
        self._dut.rst.value = 1
        self.SendInstruction(CounterInstruction())
        await RisingEdge(self._dut.clk)
        await RisingEdge(self._dut.clk)
        self._dut.rst.value = 0

    def SendInstruction(self, instruction):
        self._instruction_driver.append(instruction)

    def AddExpected(self, instruction):
        self._model.UpdateCount(instruction)
        if instruction.opcode in [CounterInstruction.CounterOpcode.COUNTER_OPCODE_DECR,
                                  CounterInstruction.CounterOpcode.COUNTER_OPCODE_INCR,
                                  CounterInstruction.CounterOpcode.COUNTER_OPCODE_LOAD]:
            self._expected_output.append(BinaryValue(self._model.count))

    async def Stop(self):
        self.SendInstruction(CounterInstruction(CounterInstruction.CounterOpcode.COUNTER_OPCODE_NOOP))
        await Timer(2.6, "us")
        raise self._scoreboard.result

@test()
async def test_counter_decr(dut):
    counter_tb = CounterTB(dut)
    await counter_tb.Start()
    counter_tb.SendInstruction(CounterInstruction(CounterInstruction.CounterOpcode.COUNTER_OPCODE_DECR))
    await counter_tb.Stop()

@test()
async def test_counter_incr(dut):
    counter_tb = CounterTB(dut)
    await counter_tb.Start()
    counter_tb.SendInstruction(CounterInstruction(CounterInstruction.CounterOpcode.COUNTER_OPCODE_INCR))
    await counter_tb.Stop()

@test()
async def test_counter_load(dut):
    counter_tb = CounterTB(dut)
    await counter_tb.Start()
    counter_tb.SendInstruction(CounterInstruction(CounterInstruction.CounterOpcode.COUNTER_OPCODE_LOAD, 2))
    await counter_tb.Stop()

@test()
async def test_counter_random(dut):
    counter_tb = CounterTB(dut)
    instruction_generator = RandomCounterInstructionGenerator(0, int((2 ** int(dut.COUNT_WIDTH)) - 1))
    await counter_tb.Start()
    for i in range(258):
        counter_tb.SendInstruction(instruction_generator.GenerateRandomCounterInstruction())
    await counter_tb.Stop()
