// yaml_flow/action_executors_pkg.sv
package action_executors_pkg;
  import uvm_pkg::*;                 `include "uvm_macros.svh"
  import apb_pkg::*;                  // apb_seq_item / apb_sequencer
  import apb_regs_pkg::*;             // apb_reg_block
  import chip_seq_lib_pkg::*;         // apb_register_seq
  import apb_test_pkg::*;             // apb_override_tr
  import avry_yaml_types_pkg::*;      // stimulus_action_t, traffic_action_data, parallel_group_t, DIR_*, etc.

  // --------------------------------------------------------------------------
  // Base Executor: stores parent sequence & sequencer; provides helpers
  // --------------------------------------------------------------------------
  class stimulus_action_executor_base extends uvm_object;
    `uvm_object_utils(stimulus_action_executor_base)

    // Context set by registry before execute()
    uvm_sequence_base  m_parent_seq;
    uvm_sequencer_base m_sequencer;

    static apb_reg_block m_reg_block;

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

    static function void set_reg_block(apb_reg_block blk);
      m_reg_block = blk;
    endfunction

    static function apb_reg_block get_reg_block();
      return m_reg_block;
    endfunction

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

  // Proxy sequence to execute one stimulus_action_t on a sequencer
  class exec_proxy_seq extends uvm_sequence #(apb_seq_item);
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
  // WRITE_TXN – portable APB driver via parent sequence
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

      send_apb_write(d.addr_base , d.data_pattern );
    endtask
  endclass
  // --------------------------------------------------------------------------
  // READ_TXN – portable APB driver via parent sequence
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

      send_apb_read(d.addr_base , r32);
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

      `uvm_info(get_type_name(), "-> TRAFFIC", UVM_MEDIUM)
      `uvm_info(get_type_name(),
                $sformatf("TRAFFIC dir=%s count=%0d",
                          (d.direction==DIR_WRITE)?"WRITE":"READ", d.num_packets),
                UVM_MEDIUM)
    
      if (d.direction == DIR_WRITE) begin
        for (i=0;i<d.num_packets;i++) begin
          send_apb_write(d.addr_base + i*2, d.data_pattern + i); // masked in helper
        end
      end else begin
        for (i=0;i<d.num_packets;i++) begin
          send_apb_read(d.addr_base + i*2, r32);
        end
      end
    endtask

  endclass

  // --------------------------------------------------------------------------
  // APB_BASE_SEQ – launch apb_base_seq with optional override
  // --------------------------------------------------------------------------
  class apb_base_seq_action_executor extends stimulus_action_executor_base;
    `uvm_object_utils(apb_base_seq_action_executor)

    static bit s_override_set = 0;

    function new(string name="apb_base_seq_action_executor");
      super.new(name);
    endfunction

    virtual task execute(stimulus_action_t a);
      base_seq_action_data d;
      int                   i, n;
      bit                   do_override;
      apb_base_seq          seq;

      if ((m_parent_seq==null) || (m_sequencer==null)) begin
        `uvm_error(get_type_name(), "No parent sequence or sequencer bound")
        return;
      end

      `uvm_info(get_type_name(), "-> APB_BASE_SEQ", UVM_MEDIUM)
      if (!$cast(d, a.action_data)) begin
        n = 1;
        do_override = 0;
      end else begin
        n = (d.num_iters <= 0) ? 1 : d.num_iters;
        do_override = d.use_override;
      end

      if (do_override && !s_override_set) begin
        apb_seq_item::type_id::set_type_override(apb_override_tr::get_type());
        s_override_set = 1;
        `uvm_info(get_type_name(), "Enabled apb_override_tr type override", UVM_LOW)
      end

      for (i = 0; i < n; i++) begin
        seq = apb_base_seq::type_id::create($sformatf("base_seq_%0d", i));
        if (!seq.randomize()) begin
          `uvm_warning(get_type_name(), $sformatf("Randomization failed for iteration %0d", i))
        end
        seq.start(m_sequencer, m_parent_seq);
      end
    endtask
  endclass



  // --------------------------------------------------------------------------
  // APB_REGISTER_SEQ – launch apb_register_seq using configured reg block
  // --------------------------------------------------------------------------
  class apb_register_seq_action_executor extends stimulus_action_executor_base;
    `uvm_object_utils(apb_register_seq_action_executor)

    function new(string name="apb_register_seq_action_executor");
      super.new(name);
    endfunction

    virtual task execute(stimulus_action_t a);
      register_seq_action_data d;
      apb_reg_block            blk;
      apb_register_seq         seq;
      int                      i, n;

      if ((m_parent_seq==null) || (m_sequencer==null)) begin
        `uvm_error(get_type_name(), "No parent sequence or sequencer bound")
        return;
      end

      `uvm_info(get_type_name(), "-> APB_REGISTER_SEQ", UVM_MEDIUM)
      blk = get_reg_block();

      if (blk == null) begin
        `uvm_error(get_type_name(), "No APB register block configured for register sequence")
        return;
      end

      if (!$cast(d, a.action_data)) n = 1; else n = (d.num_iters <= 0) ? 1 : d.num_iters;

      for (i = 0; i < n; i++) begin
        seq = apb_register_seq::type_id::create($sformatf("reg_seq_%0d", i));
        seq.model = blk;
        if (!seq.randomize()) begin
          `uvm_warning(get_type_name(), $sformatf("Randomization failed for iteration %0d", i))
        end
        seq.start(m_sequencer, m_parent_seq);
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
  
      if (!$cast(grp, a.action_data)) begin
        `uvm_error(get_type_name(), "Missing/invalid parallel_group_t")
        return;
      end
      `uvm_info(get_type_name(), "-> PARALLEL_GROUP", UVM_MEDIUM)
      `uvm_info(get_type_name(),
                $sformatf("Executing PARALLEL_GROUP (%0d actions)", grp.parallel_actions.size()),
                UVM_LOW)
  
      if ((m_parent_seq == null) || (m_sequencer == null)) begin
        `uvm_error(get_type_name(), "No parent sequence or sequencer bound")
        return;
      end

      // Launch each sub-action as its own child sequence on the same sequencer.
      // Use fork/join_none so that every proxy starts in its own process and
      // the sequencer can arbitrate between them, allowing true parallelism.
      for (j = 0; j < grp.parallel_actions.size(); j++) begin
        automatic stimulus_action_t sub = grp.parallel_actions[j];
        automatic exec_proxy_seq    proxy =
            exec_proxy_seq::type_id::create($sformatf("proxy_%0d", j));
        proxy.m_sub = sub;
        fork
          proxy.start(m_sequencer, m_parent_seq); // share parent for arbitration
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

