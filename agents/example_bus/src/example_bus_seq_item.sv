`ifndef EXAMPLE_BUS_SEQ_ITEM__SV
`define EXAMPLE_BUS_SEQ_ITEM__SV

class example_bus_seq_item extends uvm_sequence_item;
  `uvm_object_utils(example_bus_seq_item)

  typedef enum bit { READ = 0, WRITE = 1 } rw_e;

  rand rw_e          rw;
  rand bit [31:0]    addr;
  rand bit [31:0]    wdata;
  rand bit [31:0]    exp_rdata;

  constraint c_defaults {
    addr inside {[32'h0 : 32'hFFFF]};
    wdata inside {[32'h0 : 32'hFFFF_FFFF]};
    exp_rdata inside {[32'h0 : 32'hFFFF_FFFF]};
  }

  function new(string name = "example_bus_seq_item");
    super.new(name);
  endfunction

  virtual function string convert2string();
    string rw_s;
    rw_s = (rw == WRITE) ? "WRITE" : "READ";
    return $sformatf("%s addr=0x%08h wdata=0x%08h exp_rdata=0x%08h", rw_s, addr, wdata, exp_rdata);
  endfunction

endclass

`endif
