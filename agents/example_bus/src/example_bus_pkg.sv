`ifndef EXAMPLE_BUS_PKG__SV
`define EXAMPLE_BUS_PKG__SV
package example_bus_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "example_bus_seq_item.sv"
  `include "example_bus_sequencer.sv"
  `include "example_bus_driver.sv"
  `include "example_bus_agent.sv"
endpackage
`endif
