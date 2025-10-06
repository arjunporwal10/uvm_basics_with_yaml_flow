
# YAML Flow Integration (PoC)

Files are under `yaml_flow/`:
- `avry_yaml_types_pkg.sv`: action types and scenario cfg
- `action_executors_pkg.sv`: executors for RESET/TRAFFIC/PARALLEL/SERIAL/SELF_CHECK
- `stimulus_auto_builder_pkg.sv`: helpers to build actions programmatically
- `avry_flexible_seq_apb.sv`: flexible sequence that interprets action list
- `avry_yaml_tests_pkg.sv`: `yaml_test` to run flow on APB sequencer
- `tools/yaml2sv.py`: tiny YAML/JSON converter (no external deps)
- `yaml/*.yaml`: example scenarios

## Build
1. Generate scenario_config_pkg.sv:
   ```
   python3 yaml_flow/tools/yaml2sv.py yaml_flow/yaml yaml_flow/scenario_config_pkg.sv
   ```
2. Build & run:
   ```
   make
   ./simv +UVM_TESTNAME=yaml_test +SCENARIO=reset_traffic
   ./simv +UVM_TESTNAME=yaml_test +SCENARIO=parallel_mix
   ```
