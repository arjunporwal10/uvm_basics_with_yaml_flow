`ifndef EXAMPLE_BUS_READ_SEQ__SV
`define EXAMPLE_BUS_READ_SEQ__SV

class example_bus_read_seq extends uvm_sequence#(example_bus_seq_item);
  `uvm_object_utils(example_bus_read_seq)

  rand bit [31:0] addr;
  bit [31:0]      read_value;

  function new(string name = "example_bus_read_seq");
    super.new(name);
  endfunction

  virtual task body();
    example_bus_seq_item tr;
    tr = example_bus_seq_item::type_id::create("tr");
    start_item(tr);
    tr.rw   = example_bus_seq_item::READ;
    tr.addr = addr;
    finish_item(tr);
    // No bus to collect data from; propagate expected placeholder.
    read_value = tr.exp_rdata;
  endtask
endclass

`endif
