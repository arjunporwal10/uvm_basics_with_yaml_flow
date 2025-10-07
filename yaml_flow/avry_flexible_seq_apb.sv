// yaml_flow/avry_flexible_seq_apb.sv
package avry_yaml_seq_pkg;
  import uvm_pkg::*;                     `include "uvm_macros.svh"
  import apb_pkg::*;                      // apb_seq_item, apb_sequencer
  import apb_regs_pkg::*;                 // register block type
  import env_pkg::*;                      // environment types
  import avry_yaml_types_pkg::*;          // avry_scenario_cfg, payloads, stimulus_action_t
  import action_executors_pkg::*;         // action_executor_registry + executors
  import scenario_config_pkg::*;          // get_scenario_by_name()
  import stimulus_auto_builder_pkg::*;    // default action builder

  // Flexible action-driven APB sequence
  class avry_flexible_seq_apb extends uvm_sequence #(apb_seq_item);
    `uvm_object_utils(avry_flexible_seq_apb)

    // Scenario config selected from config_db or +SCENARIO
    avry_scenario_cfg cfg;
    apb_reg_block     reg_block;

    function new(string name = "avry_flexible_seq_apb");
      super.new(name);
    endfunction

    // ------------------------------------------------------------------------
    // Register all executors (once per run)
    // ------------------------------------------------------------------------
    function void register_executors_once();
      stimulus_action_executor_base h;
      if (action_executor_registry::get("RESET") == null) begin
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
        h = apb_base_seq_action_executor  ::type_id::create("exec_base");
        action_executor_registry::register("APB_BASE_SEQ", h);
        h = apb_register_seq_action_executor::type_id::create("exec_reg");
        action_executor_registry::register("APB_REGISTER_SEQ", h);
      end
    endfunction

    // ------------------------------------------------------------------------
    // Main body: choose scenario, register executors, run action list
    // ------------------------------------------------------------------------
    virtual task body();
      string scen;
      stimulus_action_t list[$];
      int i;

      // 1) Prefer config_db injection
      if (!uvm_config_db#(avry_scenario_cfg)::get(null, "*", "scenario_cfg", cfg)) begin
        // 2) Else +SCENARIO=..., default "reset_traffic"
        if (!$value$plusargs("SCENARIO=%s", scen)) scen = "reset_traffic";
        cfg = scenario_config_pkg::get_scenario_by_name(scen);
        `uvm_info(get_type_name(), $sformatf("Using scenario: %s (plusarg/default)", scen), UVM_MEDIUM)
      end else begin
        `uvm_info(get_type_name(), $sformatf("Using scenario via config_db: %s", cfg.scenario_name), UVM_MEDIUM)
      end

      // Executors must be available before running the list
      register_executors_once();
      stimulus_action_executor_base::set_reg_block(reg_block);
      `uvm_info(get_type_name(),
        $sformatf("cfg '%s' has %0d actions", cfg.scenario_name, cfg.action_list.size()),
        UVM_LOW)

      // Auto-build default if empty
      if (cfg.action_list.size() == 0) begin
        `uvm_info(get_type_name(), "Auto-building default action list", UVM_LOW)
        stimulus_auto_builder::build(cfg, cfg.action_list);
      end

      // Run the action list (serial at top level; groups handle parallel/serial internally)
      list = cfg.action_list;
      for (i = 0; i < list.size(); i++) begin
        action_executor_registry::dispatch(list[i], this, m_sequencer);
      end
    endtask

    // =========================================================================
    // Helper tasks that executors may call (owning-sequence context)
    // =========================================================================

    // Light reset (adapt to your APB env if you expose a vif on the sequencer)
    virtual task do_reset();
      `uvm_info(get_type_name(), "APB soft reset (placeholder)", UVM_LOW)
      // Example if your sequencer stores a vif:
      // if (p_sequencer != null && p_sequencer.vif != null) begin
      //   p_sequencer.vif.rst_n <= 0; repeat (2) @(posedge p_sequencer.vif.clk);
      //   p_sequencer.vif.rst_n <= 1; repeat (2) @(posedge p_sequencer.vif.clk);
      // end
    endtask

    virtual task do_self_check();
      `uvm_info(get_type_name(), "SELF_CHECK (placeholder)", UVM_LOW)
      // Hook to scoreboard or coverage if available
    endtask

    virtual task do_error_injection();
      `uvm_info(get_type_name(), "ERROR_INJECTION (placeholder)", UVM_LOW)
    endtask

    // Simple register write helper (matches apb_seq_item fields)
    virtual task do_reg_write(bit [31:0] addr, bit [31:0] data);
      apb_seq_item  req;
      logic [15:0]  addr16, data16;
      addr16 = addr[15:0];
      data16 = data[15:0];
    
      req = apb_seq_item::type_id::create("regw");
      start_item(req);
      req.tr_rw    = apb_seq_item::TR_WRITE;
      req.tr_addr  = addr16;
      req.tr_wdata = data16;
      req.tr_error = 0;
      finish_item(req);
    endtask
    
    // Simple register read helper
    virtual task do_reg_read(bit [31:0] addr);
      apb_seq_item  req;
      logic [15:0]  addr16;
      addr16 = addr[15:0];
    
      req = apb_seq_item::type_id::create("regr");
      start_item(req);
      req.tr_rw    = apb_seq_item::TR_READ;
      req.tr_addr  = addr16;
      req.tr_error = 0;
      finish_item(req);
    endtask
    
    // Traffic generator (WRITE/READ using tr_* fields)
    virtual task do_traffic(dir_e dir, int num_pkts);
      apb_seq_item  req;
      int           i;
      bit           is_write;
      logic [15:0]  a16, d16;
    
      is_write = (dir == DIR_WRITE);
      `uvm_info(get_type_name(),
        $sformatf("TRAFFIC dir=%s num_pkts=%0d", is_write?"WRITE":"READ", num_pkts),
        UVM_LOW)
    
      for (i = 0; i < num_pkts; i++) begin
        // mask to 16-bit to match item’s fields (avoids X/illegal index issues)
        a16 = (cfg.addr_base + i*2) & 16'hFFFF;
        d16 = (cfg.data_pattern ^ i) & 16'hFFFF;
    
        req = apb_seq_item::type_id::create($sformatf("pkt_%0d", i));
        start_item(req);
        req.tr_rw    = is_write ? apb_seq_item::TR_WRITE : apb_seq_item::TR_READ;
        req.tr_addr  = a16;
        if (is_write) req.tr_wdata = d16;
        req.tr_error = 0;
        finish_item(req);
      end
    endtask


  endclass
endpackage

