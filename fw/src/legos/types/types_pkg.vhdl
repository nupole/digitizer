library ieee;
use ieee.std_logic_1164.all;

package types_pkg is
    type array_std_logic_vector_type is array(natural range<>) of std_logic_vector;

    function to_words(NUMBER_WORDS: positive;
                      WORD_WIDTH:   positive;
                      vector:       std_logic_vector) return array_std_logic_vector_type;
end package;

package body types_pkg is
    function to_words(NUMBER_WORDS: positive;
                      WORD_WIDTH:   positive;
                      vector:       std_logic_vector) return array_std_logic_vector_type is
        variable word_left_index:  natural := (WORD_WIDTH - 1);
        variable word_right_index: natural := 0;
        variable ret: array_std_logic_vector_type(0 to (NUMBER_WORDS-1))((WORD_WIDTH-1) downto 0);
    begin
        for word_index in ret'RANGE loop
            ret(word_index)  := vector(word_left_index downto word_right_index);
            word_left_index  := word_left_index + WORD_WIDTH;
            word_right_index := word_right_index + WORD_WIDTH;
        end loop;
        return ret;
    end function;
end package body;
