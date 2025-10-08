`ifndef YAML_APB_SEQ_PKG__SV
`define YAML_APB_SEQ_PKG__SV
package yaml_apb_seq_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import apb_pkg::*;
  import apb_regs_pkg::*;
  import apb_test_pkg::*;
  import chip_seq_lib_pkg::*;

  // Reuse the existing APB sequence library that lives under the agent.
  `include "apb_seq_list.sv"

  // --------------------------------------------------------------------------
  // Lightweight sequences used by the YAML VIP adapter.  They provide a
  // consistent programming model where the adapter can simply set address/data
  // fields and start the sequence on the selected sequencer.
  // --------------------------------------------------------------------------
  class yaml_apb_direct_write_seq extends uvm_sequence#(apb_seq_item);
    `uvm_object_utils(yaml_apb_direct_write_seq)

    rand bit [31:0] addr;
    rand bit [31:0] data;

    function new(string name = "yaml_apb_direct_write_seq");
      super.new(name);
    endfunction

    virtual task body();
      apb_seq_item tr;
      tr = apb_seq_item::type_id::create("tr");
      start_item(tr);
      tr.tr_rw    = apb_seq_item::TR_WRITE;
      tr.tr_addr  = addr[15:0];
      tr.tr_wdata = data[15:0];
      tr.tr_error = 0;
      finish_item(tr);
    endtask
  endclass

  class yaml_apb_direct_read_seq extends uvm_sequence#(apb_seq_item);
    `uvm_object_utils(yaml_apb_direct_read_seq)

    rand bit [31:0] addr;
    bit  [31:0] read_data;

    function new(string name = "yaml_apb_direct_read_seq");
      super.new(name);
    endfunction

    virtual task body();
      apb_seq_item tr;
      tr = apb_seq_item::type_id::create("tr");
      start_item(tr);
      tr.tr_rw    = apb_seq_item::TR_READ;
      tr.tr_addr  = addr[15:0];
      tr.tr_error = 0;
      finish_item(tr);
      read_data = {16'h0, tr.tr_rdata};
    endtask
  endclass

endpackage
`endif
