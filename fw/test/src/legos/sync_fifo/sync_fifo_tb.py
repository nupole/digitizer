from cocotb import start, test
from cocotb.clock import Clock
from cocotb.binary import BinaryValue
from cocotb.triggers import RisingEdge, Timer

from cocotb_bus.scoreboard import Scoreboard

from legos.sync_fifo import SyncFifoInstruction, RandomSyncFifoInstructionGenerator, SyncFifoDriver, SyncFifoInstructionMonitor, SyncFifoReadDataMonitor, SyncFifoModel

class SyncFifoTB:
    def __init__(self, dut):
        self._dut = dut
        self._expected_output = []
        self._write_driver = SyncFifoDriver(SyncFifoDriver.SyncFifoDriverType.SYNC_FIFO_DRIVER_TYPE_MASTER_WRITE, entity = dut, name = "write", clock = dut.clk)
        self._read_driver = SyncFifoDriver(SyncFifoDriver.SyncFifoDriverType.SYNC_FIFO_DRIVER_TYPE_MASTER_READ, entity = dut, name = "read", clock = dut.clk)
        self._read_instruction_monitor = SyncFifoInstructionMonitor(SyncFifoInstructionMonitor.SyncFifoInstructionMonitorType.SYNC_FIFO_INSTRUCTION_MONITOR_TYPE_READ, entity = dut, name = "read", clock = dut.clk, callback = self.ReadFifo)
        self._write_instruction_monitor = SyncFifoInstructionMonitor(SyncFifoInstructionMonitor.SyncFifoInstructionMonitorType.SYNC_FIFO_INSTRUCTION_MONITOR_TYPE_WRITE, entity = dut, name = "write", clock = dut.clk, callback = self.WriteFifo)
        self._read_data_monitor = SyncFifoReadDataMonitor(entity = dut, name = "read", clock = dut.clk)
        self._model = SyncFifoModel(int(dut.ADDRESS_WIDTH))
        self._scoreboard = Scoreboard(dut)
        self._scoreboard.add_interface(self._read_data_monitor, self._expected_output)

    async def Start(self):
        await start(Clock(self._dut.clk, 10, units = "ns").start())
        await RisingEdge(self._dut.clk)
        self._dut.rst.value = 1
        await RisingEdge(self._dut.clk)
        self._dut.rst.value = 0
        for address in range(2 ** int(self._dut.ADDRESS_WIDTH)):
            sync_fifo_instruction = SyncFifoInstruction(SyncFifoInstruction.SyncFifoOpcode.SYNC_FIFO_OPCODE_ENABLED)
            await self.BlockedWrite(sync_fifo_instruction)
            sync_fifo_instruction = SyncFifoInstruction()
            self.Write(sync_fifo_instruction)
            sync_fifo_instruction = SyncFifoInstruction(SyncFifoInstruction.SyncFifoOpcode.SYNC_FIFO_OPCODE_ENABLED)
            await self.BlockedRead(sync_fifo_instruction)
            sync_fifo_instruction = SyncFifoInstruction()
            self.Read(sync_fifo_instruction)


    async def BlockedWrite(self, instruction):
        await self._write_driver.send(instruction)

    def Write(self, instruction):
        self._write_driver.append(instruction)

    def WriteFifo(self, instruction):
        self._model.Write(instruction)

    async def BlockedRead(self, instruction):
        await self._read_driver.send(instruction)

    def Read(self, instruction):
        self._read_driver.append(instruction)

    def ReadFifo(self, instruction):
        read_data = self._model.Read(instruction)
        if instruction.opcode == SyncFifoInstruction.SyncFifoOpcode.SYNC_FIFO_OPCODE_ENABLED:
            self._expected_output.append(BinaryValue(int(read_data)))

    async def Stop(self):
        self.Write(SyncFifoInstruction())
        self.Read(SyncFifoInstruction())
        await Timer(3.1, "us")
        raise self._scoreboard.result

@test()
async def test_sync_fifo_write_then_read(dut):
    sync_fifo_tb = SyncFifoTB(dut)
    await sync_fifo_tb.Start()
    await sync_fifo_tb.BlockedWrite(SyncFifoInstruction(SyncFifoInstruction.SyncFifoOpcode.SYNC_FIFO_OPCODE_ENABLED, 1))
    sync_fifo_tb.Read(SyncFifoInstruction(SyncFifoInstruction.SyncFifoOpcode.SYNC_FIFO_OPCODE_ENABLED))
    await sync_fifo_tb.Stop()

@test()
async def test_sync_fifo_read_then_write(dut):
    sync_fifo_tb = SyncFifoTB(dut)
    await sync_fifo_tb.Start()
    await sync_fifo_tb.BlockedRead(SyncFifoInstruction(SyncFifoInstruction.SyncFifoOpcode.SYNC_FIFO_OPCODE_ENABLED))
    sync_fifo_tb.Write(SyncFifoInstruction(SyncFifoInstruction.SyncFifoOpcode.SYNC_FIFO_OPCODE_ENABLED, 1))
    await sync_fifo_tb.Stop()

@test()
async def test_sync_fifo_write_and_read(dut):
    sync_fifo_tb = SyncFifoTB(dut)
    await sync_fifo_tb.Start()
    sync_fifo_tb.Read(SyncFifoInstruction(SyncFifoInstruction.SyncFifoOpcode.SYNC_FIFO_OPCODE_ENABLED))
    sync_fifo_tb.Write(SyncFifoInstruction(SyncFifoInstruction.SyncFifoOpcode.SYNC_FIFO_OPCODE_ENABLED, 1))
    await sync_fifo_tb.Stop()

@test()
async def test_sync_fifo_random(dut):
    sync_fifo_tb = SyncFifoTB(dut)
    await sync_fifo_tb.Start()
    min_data = 0
    max_data = ((2 ** int(dut.DATA_WIDTH)) - 1)
    instruction_generator = RandomSyncFifoInstructionGenerator(min_data, max_data)
    for i in range(296):
        sync_fifo_tb.Read(instruction_generator.GenerateRandomSyncFifoInstruction(False))
        sync_fifo_tb.Write(instruction_generator.GenerateRandomSyncFifoInstruction())
    await sync_fifo_tb.Stop()
