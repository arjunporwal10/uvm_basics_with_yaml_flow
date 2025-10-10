
# YAML Flow Integration (PoC)

Files are under `yaml_flow/`:
- `yaml_flow_types_pkg.sv`: action types and scenario cfg
- `action_executors_pkg.sv`: executors for RESET/TRAFFIC/PARALLEL/SERIAL/SELF_CHECK and generic VIP hooks
- `vip_plugins_pkg.sv`: reusable adapters that translate YAML actions to VIP-specific sequences
- `stimulus_auto_builder_pkg.sv`: helpers to build actions programmatically
- `yaml_flexible_seq_pkg.sv`: generic flexible sequence that interprets the action list
- `yaml_tests_pkg.sv`: `yaml_test` to run flow on the APB bench
- `tools/yaml2sv.py`: tiny YAML/JSON converter (no external deps)
- `yaml/*.yaml`: example scenarios

### Reusing scenarios

Scenarios can include the actions from another scenario by using the
`SCENARIO_INCLUDE` action type.  The payload only needs the `scenario_name` to
reference; an optional `from_file` string documents where the referenced YAML
originated.  When the flexible sequence encounters an include it loads the
child scenario (generating it on the fly if necessary) and dispatches each of
its actions in place.

Example snippet:

```yaml
action_list:
  - action_type: SCENARIO_INCLUDE
    action_data:
      scenario_name: reset_traffic
  - action_type: SCENARIO_INCLUDE
    action_data:
      scenario_name: reset_traffic
```

This executes the `reset_traffic` stimulus twice without duplicating its YAML.

## Build
1. Generate scenario_config_pkg.sv:
   ```
   python3 yaml_flow/tools/yaml2sv.py yaml_flow/yaml yaml_flow/scenario_config_pkg.sv
   ```
2. Build & run:
   ```
   make
  ./simv +UVM_TESTNAME=yaml_test +SCENARIO=reset_traffic
  ./simv +UVM_TESTNAME=example_bus_yaml_test +SCENARIO=reset_traffic +VIP_VENDOR=example
  ```

Both invocations consume the same YAML scenarios; the selected VIP is determined by
the context passed to the flexible sequence (plusargs `+VIP_SLOT=` / `+VIP_VENDOR=` or
config_db).  The `vip_plugins_pkg` package holds reusable adapters so a project can
plug in its own VIP-specific sequence packages without touching the YAML flow code.
