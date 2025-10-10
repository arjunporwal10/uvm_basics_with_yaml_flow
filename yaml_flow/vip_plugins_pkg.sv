package vip_plugins_pkg;
  import uvm_pkg::*;                 `include "uvm_macros.svh"
  import yaml_types_pkg::*;
  import chip_seq_lib_pkg::*;
  import yaml_apb_seq_pkg::*;
  import yaml_example_bus_seq_pkg::*;

  class yaml_vip_context extends uvm_object;
    `uvm_object_utils(yaml_vip_context)

    string             slot_id;
    string             vendor_name;
    uvm_sequencer_base sequencer;
    uvm_reg_block      reg_block;
    uvm_component      env;

    function new(string name="yaml_vip_context");
      super.new(name);
      slot_id = "vip0";
      vendor_name = "";
      sequencer = null;
      reg_block = null;
      env = null;
    endfunction
  endclass

  class yaml_vip_adapter extends uvm_object;
    `uvm_object_utils(yaml_vip_adapter)

    protected yaml_vip_context m_ctx;
    protected string           m_vendor_key;

    function new(string name="yaml_vip_adapter");
      super.new(name);
    endfunction

    function void set_vendor_key(string key);
      m_vendor_key = key;
    endfunction

    virtual function string default_vendor_key();
      return "generic";
    endfunction

    function string vendor_key();
      if (m_vendor_key == "") begin
        return default_vendor_key();
      end
      return m_vendor_key;
    endfunction

    function void set_context(yaml_vip_context ctx);
      m_ctx = ctx;
    endfunction

    function yaml_vip_context get_context();
      return m_ctx;
    endfunction

    virtual function bit is_compatible(string vendor);
      return (vendor == vendor_key());
    endfunction

    virtual function void check_ready();
      if (m_ctx == null) begin
        `uvm_fatal(get_type_name(), "VIP adapter context not configured")
      end
      if (m_ctx.sequencer == null) begin
        `uvm_fatal(get_type_name(), "VIP adapter requires a sequencer handle in the context")
      end
    endfunction

    virtual task send_write(uvm_sequence_base parent_seq,
                            uvm_sequencer_base seqr,
                            bit [31:0] addr,
                            bit [31:0] data);
      `uvm_fatal(get_type_name(), "send_write not implemented for this adapter")
    endtask

    virtual task send_read(uvm_sequence_base parent_seq,
                           uvm_sequencer_base seqr,
                           bit [31:0] addr,
                           output bit [31:0] data);
      `uvm_fatal(get_type_name(), "send_read not implemented for this adapter")
    endtask

    virtual task start_base_sequence(uvm_sequence_base parent_seq,
                                     uvm_sequencer_base seqr,
                                     base_seq_action_data cfg);
      `uvm_info(get_type_name(),
                $sformatf("VIP '%s' does not implement BASE sequence; skipping", vendor_key()),
                UVM_LOW)
    endtask

    virtual task start_register_sequence(uvm_sequence_base parent_seq,
                                         uvm_sequencer_base seqr,
                                         register_seq_action_data cfg);
      `uvm_info(get_type_name(),
                $sformatf("VIP '%s' does not implement REGISTER sequence; skipping", vendor_key()),
                UVM_LOW)
    endtask

    virtual function void register_bus_actions();
    endfunction
  endclass

  // --------------------------------------------------------------------------
  // APB VIP adapter
  // --------------------------------------------------------------------------
  class yaml_apb_vip_adapter extends yaml_vip_adapter;
    `uvm_object_utils(yaml_apb_vip_adapter)

    static bit s_override_enabled = 0;

    function new(string name="yaml_apb_vip_adapter");
      super.new(name);
    endfunction

    virtual function string default_vendor_key();
      return "apb";
    endfunction

    virtual task send_write(uvm_sequence_base parent_seq,
                            uvm_sequencer_base seqr,
                            bit [31:0] addr,
                            bit [31:0] data);
      yaml_apb_direct_write_seq seq;
      check_ready();
      seq = yaml_apb_direct_write_seq::type_id::create("yaml_apb_direct_write_seq");
      seq.addr = addr;
      seq.data = data;
      seq.start(seqr, parent_seq);
    endtask

    virtual task send_read(uvm_sequence_base parent_seq,
                           uvm_sequencer_base seqr,
                           bit [31:0] addr,
                           output bit [31:0] data);
      yaml_apb_direct_read_seq seq;
      check_ready();
      seq = yaml_apb_direct_read_seq::type_id::create("yaml_apb_direct_read_seq");
      seq.addr = addr;
      seq.start(seqr, parent_seq);
      data = seq.read_data;
    endtask

    virtual task start_base_sequence(uvm_sequence_base parent_seq,
                                     uvm_sequencer_base seqr,
                                     base_seq_action_data cfg);
      uvm_sequence_base seq;
      int n;
      bit do_override;

      check_ready();
      if (cfg == null) begin
        n = 1;
        do_override = 0;
      end else begin
        n = (cfg.num_iters <= 0) ? 1 : cfg.num_iters;
        do_override = cfg.use_override;
      end

      if (do_override && !s_override_enabled) begin
        apb_seq_item::type_id::set_type_override(apb_override_tr::get_type());
        s_override_enabled = 1;
        `uvm_info(get_type_name(), "Enabled apb_override_tr type override", UVM_LOW)
      end

      repeat (n) begin
        seq = apb_base_seq::type_id::create("yaml_apb_base_seq");
        if (!seq.randomize()) begin
          `uvm_warning(get_type_name(), "Randomization failed for apb_base_seq")
        end
        seq.start(seqr, parent_seq);
      end
    endtask

    virtual task start_register_sequence(uvm_sequence_base parent_seq,
                                         uvm_sequencer_base seqr,
                                         register_seq_action_data cfg);
      apb_register_seq seq;
      apb_reg_block    blk;
      int n;

      check_ready();
      if (cfg == null) n = 1; else n = (cfg.num_iters <= 0) ? 1 : cfg.num_iters;

      if ((m_ctx == null) || (m_ctx.reg_block == null)) begin
        `uvm_error(get_type_name(), "APB register sequence requested but context.reg_block is null")
        return;
      end

      if (!$cast(blk, m_ctx.reg_block)) begin
        `uvm_error(get_type_name(), "Context reg_block is not an apb_reg_block")
        return;
      end

      repeat (n) begin
        seq = apb_register_seq::type_id::create("yaml_apb_register_seq");
        seq.model = blk;
        if (!seq.randomize()) begin
          `uvm_warning(get_type_name(), "Randomization failed for apb_register_seq")
        end
        seq.start(seqr, parent_seq);
      end
    endtask
  endclass

  // --------------------------------------------------------------------------
  // Example bus VIP adapter (console logging demonstration)
  // --------------------------------------------------------------------------
  class yaml_example_bus_vip_adapter extends yaml_vip_adapter;
    `uvm_object_utils(yaml_example_bus_vip_adapter)

    function new(string name="yaml_example_bus_vip_adapter");
      super.new(name);
    endfunction

    virtual function string default_vendor_key();
      return "example";
    endfunction

    virtual task send_write(uvm_sequence_base parent_seq,
                            uvm_sequencer_base seqr,
                            bit [31:0] addr,
                            bit [31:0] data);
      yaml_example_direct_write_seq seq;
      check_ready();
      seq = yaml_example_direct_write_seq::type_id::create("yaml_example_direct_write_seq");
      seq.addr = addr;
      seq.data = data;
      seq.start(seqr, parent_seq);
    endtask

    virtual task send_read(uvm_sequence_base parent_seq,
                           uvm_sequencer_base seqr,
                           bit [31:0] addr,
                           output bit [31:0] data);
      yaml_example_direct_read_seq seq;
      check_ready();
      seq = yaml_example_direct_read_seq::type_id::create("yaml_example_direct_read_seq");
      seq.addr = addr;
      seq.start(seqr, parent_seq);
      data = seq.read_value;
    endtask

    virtual task start_base_sequence(uvm_sequence_base parent_seq,
                                     uvm_sequencer_base seqr,
                                     base_seq_action_data cfg);
      int n;
      int idx;
      yaml_example_direct_write_seq seq;

      check_ready();
      if (cfg == null) n = 1; else n = (cfg.num_iters <= 0) ? 1 : cfg.num_iters;
      for (idx = 0; idx < n; idx++) begin
        seq = yaml_example_direct_write_seq::type_id::create($sformatf("yaml_example_base_write_%0d", idx));
        seq.addr = 32'h1000 + idx;
        seq.data = 32'hDEAD_BEEF;
        seq.start(seqr, parent_seq);
      end
    endtask
  endclass

  class yaml_vip_registry;
    static yaml_vip_adapter m_registry[string];
    static bit m_defaults_loaded = 0;

    static function void register_adapter(yaml_vip_adapter adapter, string vendor_name="");
      if (adapter == null) begin
        `uvm_fatal("VIP_REG", "Attempting to register null adapter")
      end
      if (vendor_name != "") begin
        adapter.set_vendor_key(vendor_name);
      end
      if (adapter.vendor_key() == "") begin
        `uvm_fatal("VIP_REG", "Adapter registered with empty vendor key")
      end
      m_registry[adapter.vendor_key()] = adapter;
    endfunction

    static function yaml_vip_adapter get_adapter(string vendor_name);
      load_defaults_if_needed();
      if (!m_registry.exists(vendor_name)) begin
        `uvm_warning("VIP_REG", $sformatf("No adapter registered for VIP '%s'", vendor_name))
        return null;
      end
      return m_registry[vendor_name];
    endfunction

    static function void load_defaults_if_needed();
      if (m_defaults_loaded) return;
      m_defaults_loaded = 1;
      register_adapter(yaml_apb_vip_adapter::type_id::create("apb_default_adapter"));
      register_adapter(yaml_example_bus_vip_adapter::type_id::create("example_default_adapter"));
    endfunction
  endclass

endpackage
