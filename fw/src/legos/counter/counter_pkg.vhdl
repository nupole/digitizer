library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package counter_pkg is
    type counter_opcode_enum is (COUNTER_OPCODE_NOOP,
                                 COUNTER_OPCODE_DECR,
                                 COUNTER_OPCODE_INCR,
                                 COUNTER_OPCODE_LOAD);

    type counter_instruction_struct is record
        opcode:  counter_opcode_enum;
        operand: unsigned;
    end record;

    function get_next_count(instruction: counter_instruction_struct;
                            count:       unsigned) return unsigned;
end package;

package body counter_pkg is
    function get_next_count(instruction: counter_instruction_struct;
                            count:       unsigned) return unsigned is
        variable ret: unsigned(count'RANGE);
    begin
        case instruction.opcode is
            when COUNTER_OPCODE_NOOP => ret := count;
            when COUNTER_OPCODE_DECR => ret := count - '1';
            when COUNTER_OPCODE_INCR => ret := count + '1';
            when COUNTER_OPCODE_LOAD => ret := instruction.operand;
        end case;
        return ret;
    end function;
end package body;
