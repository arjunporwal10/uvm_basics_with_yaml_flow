`ifndef EXAMPLE_BUS_WRITE_SEQ__SV
`define EXAMPLE_BUS_WRITE_SEQ__SV

class example_bus_write_seq extends uvm_sequence#(example_bus_seq_item);
  `uvm_object_utils(example_bus_write_seq)

  rand bit [31:0] addr;
  rand bit [31:0] data;

  function new(string name = "example_bus_write_seq");
    super.new(name);
  endfunction

  virtual task body();
    example_bus_seq_item tr;
    tr = example_bus_seq_item::type_id::create("tr");
    start_item(tr);
    tr.rw   = example_bus_seq_item::WRITE;
    tr.addr = addr;
    tr.wdata = data;
    finish_item(tr);
  endtask
endclass

`endif
