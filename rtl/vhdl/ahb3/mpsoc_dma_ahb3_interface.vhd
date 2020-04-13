-- Converted from rtl/verilog/ahb3/mpsoc_dma_ahb3_interface.sv
-- by verilog2vhdl - QueenField

--//////////////////////////////////////////////////////////////////////////////
--                                            __ _      _     _               //
--                                           / _(_)    | |   | |              //
--                __ _ _   _  ___  ___ _ __ | |_ _  ___| | __| |              //
--               / _` | | | |/ _ \/ _ \ '_ \|  _| |/ _ \ |/ _` |              //
--              | (_| | |_| |  __/  __/ | | | | | |  __/ | (_| |              //
--               \__, |\__,_|\___|\___|_| |_|_| |_|\___|_|\__,_|              //
--                  | |                                                       //
--                  |_|                                                       //
--                                                                            //
--                                                                            //
--              MPSoC-RISCV CPU                                               //
--              Direct Access Memory Interface                                //
--              AMBA3 AHB-Lite Bus Interface                                  //
--                                                                            //
--//////////////////////////////////////////////////////////////////////////////

-- Copyright (c) 2018-2019 by the author(s)
-- *
-- * Permission is hereby granted, free of charge, to any person obtaining a copy
-- * of this software and associated documentation files (the "Software"), to deal
-- * in the Software without restriction, including without limitation the rights
-- * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- * copies of the Software, and to permit persons to whom the Software is
-- * furnished to do so, subject to the following conditions:
-- *
-- * The above copyright notice and this permission notice shall be included in
-- * all copies or substantial portions of the Software.
-- *
-- * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- * THE SOFTWARE.
-- *
-- * =============================================================================
-- * Author(s):
-- *   Francisco Javier Reina Campo <frareicam@gmail.com>
-- */

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.mpsoc_dma_pkg.all;

entity mpsoc_dma_ahb3_interface is
  generic (
    ADDR_WIDTH             : integer := 64;
    DATA_WIDTH             : integer := 64;
    TABLE_ENTRIES          : integer := 4;
    TABLE_ENTRIES_PTRWIDTH : integer := 2;
    TILEID                 : integer := 0
    );
  port (
    clk : in std_logic;
    rst : in std_logic;

    ahb3_if_haddr     : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    ahb3_if_hrdata    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    ahb3_if_hmastlock : in  std_logic;
    ahb3_if_hsel      : in  std_logic;
    ahb3_if_hwrite    : in  std_logic;
    ahb3_if_hwdata    : out std_logic_vector(DATA_WIDTH-1 downto 0);
    ahb3_if_hready    : out std_logic;

    if_write_req    : out std_logic_vector(DMA_REQUEST_WIDTH-1 downto 0);
    if_write_pos    : out std_logic_vector(TABLE_ENTRIES_PTRWIDTH-1 downto 0);
    if_write_select : out std_logic_vector(DMA_REQMASK_WIDTH-1 downto 0);
    if_write_en     : out std_logic;

    -- Interface read (status) interface
    if_valid_pos  : out std_logic_vector(TABLE_ENTRIES_PTRWIDTH-1 downto 0);
    if_valid_set  : out std_logic;
    if_valid_en   : out std_logic;
    if_validrd_en : out std_logic;

    done : in std_logic_vector(TABLE_ENTRIES-1 downto 0)
    );
end mpsoc_dma_ahb3_interface;

architecture RTL of mpsoc_dma_ahb3_interface is

  --////////////////////////////////////////////////////////////////
  --
  -- Variables
  --
  signal if_valid_pos_sgn : std_logic_vector(TABLE_ENTRIES_PTRWIDTH-1 downto 0);

begin
  --////////////////////////////////////////////////////////////////
  --
  -- Module body
  --
  if_write_req <= ('0' & ahb3_if_hrdata(DMA_REQFIELD_LADDR_WIDTH-1 downto 0) &
                   ahb3_if_hrdata(DMA_REQFIELD_SIZE_WIDTH-1 downto 0) &
                   ahb3_if_hrdata(DMA_REQFIELD_RTILE_WIDTH-1 downto 0) &
                   ahb3_if_hrdata(DMA_REQFIELD_RADDR_WIDTH-1 downto 0) & ahb3_if_hrdata(0));

  if_write_pos <= ahb3_if_haddr(TABLE_ENTRIES_PTRWIDTH+4 downto 5);  -- ptrwidth MUST be <= 7 (=128 entries)
  if_write_en  <= ahb3_if_hmastlock and ahb3_if_hsel and ahb3_if_hwrite;

  if_valid_pos_sgn <= ahb3_if_haddr(TABLE_ENTRIES_PTRWIDTH+4 downto 5);  -- ptrwidth MUST be <= 7 (=128 entries)
  if_valid_en      <= ahb3_if_hmastlock and ahb3_if_hsel and to_stdlogic(ahb3_if_haddr(4 downto 0) = "10100") and ahb3_if_hwrite;
  if_validrd_en    <= ahb3_if_hmastlock and ahb3_if_hsel and to_stdlogic(ahb3_if_haddr(4 downto 0) = "10100") and not ahb3_if_hwrite;
  if_valid_set     <= ahb3_if_hwrite or (not ahb3_if_hwrite and not done(to_integer(unsigned(if_valid_pos_sgn))));
  if_valid_pos     <= if_valid_pos_sgn;

  ahb3_if_hready <= ahb3_if_hmastlock and ahb3_if_hsel;

  processing_0 : process (done, if_valid_pos_sgn)
  begin
    if (ahb3_if_haddr(4 downto 0) = "10100") then
      ahb3_if_hwdata <= ((DATA_WIDTH-1 downto 0 => '0') & done(to_integer(unsigned(if_valid_pos_sgn))));
    end if;
  end process;

  -- This assumes, that mask and address match
  generating_0 : for i in 0 to DMA_REQMASK_WIDTH - 1 generate
    if_write_select(i) <= to_stdlogic(unsigned(ahb3_if_haddr(4 downto 2)) = to_unsigned(i, 3));
  end generate;
end RTL;
