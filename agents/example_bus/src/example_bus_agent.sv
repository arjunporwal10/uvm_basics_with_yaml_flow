`ifndef EXAMPLE_BUS_AGENT__SV
`define EXAMPLE_BUS_AGENT__SV

class example_bus_agent extends uvm_agent;
  `uvm_component_utils(example_bus_agent)

  example_bus_sequencer m_sequencer;
  example_bus_driver    m_driver;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_sequencer = example_bus_sequencer::type_id::create("m_sequencer", this);
    m_driver    = example_bus_driver   ::type_id::create("m_driver",    this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (m_driver != null && m_sequencer != null) begin
      m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
    end
  endfunction
endclass

`endif
