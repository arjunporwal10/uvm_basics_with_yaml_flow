package yaml_types_pkg;
  import uvm_pkg::*; `include "uvm_macros.svh"

  // Direction for traffic actions
  typedef enum int unsigned { DIR_READ, DIR_WRITE } dir_e;

  // Generic action container
  class stimulus_action_t extends uvm_object;
    string     action_type;   // "RESET","TRAFFIC","PARALLEL_GROUP","SERIAL_GROUP",...
    uvm_object action_data;   // payload specific to action_type (may be null)
    int unsigned repeat_count; // number of times to dispatch this action (>=1)

    `uvm_object_utils_begin(stimulus_action_t)
      `uvm_field_string(action_type, UVM_ALL_ON)
      `uvm_field_object(action_data, UVM_ALL_ON)
      `uvm_field_int   (repeat_count, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name="stimulus_action_t");
      super.new(name);
      repeat_count = 1;
    endfunction
  endclass

  // Traffic action payload (per-action overrides)
  class traffic_action_data extends uvm_object;
    rand dir_e        direction;
    rand int          num_packets;
    rand int unsigned addr_base;
    rand bit [31:0]   data_pattern;

    `uvm_object_utils_begin(traffic_action_data)
      `uvm_field_enum(dir_e,  direction,    UVM_ALL_ON)
      `uvm_field_int (num_packets,          UVM_ALL_ON)
      `uvm_field_int (addr_base,            UVM_ALL_ON)
      `uvm_field_int (data_pattern,         UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name="traffic_action_data");
      super.new(name);
    endfunction
  endclass

  // apb_base_seq action payload
  class base_seq_action_data extends uvm_object;
    rand int num_iters;
    bit      use_override;

    `uvm_object_utils_begin(base_seq_action_data)
      `uvm_field_int(num_iters,    UVM_ALL_ON)
      `uvm_field_int(use_override, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name="base_seq_action_data");
      super.new(name);
      num_iters    = 1;
      use_override = 0;
    endfunction
  endclass

  // apb_register_seq action payload
  class register_seq_action_data extends uvm_object;
    rand int num_iters;

    `uvm_object_utils_begin(register_seq_action_data)
      `uvm_field_int(num_iters, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name="register_seq_action_data");
      super.new(name);
      num_iters = 1;
    endfunction
  endclass

  // Group payload (used for PARALLEL_GROUP or SERIAL_GROUP)
  class parallel_group_t extends uvm_object;
    stimulus_action_t parallel_actions[$];
    `uvm_object_utils_begin(parallel_group_t)
      // (omit auto-fielding of queues for tool friendliness)
    `uvm_object_utils_end
    function new(string name="parallel_group_t"); super.new(name); endfunction
  endclass

  // Scenario include payload (allows reusing another scenario's actions)
  class scenario_include_action_data extends uvm_object;
    string scenario_name;
    string from_file;

    `uvm_object_utils_begin(scenario_include_action_data)
      `uvm_field_string(scenario_name, UVM_ALL_ON)
      `uvm_field_string(from_file,    UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name="scenario_include_action_data");
      super.new(name);
      scenario_name = "";
      from_file     = "";
    endfunction
  endclass

  // Scenario-wide configuration (sequence-level defaults)
  class yaml_scenario_cfg extends uvm_object;
    `uvm_object_utils(yaml_scenario_cfg)

    // Identity
    string       scenario_name;

    // Global knobs / defaults
    int unsigned timeout_value;   // used by sequence timeout wrappers if any
    int unsigned num_packets;     // default packet count (when action omits it)
    int unsigned addr_base;       // default base address (16-bit APB masked)
    bit [31:0]   data_pattern;    // default data pattern seed

    // Optional expectations
    string expected_interrupts[$];
    bit    do_self_check;

    // Action list (filled by YAML generator)
    stimulus_action_t action_list[$];

    function new(string name="yaml_scenario_cfg");
      super.new(name);
      scenario_name  = "";
      timeout_value  = 10000;
      num_packets    = 8;
      addr_base      = '0;              // APB is 16-bit in this PoC; we’ll mask in seq
      data_pattern   = 32'hA5A5_5A5A;
      do_self_check  = 0;
    endfunction
  endclass

endpackage

