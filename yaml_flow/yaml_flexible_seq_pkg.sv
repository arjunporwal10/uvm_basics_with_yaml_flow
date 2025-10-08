package yaml_seq_pkg;
  import uvm_pkg::*;                     `include "uvm_macros.svh"
  import yaml_types_pkg::*;              // yaml_scenario_cfg, payloads, stimulus_action_t
  import action_executors_pkg::*;         // action_executor_registry + executors
  import scenario_config_pkg::*;          // get_scenario_by_name()
  import stimulus_auto_builder_pkg::*;    // default action builder
  import vip_plugins_pkg::*;

  class yaml_flexible_seq extends uvm_sequence #(uvm_sequence_item);
    `uvm_object_utils(yaml_flexible_seq)

    yaml_scenario_cfg   cfg;
    yaml_vip_context    vip_ctx;
    yaml_vip_adapter    vip_adapter;

    static bit s_executors_registered = 0;

    function new(string name = "yaml_flexible_seq");
      super.new(name);
    endfunction

    function void register_executors_once();
      stimulus_action_executor_base h;
      if (s_executors_registered) return;

      h = reset_action_executor         ::type_id::create("exec_reset");
      action_executor_registry::register("RESET", h);
      h = self_check_action_executor    ::type_id::create("exec_self");
      action_executor_registry::register("SELF_CHECK", h);
      h = error_inject_action_executor  ::type_id::create("exec_err");
      action_executor_registry::register("ERROR_INJECTION", h);
      h = traffic_action_executor       ::type_id::create("exec_traf");
      action_executor_registry::register("TRAFFIC", h);
      h = parallel_group_action_executor::type_id::create("exec_par");
      action_executor_registry::register("PARALLEL_GROUP", h);
      h = serial_group_action_executor  ::type_id::create("exec_ser");
      action_executor_registry::register("SERIAL_GROUP", h);
      h = send_wr_action_executor       ::type_id::create("exec_wr");
      action_executor_registry::register("WRITE_TXN", h);
      h = send_rd_action_executor       ::type_id::create("exec_rd");
      action_executor_registry::register("READ_TXN", h);
      h = vip_base_seq_action_executor  ::type_id::create("exec_base");
      action_executor_registry::register("VIP_BASE_SEQ", h);
      h = vip_register_seq_action_executor::type_id::create("exec_reg");
      action_executor_registry::register("VIP_REGISTER_SEQ", h);

      s_executors_registered = 1;
    endfunction

    virtual task body();
      string scen;
      string vip_slot;
      string vendor_name;
      stimulus_action_t list[$];
      int i;
      yaml_vip_adapter proto;

      if (!uvm_config_db#(yaml_scenario_cfg)::get(null, "*", "scenario_cfg", cfg)) begin
        if (!$value$plusargs("SCENARIO=%s", scen)) scen = "reset_traffic";
        cfg = scenario_config_pkg::get_scenario_by_name(scen);
        `uvm_info(get_type_name(), $sformatf("Using scenario: %s (plusarg/default)", scen), UVM_MEDIUM)
      end else begin
        `uvm_info(get_type_name(), $sformatf("Using scenario via config_db: %s", cfg.scenario_name), UVM_MEDIUM)
      end

      vip_slot = "vip0";
      if (!$value$plusargs("VIP_SLOT=%s", vip_slot)) begin
        if ((vip_ctx != null) && (vip_ctx.slot_id != "")) vip_slot = vip_ctx.slot_id;
      end

      if (!uvm_config_db#(yaml_vip_context)::get(null,
                                                 "*",
                                                 $sformatf("vip_context_%s", vip_slot),
                                                 vip_ctx)) begin
        if (!uvm_config_db#(yaml_vip_context)::get(null, "*", "vip_context", vip_ctx)) begin
          vip_ctx = yaml_vip_context::type_id::create($sformatf("vip_ctx_%s", vip_slot));
        end
      end

      if (vip_ctx == null) begin
        vip_ctx = yaml_vip_context::type_id::create($sformatf("vip_ctx_%s_auto", vip_slot));
      end

      vendor_name = "";
      if (!$value$plusargs("VIP_VENDOR=%s", vendor_name)) begin
        if ((vip_ctx != null) && (vip_ctx.vendor_name != "")) vendor_name = vip_ctx.vendor_name;
      end
      if (vendor_name == "") vendor_name = "apb";

      vip_ctx.slot_id     = vip_slot;
      vip_ctx.vendor_name = vendor_name;
      if (vip_ctx.sequencer == null) begin
        vip_ctx.sequencer = m_sequencer;
      end

      uvm_config_db#(yaml_vip_context)::set(null, "*", "vip_context", vip_ctx);
      uvm_config_db#(yaml_vip_context)::set(null, "*", $sformatf("vip_context_%s", vip_slot), vip_ctx);

      proto = yaml_vip_registry::get_adapter(vendor_name);
      if (proto == null) begin
        `uvm_fatal(get_type_name(), $sformatf("No VIP adapter registered for vendor '%s'", vendor_name))
      end

      vip_adapter = yaml_vip_adapter'(proto.clone());
      if (vip_adapter == null) begin
        `uvm_fatal(get_type_name(), $sformatf("Failed to clone VIP adapter for vendor '%s'", vendor_name))
      end
      vip_adapter.set_context(vip_ctx);
      stimulus_action_executor_base::set_adapter(vip_adapter);

      register_executors_once();

      if (cfg.action_list.size() == 0) begin
        `uvm_info(get_type_name(), "Auto-building default action list", UVM_LOW)
        stimulus_auto_builder::build(cfg, cfg.action_list);
      end

      list = cfg.action_list;
      for (i = 0; i < list.size(); i++) begin
        action_executor_registry::dispatch(list[i], this, m_sequencer);
      end
    endtask
  endclass
endpackage
