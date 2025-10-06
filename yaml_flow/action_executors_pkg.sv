// yaml_flow/action_executors_pkg.sv
package action_executors_pkg;
  import uvm_pkg::*;                 `include "uvm_macros.svh"
  import apb_pkg::*;                  // apb_seq_item / apb_sequencer
  import avry_yaml_types_pkg::*;      // stimulus_action_t, traffic_action_data, parallel_group_t, DIR_*, etc.

  // --------------------------------------------------------------------------
  // Base Executor: stores parent sequence & sequencer; provides helpers
  // --------------------------------------------------------------------------
  class stimulus_action_executor_base extends uvm_object;
    `uvm_object_utils(stimulus_action_executor_base)

    // Context set by registry before execute()
    uvm_sequence_base  m_parent_seq;
    uvm_sequencer_base m_sequencer;

    function new(string name="stimulus_action_executor_base");
      super.new(name);
    endfunction

    virtual task execute(stimulus_action_t a);
      `uvm_fatal(get_type_name(),"execute() not implemented")
    endtask

    protected task send_apb_write(bit [31:0] addr, bit [31:0] data);
      apb_seq_item req;
      if ((m_parent_seq==null) || (m_sequencer==null)) begin
        `uvm_fatal(get_type_name(),"No parent sequence or sequencer bound")
      end
      req = apb_seq_item::type_id::create("req");
      m_parent_seq.start_item(req);
      req.tr_rw    = apb_seq_item::TR_WRITE;
      req.tr_addr  = addr[15:0];
      req.tr_wdata = data[15:0];
      req.tr_error = 0;
      m_parent_seq.finish_item(req);
    endtask
    
    protected task send_apb_read(bit [31:0] addr, output bit [31:0] data);
      apb_seq_item req;
      bit [15:0]   r16;
      if ((m_parent_seq==null) || (m_sequencer==null)) begin
        `uvm_fatal(get_type_name(),"No parent sequence or sequencer bound")
      end
      req = apb_seq_item::type_id::create("req");
      m_parent_seq.start_item(req);
      req.tr_rw    = apb_seq_item::TR_READ;
      req.tr_addr  = addr[15:0];
      req.tr_error = 0;
      m_parent_seq.finish_item(req);
      // If driver fills tr_rdata, collect it:
      r16  = req.tr_rdata;
      data = {16'h0000, r16};
    endtask

  endclass

  // Alias at PACKAGE scope (VCS-friendly)
  typedef stimulus_action_executor_base exec_base_t;

  // --------------------------------------------------------------------------
  // Registry: string -> executor handle
  // --------------------------------------------------------------------------
  class action_executor_registry;
    static exec_base_t m_map[string];

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
      exec_base_t ex;
      if (a == null) begin
        `uvm_error("EXEC_DISP", "Null action")
        return;
      end
      if (!m_map.exists(a.action_type)) begin
        `uvm_error("EXEC_DISP", $sformatf("No executor registered for action_type='%s'", a.action_type))
        return;
      end
      ex = m_map[a.action_type];
      ex.m_parent_seq = parent_seq;
      ex.m_sequencer  = seqr;
      ex.execute(a);
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
      `uvm_info(get_type_name(), "Executing ERROR_INJECTION (placeholder)", UVM_LOW)
    endtask
  endclass

  // --------------------------------------------------------------------------
  // TRAFFIC – portable APB driver via parent sequence
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
    
      `uvm_info(get_type_name(),
                $sformatf("TRAFFIC dir=%s count=%0d",
                          (d.direction==DIR_WRITE)?"WRITE":"READ", d.num_packets),
                UVM_MEDIUM)
    
      if (d.direction == DIR_WRITE) begin
        for (i=0;i<d.num_packets;i++) begin
          send_apb_write(32'h0000_1A00 + i*2, 32'hA5A5_A5A5 + i); // masked in helper
        end
      end else begin
        for (i=0;i<d.num_packets;i++) begin
          send_apb_read(32'h0000_1A00 + i*2, r32);
        end
      end
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

      if (!$cast(grp, a.action_data) || (grp==null)) begin
        `uvm_error(get_type_name(), "Missing/invalid parallel_group_t")
        return;
      end

      `uvm_info(get_type_name(),
                $sformatf("Executing PARALLEL_GROUP (%0d actions)", grp.parallel_actions.size()),
                UVM_LOW)

      fork
        for (j=0; j<grp.parallel_actions.size(); j++) begin : PAR_DO
          automatic stimulus_action_t sub = grp.parallel_actions[j];
          fork
            action_executor_registry::dispatch(sub, m_parent_seq, m_sequencer);
          join_none
        end
      join
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

      `uvm_info(get_type_name(),
                $sformatf("Executing SERIAL_GROUP (%0d actions)", grp.parallel_actions.size()),
                UVM_LOW)

      for (j=0; j<grp.parallel_actions.size(); j++) begin
        action_executor_registry::dispatch(grp.parallel_actions[j], m_parent_seq, m_sequencer);
      end
    endtask
  endclass

endpackage

