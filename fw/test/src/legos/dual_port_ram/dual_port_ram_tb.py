from cocotb import start, test
from cocotb.clock import Clock
from cocotb.binary import BinaryValue
from cocotb.triggers import Timer

from cocotb_bus.scoreboard import Scoreboard

from legos.dual_port_ram import DualPortRamInstruction, RandomDualPortRamInstructionGenerator, DualPortRamDriver, DualPortRamInstructionMonitor, DualPortRamReadDataMonitor, DualPortRamModel

class DualPortRamTB:
    def __init__(self, dut):
        self._dut = dut
        self._expected_output = []
        self._write_driver = DualPortRamDriver(DualPortRamDriver.DualPortRamDriverType.DUAL_PORT_RAM_DRIVER_TYPE_WRITE, entity = dut, name = "write", clock = dut.write_clk)
        self._read_driver = DualPortRamDriver(DualPortRamDriver.DualPortRamDriverType.DUAL_PORT_RAM_DRIVER_TYPE_READ, entity = dut, name = "read", clock = dut.read_clk)
        self._write_instruction_monitor = DualPortRamInstructionMonitor(DualPortRamInstructionMonitor.DualPortRamInstructionMonitorType.DUAL_PORT_RAM_INSTRUCTION_MONITOR_TYPE_WRITE, entity = dut, name = "write", clock = dut.write_clk, callback = self.WriteRam)
        self._read_instruction_monitor = DualPortRamInstructionMonitor(DualPortRamInstructionMonitor.DualPortRamInstructionMonitorType.DUAL_PORT_RAM_INSTRUCTION_MONITOR_TYPE_READ, entity = dut, name = "read", clock = dut.read_clk, callback = self.ReadRam)
        self._read_data_monitor = DualPortRamReadDataMonitor(entity = dut, name = "read", clock = dut.read_clk)
        self._model = DualPortRamModel(int(dut.ADDRESS_WIDTH))
        self._scoreboard = Scoreboard(dut)
        self._scoreboard.add_interface(self._read_data_monitor, self._expected_output)

    async def Start(self):
        await start(Clock(self._dut.write_clk, 10, units = "ns").start())
        await start(Clock(self._dut.read_clk, 10, units = "ns").start(start_high = False))
        for address in range(2 ** int(self._dut.ADDRESS_WIDTH)):
            dual_port_ram_instruction = DualPortRamInstruction(DualPortRamInstruction.DualPortRamOpcode.DUAL_PORT_RAM_OPCODE_ENABLED,
                                                               DualPortRamInstruction.DualPortRamOperand(address))
            await self.BlockedWrite(dual_port_ram_instruction)

    async def BlockedWrite(self, instruction):
        await self._write_driver.send(instruction)

    def Write(self, instruction):
        self._write_driver.append(instruction)

    def WriteRam(self, instruction):
        self._model.Write(instruction)

    async def BlockedRead(self, instruction):
        await self._read_driver.send(instruction)

    def Read(self, instruction):
        self._read_driver.append(instruction)

    def ReadRam(self, instruction):
        read_data = self._model.Read(instruction)
        if instruction.opcode == DualPortRamInstruction.DualPortRamOpcode.DUAL_PORT_RAM_OPCODE_ENABLED:
            self._expected_output.append(BinaryValue(int(read_data)))

    async def Stop(self):
        self.Write(DualPortRamInstruction())
        self.Read(DualPortRamInstruction())
        await Timer(3, units = "us")
        raise self._scoreboard.result

@test()
async def test_dual_port_ram_write_then_read(dut):
    dual_port_ram_tb = DualPortRamTB(dut)
    await dual_port_ram_tb.Start()
    await dual_port_ram_tb.BlockedWrite(DualPortRamInstruction(DualPortRamInstruction.DualPortRamOpcode.DUAL_PORT_RAM_OPCODE_ENABLED, DualPortRamInstruction.DualPortRamOperand(2, 3)))
    dual_port_ram_tb.Read(DualPortRamInstruction(DualPortRamInstruction.DualPortRamOpcode.DUAL_PORT_RAM_OPCODE_ENABLED, DualPortRamInstruction.DualPortRamOperand(2)))
    await dual_port_ram_tb.Stop()

@test()
async def test_dual_port_ram_read_then_write(dut):
    dual_port_ram_tb = DualPortRamTB(dut)
    await dual_port_ram_tb.Start()
    await dual_port_ram_tb.BlockedRead(DualPortRamInstruction(DualPortRamInstruction.DualPortRamOpcode.DUAL_PORT_RAM_OPCODE_ENABLED, DualPortRamInstruction.DualPortRamOperand(2)))
    dual_port_ram_tb.Write(DualPortRamInstruction(DualPortRamInstruction.DualPortRamOpcode.DUAL_PORT_RAM_OPCODE_ENABLED, DualPortRamInstruction.DualPortRamOperand(2, 3)))
    await dual_port_ram_tb.Stop()

@test()
async def test_dual_port_ram_random(dut):
    dual_port_ram_tb = DualPortRamTB(dut)
    await dual_port_ram_tb.Start()
    min_address = 0
    max_address = ((2 ** int(dut.ADDRESS_WIDTH)) - 1)
    min_data = 0
    max_data = ((2 ** int(dut.DATA_WIDTH)) - 1)
    instruction_generator = RandomDualPortRamInstructionGenerator(min_address, max_address, min_data, max_data)
    for i in range(296):
        dual_port_ram_tb.Write(instruction_generator.GenerateRandomDualPortRamInstruction())
        dual_port_ram_tb.Read(instruction_generator.GenerateRandomDualPortRamInstruction(False))
    await dual_port_ram_tb.Stop()
