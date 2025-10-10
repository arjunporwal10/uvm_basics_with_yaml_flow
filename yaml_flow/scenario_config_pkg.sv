// Auto-generated scenario_config_pkg.sv
package scenario_config_pkg;
  import yaml_types_pkg::*;
  import stimulus_auto_builder_pkg::*;
  function automatic yaml_scenario_cfg get_scenario_by_name(string name);
    yaml_scenario_cfg cfg = yaml_scenario_cfg::type_id::create(name);
    stimulus_action_t a_0, a_0_0, a_0_1, a_0_2, a_1, a_1_0;
    stimulus_action_t a_1_1, a_1_1_0, a_1_1_1, a_1_2, a_1_2_0, a_1_2_1;
    stimulus_action_t a_1_2_1_0, a_1_2_1_1, a_1_2_1_2, a_2, a_3, a_3_0;
    stimulus_action_t a_3_1, a_3_1_0, a_3_1_1, a_3_2, a_3_2_0, a_3_2_1;
    stimulus_action_t a_4, a_4_0, a_4_1, a_4_2, a_4_2_0, a_4_2_1;
    stimulus_action_t a_5;
    if (0) ;
  else if (name == "only_read") begin
    cfg.scenario_name = "only_read";
    cfg.timeout_value = 10000;
    cfg.action_list.delete();
    a_0 = stimulus_auto_builder::build_reset();
    a_1 = stimulus_auto_builder::build_read_tr(0);
    a_2 = stimulus_auto_builder::build_self_check();
    cfg.action_list.push_back(a_0);
    cfg.action_list.push_back(a_1);
    cfg.action_list.push_back(a_2);
  end
  else if (name == "only_write") begin
    cfg.scenario_name = "only_write";
    cfg.timeout_value = 10000;
    cfg.action_list.delete();
    a_0 = stimulus_auto_builder::build_reset();
    a_1 = stimulus_auto_builder::build_write_tr(8, 32'hA5A55A5A);
    a_2 = stimulus_auto_builder::build_self_check();
    cfg.action_list.push_back(a_0);
    cfg.action_list.push_back(a_1);
    cfg.action_list.push_back(a_2);
  end
  else if (name == "parallel_mix") begin
    cfg.scenario_name = "parallel_mix";
    cfg.timeout_value = 12000;
    cfg.action_list.delete();
    a_0_0 = stimulus_auto_builder::build_traffic(DIR_READ, 8, 16, 32'h00001111);
    a_0_1 = stimulus_auto_builder::build_traffic(DIR_WRITE, 8, 64, 32'h00002222);
    a_0 = stimulus_auto_builder::build_parallel('{a_0_0, a_0_1});
    a_1 = stimulus_auto_builder::build_error_injection();
    a_2 = stimulus_auto_builder::build_self_check();
    cfg.action_list.push_back(a_0);
    cfg.action_list.push_back(a_1);
    cfg.action_list.push_back(a_2);
  end
  else if (name == "random_override_parallel") begin
    cfg.scenario_name = "random_override_parallel";
    cfg.timeout_value = 15000;
    cfg.action_list.delete();
    a_0_0 = stimulus_auto_builder::build_vip_base_seq(1, 1);
    a_0_1 = stimulus_auto_builder::build_vip_register_seq(1);
    a_0_2 = stimulus_auto_builder::build_write_tr(8, 32'hA5A55A5A);
    a_0 = stimulus_auto_builder::build_parallel('{a_0_0, a_0_1, a_0_2});
    a_1 = stimulus_auto_builder::build_self_check();
    cfg.action_list.push_back(a_0);
    cfg.action_list.push_back(a_1);
  end
  else if (name == "repeat_examples") begin
    cfg.scenario_name = "repeat_examples";
    cfg.timeout_value = 20000;
    cfg.action_list.delete();
    a_0 = stimulus_auto_builder::build_reset();
    a_0.repeat_count = 4;
    a_1 = stimulus_auto_builder::build_traffic(DIR_WRITE, 1, 0, 32'hA5A55A5A);
    a_1.repeat_count = 5;
    a_2 = stimulus_auto_builder::build_self_check();
    cfg.action_list.push_back(a_0);
    cfg.action_list.push_back(a_1);
    cfg.action_list.push_back(a_2);
  end
  else if (name == "repeat_reset_traffic") begin
    cfg.scenario_name = "repeat_reset_traffic";
    cfg.timeout_value = 30000;
    cfg.action_list.delete();
    a_0 = stimulus_auto_builder::build_scenario_include("reset_traffic", "reset_traffic.yaml");
    a_0.repeat_count = 2;
    cfg.action_list.push_back(a_0);
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
  else if (name == "serial_only") begin
    cfg.scenario_name = "serial_only";
    cfg.timeout_value = 12000;
    cfg.action_list.delete();
    a_0 = stimulus_auto_builder::build_reset();
    a_1_0 = stimulus_auto_builder::build_traffic(DIR_WRITE, 4, 0, 32'h0000A5A5);
    a_1_1 = stimulus_auto_builder::build_traffic(DIR_READ, 4, 8, 32'h00005A5A);
    a_1_2 = stimulus_auto_builder::build_self_check();
    a_1 = stimulus_auto_builder::build_serial('{a_1_0, a_1_1, a_1_2});
    cfg.action_list.push_back(a_0);
    cfg.action_list.push_back(a_1);
  end
  else if (name == "serial_parallel_mix") begin
    cfg.scenario_name = "serial_parallel_mix";
    cfg.timeout_value = 15000;
    cfg.action_list.delete();
    a_0 = stimulus_auto_builder::build_reset();
    a_1_0 = stimulus_auto_builder::build_traffic(DIR_READ, 8, 16, 32'h00001111);
    a_1_1 = stimulus_auto_builder::build_traffic(DIR_WRITE, 8, 64, 32'h00002222);
    a_1 = stimulus_auto_builder::build_parallel('{a_1_0, a_1_1});
    a_2 = stimulus_auto_builder::build_self_check();
    a_3_0 = stimulus_auto_builder::build_traffic(DIR_WRITE, 2, 0, 32'h0000A5A5);
    a_3_1_0 = stimulus_auto_builder::build_traffic(DIR_READ, 2, 2, 32'h00005A5A);
    a_3_1_1 = stimulus_auto_builder::build_traffic(DIR_WRITE, 2, 4, 32'h0000F00F);
    a_3_1 = stimulus_auto_builder::build_parallel('{a_3_1_0, a_3_1_1});
    a_3 = stimulus_auto_builder::build_serial('{a_3_0, a_3_1});
    a_4 = stimulus_auto_builder::build_self_check();
    cfg.action_list.push_back(a_0);
    cfg.action_list.push_back(a_1);
    cfg.action_list.push_back(a_2);
    cfg.action_list.push_back(a_3);
    cfg.action_list.push_back(a_4);
  end
  else if (name == "ultimate_system_stress") begin
    cfg.scenario_name = "ultimate_system_stress";
    cfg.timeout_value = 60000;
    cfg.action_list.delete();
    a_0 = stimulus_auto_builder::build_reset();
    a_1_0 = stimulus_auto_builder::build_reset(); // unknown APB_BASE_SEQ
    a_1_1_0 = stimulus_auto_builder::build_reset(); // unknown APB_REGISTER_SEQ
    a_1_1_1 = stimulus_auto_builder::build_traffic(DIR_WRITE, 6, 32, 32'h12345678);
    a_1_1 = stimulus_auto_builder::build_parallel('{a_1_1_0, a_1_1_1});
    a_1_2_0 = stimulus_auto_builder::build_traffic(DIR_READ, 4, 48, 32'h87654321);
    a_1_2_1_0 = stimulus_auto_builder::build_write_tr(64, 32'h000ABCDE);
    a_1_2_1_1 = stimulus_auto_builder::build_read_tr(64);
    a_1_2_1_2 = stimulus_auto_builder::build_traffic(DIR_WRITE, 3, 80, 32'hCCCCCCCC);
    a_1_2_1 = stimulus_auto_builder::build_parallel('{a_1_2_1_0, a_1_2_1_1, a_1_2_1_2});
    a_1_2 = stimulus_auto_builder::build_serial('{a_1_2_0, a_1_2_1});
    a_1 = stimulus_auto_builder::build_serial('{a_1_0, a_1_1, a_1_2});
    a_2 = stimulus_auto_builder::build_self_check();
    a_3_0 = stimulus_auto_builder::build_error_injection();
    a_3_1_0 = stimulus_auto_builder::build_traffic(DIR_READ, 5, 96, 32'h01234567);
    a_3_1_1 = stimulus_auto_builder::build_self_check();
    a_3_1 = stimulus_auto_builder::build_serial('{a_3_1_0, a_3_1_1});
    a_3_2_0 = stimulus_auto_builder::build_traffic(DIR_WRITE, 2, 104, 32'hFF00FF00);
    a_3_2_1 = stimulus_auto_builder::build_traffic(DIR_READ, 2, 108, 32'hAABBCCDD);
    a_3_2 = stimulus_auto_builder::build_parallel('{a_3_2_0, a_3_2_1});
    a_3 = stimulus_auto_builder::build_parallel('{a_3_0, a_3_1, a_3_2});
    a_4_0 = stimulus_auto_builder::build_self_check();
    a_4_1 = stimulus_auto_builder::build_traffic(DIR_WRITE, 4, 120, 32'h55555555);
    a_4_2_0 = stimulus_auto_builder::build_read_tr(120);
    a_4_2_1 = stimulus_auto_builder::build_read_tr(124);
    a_4_2 = stimulus_auto_builder::build_parallel('{a_4_2_0, a_4_2_1});
    a_4 = stimulus_auto_builder::build_serial('{a_4_0, a_4_1, a_4_2});
    a_5 = stimulus_auto_builder::build_self_check();
    cfg.action_list.push_back(a_0);
    cfg.action_list.push_back(a_1);
    cfg.action_list.push_back(a_2);
    cfg.action_list.push_back(a_3);
    cfg.action_list.push_back(a_4);
    cfg.action_list.push_back(a_5);
  end
    return cfg;
  endfunction
endpackage
