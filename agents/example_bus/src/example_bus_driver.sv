`ifndef EXAMPLE_BUS_DRIVER__SV
`define EXAMPLE_BUS_DRIVER__SV

class example_bus_driver extends uvm_driver#(example_bus_seq_item);
  `uvm_component_utils(example_bus_driver)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    example_bus_seq_item tr;
    forever begin
      seq_item_port.get_next_item(tr);
      if (tr == null) begin
        `uvm_warning(get_type_name(), "Received null transaction")
        seq_item_port.item_done();
        continue;
      end

      if (tr.rw == example_bus_seq_item::WRITE) begin
        `uvm_info(get_type_name(),
                  $sformatf("WRITE addr=0x%08h data=0x%08h", tr.addr, tr.wdata),
                  UVM_MEDIUM)
      end else begin
        `uvm_info(get_type_name(),
                  $sformatf("READ  addr=0x%08h -> expect 0x%08h", tr.addr, tr.exp_rdata),
                  UVM_MEDIUM)
      end

      // In a real VIP this is where bus driving would happen.  For the
      // reusable demo we simply complete the item immediately.
      seq_item_port.item_done();
    end
  endtask
endclass

`endif
