// yaml_flow/action_executors_pkg.sv
package action_executors_pkg;
  import uvm_pkg::*;                 `include "uvm_macros.svh"
  import yaml_types_pkg::*;          // stimulus_action_t, traffic_action_data, parallel_group_t, DIR_*, etc.
  import vip_plugins_pkg::*;
  import scenario_config_pkg::*;
  import stimulus_auto_builder_pkg::*;

  // --------------------------------------------------------------------------
  // Base Executor: stores parent sequence & sequencer; provides helpers
  // --------------------------------------------------------------------------
  class stimulus_action_executor_base extends uvm_object;
    `uvm_object_utils(stimulus_action_executor_base)

    // Context set by registry before execute()
    uvm_sequence_base  m_parent_seq;
    uvm_sequencer_base m_sequencer;

    static yaml_vip_adapter m_adapter;

    function new(string name="stimulus_action_executor_base");
      super.new(name);
    endfunction

    virtual task execute(stimulus_action_t a);
      `uvm_fatal(get_type_name(),"execute() not implemented")
    endtask

    protected task send_bus_write(bit [31:0] addr, bit [31:0] data);
      if ((m_parent_seq==null) || (m_sequencer==null)) begin
        `uvm_fatal(get_type_name(),"No parent sequence or sequencer bound")
      end
      if (m_adapter == null) begin
        `uvm_fatal(get_type_name(),"No VIP adapter configured for bus write")
      end
      m_adapter.send_write(m_parent_seq, m_sequencer, addr, data);
    endtask

    protected task send_bus_read(bit [31:0] addr, output bit [31:0] data);
      if ((m_parent_seq==null) || (m_sequencer==null)) begin
        `uvm_fatal(get_type_name(),"No parent sequence or sequencer bound")
      end
      if (m_adapter == null) begin
        `uvm_fatal(get_type_name(),"No VIP adapter configured for bus read")
      end
      m_adapter.send_read(m_parent_seq, m_sequencer, addr, data);
    endtask

    static function void set_adapter(yaml_vip_adapter adapter);
      m_adapter = adapter;
    endfunction

    static function yaml_vip_adapter get_adapter();
      return m_adapter;
    endfunction

  endclass

  // Alias at PACKAGE scope (VCS-friendly)
  typedef stimulus_action_executor_base exec_base_t;

  // --------------------------------------------------------------------------
  // Registry: string -> executor handle
  // --------------------------------------------------------------------------
  class action_executor_registry;
    static exec_base_t m_map[string];
    static int unsigned m_next_inst_id = 0;

    // Register a handle (constructed with proper new(string name))
    static function void register(string key, exec_base_t h);
      if (h == null) begin
        `uvm_fatal("EXEC_REG", $sformatf("Null executor for key '%s'", key))
      end
      m_map[key] = h;
    endfunction

    static function exec_base_t get(string key);
      if (!m_map.exists(key)) return null;
      return m_map[key];
    endfunction

    // Dispatch one action using the provided parent sequence & sequencer
    static task dispatch(stimulus_action_t a,
                         uvm_sequence_base  parent_seq,
                         uvm_sequencer_base seqr);
      exec_base_t proto;
      exec_base_t ex;
      int unsigned repeat_count;
      int unsigned idx;
      if (a == null) begin
        `uvm_error("EXEC_DISP", "Null action")
        return;
      end
      if (!m_map.exists(a.action_type)) begin
        `uvm_error("EXEC_DISP", $sformatf("No executor registered for action_type='%s'", a.action_type))
        return;
      end
      proto = m_map[a.action_type];
      if (proto == null) begin
        `uvm_error("EXEC_DISP", $sformatf("Executor prototype for action_type='%s' is null", a.action_type))
        return;
      end

      repeat_count = (a.repeat_count == 0) ? 1 : a.repeat_count;

      `uvm_info("EXEC_DISP",
                $sformatf("Dispatching action_type='%s' %0d time(s)",
                          a.action_type, repeat_count),
                UVM_DEBUG);

      for (idx = 0; idx < repeat_count; idx++) begin
        // Clone the prototype so that each dispatch gets an isolated
        // executor instance.  This avoids shared state when multiple
        // actions (e.g. from a PARALLEL_GROUP) execute concurrently.
        ex = exec_base_t'(proto.clone());
        if (ex == null) begin
          `uvm_error("EXEC_DISP", $sformatf("Failed to clone executor for action_type='%s'", a.action_type))
          return;
        end
        ex.set_name($sformatf("%s_exec_%0d", a.action_type, m_next_inst_id++));
        ex.m_parent_seq = parent_seq;
        ex.m_sequencer  = seqr;
        ex.execute(a);
      end
    endtask

  endclass

  // Proxy sequence to execute one stimulus_action_t on a sequencer
  class exec_proxy_seq extends uvm_sequence #(uvm_sequence_item);
    `uvm_object_utils(exec_proxy_seq)
    stimulus_action_t m_sub;
  
    function new(string name="exec_proxy_seq");
      super.new(name);
    endfunction
  
    virtual task body();
      // Dispatch using this sequence as the parent, so the sequencer
      // can arbitrate between multiple exec_proxy_seq in parallel.
      action_executor_registry::dispatch(m_sub, this, m_sequencer);
    endtask
  endclass

  // --------------------------------------------------------------------------
  // RESET (placeholder)
  // --------------------------------------------------------------------------
  class reset_action_executor extends stimulus_action_executor_base;
    `uvm_object_utils(reset_action_executor)
    function new(string name="reset_action_executor"); super.new(name); endfunction
    virtual task execute(stimulus_action_t a);
      time delay_t;
      `uvm_info(get_type_name(), "-> RESET", UVM_MEDIUM)
      `uvm_info(get_type_name(), "Executing RESET (placeholder)", UVM_LOW)
      delay_t = 10ns; // Replace with TB clocked reset if you wire in a vif
      #delay_t;
    endtask
  endclass

  // --------------------------------------------------------------------------
  // SELF_CHECK (placeholder)
  // --------------------------------------------------------------------------
  class self_check_action_executor extends stimulus_action_executor_base;
    `uvm_object_utils(self_check_action_executor)
    function new(string name="self_check_action_executor"); super.new(name); endfunction
    virtual task execute(stimulus_action_t a);
      `uvm_info(get_type_name(), "-> SELF_CHECK", UVM_MEDIUM)
      `uvm_info(get_type_name(), "Executing SELF_CHECK (placeholder)", UVM_LOW)
    endtask
  endclass

  // --------------------------------------------------------------------------
  // ERROR_INJECTION (placeholder)
  // --------------------------------------------------------------------------
  class error_inject_action_executor extends stimulus_action_executor_base;
    `uvm_object_utils(error_inject_action_executor)
    function new(string name="error_inject_action_executor"); super.new(name); endfunction
    virtual task execute(stimulus_action_t a);
      `uvm_info(get_type_name(), "-> ERROR_INJECTION", UVM_MEDIUM)
      `uvm_info(get_type_name(), "Executing ERROR_INJECTION (placeholder)", UVM_LOW)
    endtask
  endclass

  // --------------------------------------------------------------------------
  // WRITE_TXN – portable bus driver via parent sequence
  // --------------------------------------------------------------------------
  class send_wr_action_executor extends stimulus_action_executor_base;
    `uvm_object_utils(send_wr_action_executor)
    function new(string name="send_wr_action_executor"); super.new(name); endfunction
    virtual task execute(stimulus_action_t a);
      traffic_action_data d;

      if (!$cast(d, a.action_data)) begin
        `uvm_error(get_type_name(), "Missing/invalid traffic_action_data")
        return;
      end

      `uvm_info(get_type_name(),
                $sformatf("-> WRITE TXN"), UVM_MEDIUM)

      send_bus_write(d.addr_base , d.data_pattern );
    endtask
  endclass
  // --------------------------------------------------------------------------
  // READ_TXN – portable bus driver via parent sequence
  // --------------------------------------------------------------------------
  class send_rd_action_executor extends stimulus_action_executor_base;
    `uvm_object_utils(send_rd_action_executor)
    function new(string name="send_rd_action_executor"); super.new(name); endfunction
    virtual task execute(stimulus_action_t a);
      traffic_action_data d;
      bit [31:0] r32;
    
      if (!$cast(d, a.action_data)) begin
        `uvm_error(get_type_name(), "Missing/invalid traffic_action_data")
        return;
      end

      `uvm_info(get_type_name(),
                $sformatf("-> READ TXN"), UVM_MEDIUM)

      send_bus_read(d.addr_base , r32);
    endtask
  endclass

  // --------------------------------------------------------------------------
  // TRAFFIC – portable bus driver via parent sequence
  // --------------------------------------------------------------------------
  class traffic_action_executor extends stimulus_action_executor_base;
    `uvm_object_utils(traffic_action_executor)
    function new(string name="traffic_action_executor"); super.new(name); endfunction
    virtual task execute(stimulus_action_t a);
      traffic_action_data d;
      integer i;
      bit [31:0] r32;
    
      if (!$cast(d, a.action_data)) begin
        `uvm_error(get_type_name(), "Missing/invalid traffic_action_data")
        return;
      end

      `uvm_info(get_type_name(), "-> TRAFFIC", UVM_MEDIUM)
      `uvm_info(get_type_name(),
                $sformatf("TRAFFIC dir=%s count=%0d",
                          (d.direction==DIR_WRITE)?"WRITE":"READ", d.num_packets),
                UVM_MEDIUM)
    
      if (d.direction == DIR_WRITE) begin
        for (i=0;i<d.num_packets;i++) begin
          send_bus_write(d.addr_base + i*2, d.data_pattern + i); // masked in helper
        end
      end else begin
        for (i=0;i<d.num_packets;i++) begin
          send_bus_read(d.addr_base + i*2, r32);
        end
      end
    endtask

  endclass

  // --------------------------------------------------------------------------
  // VIP_BASE_SEQ – delegate to the active VIP adapter
  // --------------------------------------------------------------------------
  class vip_base_seq_action_executor extends stimulus_action_executor_base;
    `uvm_object_utils(vip_base_seq_action_executor)

    function new(string name="vip_base_seq_action_executor");
      super.new(name);
    endfunction

    virtual task execute(stimulus_action_t a);
      base_seq_action_data d;
      yaml_vip_adapter     adapter;

      if ((m_parent_seq==null) || (m_sequencer==null)) begin
        `uvm_error(get_type_name(), "No parent sequence or sequencer bound")
        return;
      end

      adapter = get_adapter();
      if (adapter == null) begin
        `uvm_error(get_type_name(), "No VIP adapter configured for BASE sequence")
        return;
      end

      `uvm_info(get_type_name(), "-> VIP_BASE_SEQ", UVM_MEDIUM)
      if (!$cast(d, a.action_data)) d = null;
      adapter.start_base_sequence(m_parent_seq, m_sequencer, d);
    endtask
  endclass

  // --------------------------------------------------------------------------
  // VIP_REGISTER_SEQ – delegate to the active VIP adapter
  // --------------------------------------------------------------------------
  class vip_register_seq_action_executor extends stimulus_action_executor_base;
    `uvm_object_utils(vip_register_seq_action_executor)

    function new(string name="vip_register_seq_action_executor");
      super.new(name);
    endfunction

    virtual task execute(stimulus_action_t a);
      register_seq_action_data d;
      yaml_vip_adapter         adapter;

      if ((m_parent_seq==null) || (m_sequencer==null)) begin
        `uvm_error(get_type_name(), "No parent sequence or sequencer bound")
        return;
      end

      adapter = get_adapter();
      if (adapter == null) begin
        `uvm_error(get_type_name(), "No VIP adapter configured for REGISTER sequence")
        return;
      end

      `uvm_info(get_type_name(), "-> VIP_REGISTER_SEQ", UVM_MEDIUM)
      if (!$cast(d, a.action_data)) d = null;
      adapter.start_register_sequence(m_parent_seq, m_sequencer, d);
    endtask
  endclass

  // --------------------------------------------------------------------------
  // SCENARIO_INCLUDE – execute actions from another scenario
  // --------------------------------------------------------------------------
  class scenario_include_action_executor extends stimulus_action_executor_base;
    `uvm_object_utils(scenario_include_action_executor)

    static string m_include_stack[string][$];

    function new(string name="scenario_include_action_executor");
      super.new(name);
    endfunction

    static function string get_seq_key(uvm_sequence_base seq);
      string key;
      if (seq == null) return "global";
      key = seq.get_full_name();
      if (key == "") key = seq.get_name();
      if (key == "") key = $sformatf("%s@%0h", seq.get_type_name(), seq);
      return key;
    endfunction

    virtual task execute(stimulus_action_t a);
      scenario_include_action_data d;
      yaml_scenario_cfg            child_cfg;
      string                       key;
      string                       path_desc;
      int                          i;
      int                          j;

      if (!$cast(d, a.action_data) || (d == null)) begin
        `uvm_error(get_type_name(), "Missing/invalid scenario include payload")
        return;
      end

      if (d.scenario_name == "") begin
        `uvm_error(get_type_name(), "SCENARIO_INCLUDE missing scenario_name")
        return;
      end

      key = get_seq_key(m_parent_seq);

      foreach (m_include_stack[key][i]) begin
        if (m_include_stack[key][i] == d.scenario_name) begin
          path_desc = "";
          for (j = 0; j < m_include_stack[key].size(); j++) begin
            if (j != 0) path_desc = {path_desc, " -> "};
            path_desc = {path_desc, m_include_stack[key][j]};
          end
          if (path_desc != "") path_desc = {path_desc, " -> "};
          path_desc = {path_desc, d.scenario_name};
          `uvm_error(get_type_name(), $sformatf("Recursive scenario include detected: %s", path_desc))
          return;
        end
      end

      `uvm_info(get_type_name(),
                $sformatf("-> SCENARIO_INCLUDE '%s'", d.scenario_name),
                UVM_MEDIUM)

      m_include_stack[key].push_back(d.scenario_name);

      child_cfg = scenario_config_pkg::get_scenario_by_name(d.scenario_name);
      if ((child_cfg == null) || (child_cfg.scenario_name != d.scenario_name)) begin
        `uvm_error(get_type_name(),
                  $sformatf("Scenario '%s' not found for include", d.scenario_name))
        m_include_stack[key].pop_back();
        if (m_include_stack[key].size() == 0) m_include_stack.delete(key);
        return;
      end

      if (child_cfg.action_list.size() == 0) begin
        `uvm_info(get_type_name(),
                  $sformatf("Auto-building child scenario '%s'", d.scenario_name),
                  UVM_LOW)
        stimulus_auto_builder::build(child_cfg, child_cfg.action_list);
      end

      for (i = 0; i < child_cfg.action_list.size(); i++) begin
        action_executor_registry::dispatch(child_cfg.action_list[i], m_parent_seq, m_sequencer);
      end

      m_include_stack[key].pop_back();
      if (m_include_stack[key].size() == 0) m_include_stack.delete(key);
    endtask
  endclass

  // --------------------------------------------------------------------------
  // PARALLEL_GROUP
  // --------------------------------------------------------------------------
  class parallel_group_action_executor extends stimulus_action_executor_base;
    `uvm_object_utils(parallel_group_action_executor)
    function new(string name="parallel_group_action_executor"); super.new(name); endfunction
  
    virtual task execute(stimulus_action_t a);
      parallel_group_t grp;
      int j;
  
      if (!$cast(grp, a.action_data)) begin
        `uvm_error(get_type_name(), "Missing/invalid parallel_group_t")
        return;
      end
      `uvm_info(get_type_name(), "-> PARALLEL_GROUP", UVM_MEDIUM)
      `uvm_info(get_type_name(),
                $sformatf("Executing PARALLEL_GROUP (%0d actions)", grp.parallel_actions.size()),
                UVM_LOW)
  
      // Launch each sub-action as its own child sequence on the same sequencer.
      // Use fork/join_none so that every proxy starts in its own process and
      // the sequencer can arbitrate between them, allowing true parallelism.
      for (j = 0; j < grp.parallel_actions.size(); j++) begin
        automatic stimulus_action_t sub = grp.parallel_actions[j];
        automatic exec_proxy_seq    proxy =
            exec_proxy_seq::type_id::create($sformatf("proxy_%0d", j));
        proxy.m_sub = sub;
        fork
          proxy.start(m_sequencer); // start on the same sequencer
        join_none
      end

      // Ensure we wait for all forked proxy sequences to finish before
      // returning to the caller.
      wait fork;
    endtask
  endclass

  // --------------------------------------------------------------------------
  // SERIAL_GROUP (re-uses parallel_group_t container as an ordered list)
  // --------------------------------------------------------------------------
  class serial_group_action_executor extends stimulus_action_executor_base;
    `uvm_object_utils(serial_group_action_executor)
    function new(string name="serial_group_action_executor"); super.new(name); endfunction
    virtual task execute(stimulus_action_t a);
      parallel_group_t grp; // ordered list
      int j;

      if (!$cast(grp, a.action_data) || (grp==null)) begin
        `uvm_error(get_type_name(), "Missing/invalid serial list payload")
        return;
      end

      `uvm_info(get_type_name(), "-> SERIAL_GROUP", UVM_MEDIUM)
      `uvm_info(get_type_name(),
                $sformatf("Executing SERIAL_GROUP (%0d actions)", grp.parallel_actions.size()),
                UVM_LOW)

      for (j=0; j<grp.parallel_actions.size(); j++) begin
        action_executor_registry::dispatch(grp.parallel_actions[j], m_parent_seq, m_sequencer);
      end
    endtask
  endclass

endpackage

