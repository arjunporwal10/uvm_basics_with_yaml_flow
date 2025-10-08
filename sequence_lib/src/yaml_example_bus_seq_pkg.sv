`ifndef YAML_EXAMPLE_BUS_SEQ_PKG__SV
`define YAML_EXAMPLE_BUS_SEQ_PKG__SV
package yaml_example_bus_seq_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import example_bus_pkg::*;

  `include "example_bus_seq_list.sv"

  class yaml_example_direct_write_seq extends example_bus_write_seq;
    `uvm_object_utils(yaml_example_direct_write_seq)

    function new(string name = "yaml_example_direct_write_seq");
      super.new(name);
    endfunction
  endclass

  class yaml_example_direct_read_seq extends example_bus_read_seq;
    `uvm_object_utils(yaml_example_direct_read_seq)

    function new(string name = "yaml_example_direct_read_seq");
      super.new(name);
    endfunction
  endclass
endpackage
`endif
