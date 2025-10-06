package avry_yaml_tests_pkg;
  import uvm_pkg::*;                  `include "uvm_macros.svh"

  // Make sure apb_base_test is visible (in adibis repo it's in test_pkg)
  import apb_test_pkg::*;                 // <-- provides apb_base_test
  import env_pkg::*;                  // env / m_env
  import apb_pkg::*;                  // apb_seq_item and agent types

  // YAML flow pieces
  import avry_yaml_types_pkg::*;      // avry_scenario_cfg, action types
  import scenario_config_pkg::*;      // get_scenario_by_name()
  import avry_yaml_seq_pkg::*;        // avry_flexible_seq_apb

  //----------------------------------------------------------------------------
  // Virtual sequence that:
  //  - reads +SCENARIO (or defaults)
  //  - builds avry_scenario_cfg from scenario_config_pkg
  //  - pushes cfg to config_db for the flexible seq
  //  - starts avry_flexible_seq_apb on APB sequencer
  //----------------------------------------------------------------------------
  class yaml_vseq extends uvm_sequence #(uvm_sequence_item);
    `uvm_object_utils(yaml_vseq)

    // Passed in by the test
    env                m_env;

    // Locals (declare up-front: VCS-friendly)
    avry_flexible_seq_apb seq;
    string                scen_name;
    avry_scenario_cfg     scen_cfg;

    function new(string name="yaml_vseq");
      super.new(name);
    endfunction

    virtual task body();
      uvm_sequencer_base apb_sqr;
      uvm_component      c;

      if (m_env == null) begin
        `uvm_fatal(get_type_name(),"m_env not set (test must assign vseq.m_env before start())")
      end

      // Resolve scenario (+SCENARIO=... or default)
      if (!$value$plusargs("SCENARIO=%s", scen_name))
        scen_name = "reset_traffic";

      scen_cfg = scenario_config_pkg::get_scenario_by_name(scen_name);
      `uvm_info(get_type_name(),
                $sformatf("Using scenario: %s", scen_cfg.scenario_name),
                UVM_LOW)

      // Make the scenario visible to the flexible sequence
      // (use a broad path so the seq can find it)
      uvm_config_db#(avry_scenario_cfg)::set(null, "*", "scenario_cfg", scen_cfg);

      // Create seq
      seq = avry_flexible_seq_apb::type_id::create("seq");

      // Prefer the bench’s APB sequencer from env
      apb_sqr = m_env.m_apb_agent.m_apb_seqr;

      if (apb_sqr == null) begin
        // Fallback: try a common hierarchy path
        c = uvm_root::get().find("uvm_test_top.env.apb_agent.sqr");
        if (!$cast(apb_sqr, c)) begin
          `uvm_warning(get_type_name(),"APB sequencer not found in env or at uvm_test_top.env.apb_agent.sqr. starting seq on null will only work if a default sequencer is configured.")
        end
      end

      // Start the flexible sequence
      seq.start(apb_sqr);
    endtask
  endclass

  //----------------------------------------------------------------------------
  // Test that runs the virtual sequence on the bench
  //----------------------------------------------------------------------------
  class yaml_test extends apb_base_test;
    `uvm_component_utils(yaml_test)

    // Locals up-front
    yaml_vseq vseq;

    function new(string name="yaml_test", uvm_component parent=null);
      super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
      phase.raise_objection(this);

      vseq = yaml_vseq::type_id::create("vseq");
      vseq.m_env = m_env;          // apb_base_test creates/keeps m_env
      vseq.start(null);            // vseq internally finds the APB sequencer

      phase.drop_objection(this);
    endtask
  endclass

endpackage

