// Auto-generated scenario_config_pkg.sv
package scenario_config_pkg;
  import avry_yaml_types_pkg::*;
  import stimulus_auto_builder_pkg::*;
  function automatic avry_scenario_cfg get_scenario_by_name(string name);
    avry_scenario_cfg cfg = avry_scenario_cfg::type_id::create(name);
    stimulus_action_t a_0, a_0_0, a_0_1, a_1, a_2;
    if (0) ;
  else if (name == "parallel_mix") begin
    cfg.scenario_name = "parallel_mix";
    cfg.timeout_value = 12000;
    cfg.action_list.delete();
    a_0_0 = stimulus_auto_builder::build_traffic(DIR_READ, 8, 16, 32'h00001111);
    a_0_1 = stimulus_auto_builder::build_traffic(DIR_WRITE, 8, 64, 32'h00002222);
    a_0 = stimulus_auto_builder::build_parallel('{a_0_0, a_0_1});
    a_1 = stimulus_auto_builder::build_self_check();
    cfg.action_list.push_back(a_0);
    cfg.action_list.push_back(a_1);
  end
  else if (name == "reset_traffic") begin
    cfg.scenario_name = "reset_traffic";
    cfg.timeout_value = 10000;
    cfg.action_list.delete();
    a_0 = stimulus_auto_builder::build_reset();
    a_1 = stimulus_auto_builder::build_traffic(DIR_WRITE, 8, 0, 32'hA5A55A5A);
    a_2 = stimulus_auto_builder::build_self_check();
    cfg.action_list.push_back(a_0);
    cfg.action_list.push_back(a_1);
    cfg.action_list.push_back(a_2);
  end
    return cfg;
  endfunction
endpackage
