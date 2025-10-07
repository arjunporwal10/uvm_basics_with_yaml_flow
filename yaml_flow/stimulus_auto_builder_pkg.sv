package stimulus_auto_builder_pkg;
  import uvm_pkg::*;                  `include "uvm_macros.svh"
  import avry_yaml_types_pkg::*;

  // ----------------------------------------------------------------------------
  // Stimulus auto-builder
  //  - All variables declared at the top of each function (VCS-friendly)
  //  - Same public API as before
  // ----------------------------------------------------------------------------
  class stimulus_auto_builder;

    // Build a default list if cfg.action_list is empty
    static function void build(avry_scenario_cfg cfg, ref stimulus_action_t action_q[$]);
      integer               n;
      stimulus_action_t     tmp_a;      // scratch when needed (not used below)
      bit                   use_default;

      use_default = (cfg.action_list.size() == 0);

      if (use_default) begin
        // Choose packet count (new field first, then legacy)
        n = 8;

        action_q.delete();
        action_q.push_back(build_reset());
        action_q.push_back(build_traffic(DIR_WRITE, n, 32'd0, 32'hA5A5_5A5A));
        action_q.push_back(build_self_check());

      end
      else begin
        // If YAML already provided actions, just mirror them
        action_q = cfg.action_list;
      end
    endfunction

    static function stimulus_action_t build_reset();
      stimulus_action_t a; a=new(); a.action_type="RESET"; return a;
    endfunction

    static function stimulus_action_t build_self_check();
      stimulus_action_t a; a=new(); a.action_type="SELF_CHECK"; return a;
    endfunction

    static function stimulus_action_t build_error_injection();
      stimulus_action_t a; a=new(); a.action_type="ERROR_INJECTION"; return a;
    endfunction

    static function stimulus_action_t build_traffic(dir_e dir, integer n, int unsigned base=32'h0, bit[31:0] pat=32'h0);
      stimulus_action_t a; traffic_action_data d;
      a=new(); a.action_type="TRAFFIC";
      d=new(); d.direction=dir; d.num_packets=n; d.addr_base=base; d.data_pattern=pat;
      a.action_data=d; return a;
    endfunction

    static function stimulus_action_t build_write_tr(int unsigned base=32'h0, bit[31:0] pat=32'h0);
      stimulus_action_t a; traffic_action_data d;
      a=new(); a.action_type="WRITE_TXN";
      d=new(); d.addr_base=base; d.data_pattern=pat;
      a.action_data=d; return a;
    endfunction

    static function stimulus_action_t build_read_tr(int unsigned base=32'h0 );
      stimulus_action_t a; traffic_action_data d;
      a=new(); a.action_type="READ_TXN";
      d=new(); d.addr_base=base;
      a.action_data=d; return a;
    endfunction

    static function stimulus_action_t build_apb_base_seq(int iterations=1, bit use_override=0);
      stimulus_action_t    a; base_seq_action_data d;
      int                  iters;

      iters = (iterations <= 0) ? 1 : iterations;

      a=new(); a.action_type="APB_BASE_SEQ";
      d=new(); d.num_iters=iters; d.use_override=use_override;
      a.action_data=d; return a;
    endfunction

    static function stimulus_action_t build_apb_register_seq(int iterations=1);
      stimulus_action_t       a; register_seq_action_data d;
      int                     iters;

      iters = (iterations <= 0) ? 1 : iterations;

      a=new(); a.action_type="APB_REGISTER_SEQ";
      d=new(); d.num_iters=iters;
      a.action_data=d; return a;
    endfunction

    static function stimulus_action_t build_parallel(stimulus_action_t subs[$]);
      stimulus_action_t a; parallel_group_t p; integer i;
      a=new(); a.action_type="PARALLEL_GROUP";
      p=new(); for (i=0;i<subs.size();i++) p.parallel_actions.push_back(subs[i]);
      a.action_data=p; return a;
    endfunction

    static function stimulus_action_t build_serial(stimulus_action_t subs[$]);
      stimulus_action_t a; parallel_group_t p; integer i;
      a=new(); a.action_type="SERIAL_GROUP";
      p=new(); for (i=0;i<subs.size();i++) p.parallel_actions.push_back(subs[i]);
      a.action_data=p; return a;
    endfunction
  endclass
endpackage

