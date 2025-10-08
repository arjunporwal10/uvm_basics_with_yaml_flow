`ifndef EXAMPLE_TEST_PKG__SV
`define EXAMPLE_TEST_PKG__SV
package example_test_pkg;
  import uvm_pkg::*;
  import example_bus_pkg::*;
  import yaml_seq_pkg::*;
  import scenario_config_pkg::*;
  import vip_plugins_pkg::*;
  import yaml_types_pkg::*;
  import stimulus_auto_builder_pkg::*;

  `include "uvm_macros.svh"

  class example_bus_base_test extends uvm_test;
    `uvm_component_utils(example_bus_base_test)

    example_bus_agent m_agent;

    function new(string name="example_bus_base_test", uvm_component parent=null);
      super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      m_agent = example_bus_agent::type_id::create("example_agent", this);
    endfunction
  endclass

  class example_bus_yaml_test extends example_bus_base_test;
    `uvm_component_utils(example_bus_yaml_test)

    function new(string name="example_bus_yaml_test", uvm_component parent=null);
      super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
      yaml_flexible_seq seq;
      yaml_vip_context  ctx;
      string scen_name;
      yaml_scenario_cfg cfg;

      phase.raise_objection(this);

      seq = yaml_flexible_seq::type_id::create("example_yaml_seq");

      if (!$value$plusargs("SCENARIO=%s", scen_name)) scen_name = "reset_traffic";
      cfg = scenario_config_pkg::get_scenario_by_name(scen_name);
      uvm_config_db#(yaml_scenario_cfg)::set(null, "*", "scenario_cfg", cfg);

      ctx = yaml_vip_context::type_id::create("example_vip_ctx");
      ctx.slot_id     = "vip0";
      ctx.vendor_name = "example";
      ctx.sequencer = m_agent.m_sequencer;
      uvm_config_db#(yaml_vip_context)::set(null, "*", "vip_context", ctx);
      uvm_config_db#(yaml_vip_context)::set(null, "*", "vip_context_vip0", ctx);

      seq.start(m_agent.m_sequencer);

      phase.drop_objection(this);
    endtask
  endclass
endpackage
`endif
