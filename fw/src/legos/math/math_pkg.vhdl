library ieee;
use ieee.std_logic_1164.all;

package math_pkg is
    function log2(m: positive) return natural;
end package;

package body math_pkg is
    function log2(m: positive) return natural is
        variable temp: natural := m / 2;
        variable ret:  natural := 0;
    begin
        if(temp /= 0) then
            ret := 1 + log2(temp);
        end if;
        return ret;
    end function;
end package body;
