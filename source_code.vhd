----------------------------------------------------------------------------------
-- Company: Politecnico di Milano
-- Authors: De Santi Riccardo, Danelutti Luca
-- Academic Year: 2019-2020
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity project_reti_logiche is
  port(
    i_clk, i_start, i_rst   : in std_logic;
    i_data                  : in std_logic_vector(7 downto 0);
    o_address               : out std_logic_vector(15 downto 0);
    o_done, o_en, o_we      : out std_logic;
    o_data                  : out std_logic_vector(7 downto 0)
  );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
    type state_type is (reset, read_addr, read_wzs, write_res, final);
    signal state: state_type;
    signal address_read: std_logic_vector(6 downto 0);
    signal curr_mem_pos: std_logic_vector(15 downto 0);
    signal wz_bit: std_logic;
    signal wz_offset: std_logic_vector(3 downto 0);

begin
    process(i_clk, i_rst)
    begin
        if (falling_edge(i_clk)) then
            o_done <= '0';
            o_we <= '0';
            o_en <= '0';
            o_address <= "0000000000001000";
            o_data <= "00000000";
            case state is
            when reset =>
                if i_start='1' then
                    state <= read_addr;
                    o_en <= '1';
                    o_address <= "0000000000001000";
                else
                    state <= state;
                end if;
            when read_addr =>
                address_read <= i_data(6 downto 0);
                curr_mem_pos <= (others => '0');
                
                state <= read_wzs;
                o_en <= '1';
                o_address <= (others => '0');
            when read_wzs =>
                if address_read(6 downto 0) = i_data(6 downto 0) then
                    wz_bit <= '1';
                    wz_offset <= "0001";
                    state <= write_res;
                    
                elsif address_read(6 downto 0) = (i_data(6 downto 0) + "1") then
                    wz_bit <= '1';
                    wz_offset <= "0010";
                    state <= write_res;
                    
                elsif address_read(6 downto 0) = (i_data(6 downto 0) + "10") then
                    wz_bit <= '1';
                    wz_offset <= "0100";
                    state <= write_res;
                    
                elsif address_read(6 downto 0) = (i_data(6 downto 0) + "11") then
                    wz_bit <= '1';
                    wz_offset <= "1000";
                    state <= write_res;
                    
                elsif curr_mem_pos = "0000000000000111" then
                    state <= write_res;
                    
                else 
                    curr_mem_pos <= curr_mem_pos + '1';
                    o_en <= '1';
                    o_address <= curr_mem_pos + '1';
                    state <= state;
                end if;
                
            when write_res =>
                -- If a WZ is found then writes in memory the encoded address.
                if (wz_bit = '1') then
                    o_data <= wz_bit & curr_mem_pos(2 downto 0) & wz_offset;
                -- After that it has compared the address_read with all the 8 WZ addresses and doesn't have found a match it writes in memory the address.
                else
                    o_data <= wz_bit & address_read(6 downto 0); 
                end if;
                o_address <= "0000000000001001";
                o_en <= '1';
                o_we <= '1';
                o_done <= '1';
              
                state <= final;
            when final =>
                if i_start = '0' then
                    state <= reset;
                    wz_bit <= '0';
                    wz_offset <= "0000";
                else 
                    state <= state;
                end if;
        end case;
        end if;
        if i_rst='1' then
            state <= reset;
            wz_bit <= '0';
            wz_offset <= "0000";
        end if;
    end process;

end Behavioral;
