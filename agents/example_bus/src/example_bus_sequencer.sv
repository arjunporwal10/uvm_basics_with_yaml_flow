`ifndef EXAMPLE_BUS_SEQUENCER__SV
`define EXAMPLE_BUS_SEQUENCER__SV

class example_bus_sequencer extends uvm_sequencer#(example_bus_seq_item);
  `uvm_component_utils(example_bus_sequencer)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass

`endif
