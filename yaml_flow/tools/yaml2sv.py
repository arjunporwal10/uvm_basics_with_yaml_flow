#!/usr/bin/env python3
import os, sys, json

# -----------------------------
# SV code generators
# -----------------------------

def sv_header():
    # NOTE: we intentionally END before any procedural statements.
    # Declarations will be inserted right after the 'create(name);' line.
    return (
        "// Auto-generated scenario_config_pkg.sv\n"
        "package scenario_config_pkg;\n"
        "  import yaml_types_pkg::*;\n"
        "  import stimulus_auto_builder_pkg::*;\n"
        "  function automatic yaml_scenario_cfg get_scenario_by_name(string name);\n"
        "    yaml_scenario_cfg cfg = yaml_scenario_cfg::type_id::create(name);\n"
    )

def sv_after_decls():
    # The classic trick to start an else-if chain
    return "    if (0) ;\n"

def sv_footer():
    return (
        "    return cfg;\n"
        "  endfunction\n"
        "endpackage\n"
    )

def sv_id(x):  # placeholder if you later want to sanitize/escape identifiers
    return x

def sv_string_literal(x):
    """Return a SystemVerilog-compatible quoted string literal."""
    if x is None:
        x = ""
    return json.dumps(str(x))

# -----------------------------
# Emission helpers
# -----------------------------

def emit_actions(lst, prefix):
    """
    Build the SV for a list of actions.
    Returns:
      var_names: set of variable names needed (strings like 'a_0', 'a_1_0', ...)
      stmts: list of assignment/build statements (no declarations!)
    """
    var_names = set()
    stmts = []

    for i, a in enumerate(lst):
        var_name = f"{prefix}{i}"
        var_names.add(var_name)

        at = a["action_type"]
        data = a.get("action_data", {})

        repeat = a.get("repeat", 1)
        try:
            repeat = int(repeat)
        except (TypeError, ValueError):
            repeat = 1
        if repeat <= 0:
            repeat = 1

        if at == "RESET":
            stmts.append(f"    {var_name} = stimulus_auto_builder::build_reset();")
        elif at == "SELF_CHECK":
            stmts.append(f"    {var_name} = stimulus_auto_builder::build_self_check();")
        elif at == "ERROR_INJECTION":
            stmts.append(f"    {var_name} = stimulus_auto_builder::build_error_injection();")
        elif at == "WRITE_TXN":
            base = int(data.get("addr_base", 0))
            pat = int(data.get("data_pattern", 0))
            stmts.append(
                f"    {var_name} = stimulus_auto_builder::build_write_tr({base}, 32'h{pat:08X});"
            )
        elif at == "READ_TXN":
            base = int(data.get("addr_base", 0))
            stmts.append(
                f"    {var_name} = stimulus_auto_builder::build_read_tr({base});"
            )
        elif at == "TRAFFIC":
            n = int(data.get("num_packets", 8))
            base = int(data.get("addr_base", 0))
            pat = int(data.get("data_pattern", 0))
            dirn = data.get("direction", "write").lower()
            dirc = "DIR_WRITE" if dirn.startswith("w") else "DIR_READ"
            stmts.append(
                f"    {var_name} = stimulus_auto_builder::build_traffic({dirc}, {n}, {base}, 32'h{pat:08X});"
            )
        elif at == "VIP_BASE_SEQ":
            n = int(data.get("num_iters", 1))
            use_override = data.get("use_override", False)
            ov = 1 if use_override else 0
            stmts.append(
                f"    {var_name} = stimulus_auto_builder::build_vip_base_seq({n}, {ov});"
            )
        elif at == "VIP_REGISTER_SEQ":
            n = int(data.get("num_iters", 1))
            stmts.append(
                f"    {var_name} = stimulus_auto_builder::build_vip_register_seq({n});"
            )
        elif at == "PARALLEL_GROUP":
            subs = data.get("parallel_actions", [])
            subp = f"{var_name}_"
            sub_vars, sub_stmts = emit_actions(subs, subp)
            var_names |= sub_vars
            stmts += sub_stmts
            names = ", ".join([f"{subp}{j}" for j in range(len(subs))])
            stmts.append(f"    {var_name} = stimulus_auto_builder::build_parallel('{{{names}}});")
        elif at == "SERIAL_GROUP":
            subs = data.get("serial_actions", [])
            subp = f"{var_name}_"
            sub_vars, sub_stmts = emit_actions(subs, subp)
            var_names |= sub_vars
            stmts += sub_stmts
            names = ", ".join([f"{subp}{j}" for j in range(len(subs))])
            stmts.append(f"    {var_name} = stimulus_auto_builder::build_serial('{{{names}}});")
        elif at == "SCENARIO_INCLUDE":
            scen = data.get("scenario_name", "")
            if not scen:
                stmts.append(
                    f"    {var_name} = stimulus_auto_builder::build_reset(); // missing scenario_name for include"
                )
            else:
                scen_lit = sv_string_literal(scen)
                from_file = data.get("from_file", "")
                if from_file:
                    file_lit = sv_string_literal(from_file)
                    stmts.append(
                        f"    {var_name} = stimulus_auto_builder::build_scenario_include({scen_lit}, {file_lit});"
                    )
                else:
                    stmts.append(
                        f"    {var_name} = stimulus_auto_builder::build_scenario_include({scen_lit});"
                    )
        else:
            # unknown -> default to RESET
            stmts.append(
                f"    {var_name} = stimulus_auto_builder::build_reset(); // unknown {at}"
            )

        if repeat != 1:
            stmts.append(f"    {var_name}.repeat_count = {repeat};")

    return var_names, stmts

def emit_case(scen):
    """
    Build one 'else if (name == "...") begin ... end' block.
    Returns:
      var_names: set of variable names needed by this scenario
      block: the SV code string for this case (no declarations!)
    """
    nm = scen.get("scenario_name", "unnamed")
    lines = [
        f'  else if (name == "{nm}") begin',
        f'    cfg.scenario_name = "{nm}";'
    ]

    if "timeout_value" in scen:
        lines.append(f'    cfg.timeout_value = {int(scen["timeout_value"])};')

    acts = scen.get("action_list", [])
    var_names = set()

    if acts:
        # collect variables + statements for this scenario
        act_vars, stmts = emit_actions(acts, "a_")
        var_names |= act_vars

        # assignments first, then push into list
        lines.append("    cfg.action_list.delete();")
        lines += stmts

        for i in range(len(acts)):
            lines.append(f"    cfg.action_list.push_back(a_{i});")
    else:
        lines.append("    cfg.action_list.delete();")

    lines.append("  end")
    return var_names, "\n".join(lines)

def format_decl_lines(var_names):
    """
    Emit declarations at the top of the function.
    Groups multiple variables per line for readability.
    """
    if not var_names:
        return ""

    names = sorted(var_names)  # deterministic output
    lines = []
    # group a few per line
    group = []
    for n in names:
        group.append(n)
        if len(group) >= 6:
            lines.append("    stimulus_action_t " + ", ".join(group) + ";")
            group = []
    if group:
        lines.append("    stimulus_action_t " + ", ".join(group) + ";")

    return "\n".join(lines) + "\n"

# -----------------------------
# YAML/JSON loader
# -----------------------------

def load_scenarios(yaml_dir):
    """
    Loads all *.yaml files (very limited parser: JSON first, then a minimal YAML->JSON-ish fallback).
    Returns a list of dicts.
    """
    scenarios = []
    for fn in sorted(os.listdir(yaml_dir)):
        if not fn.endswith(".yaml"):
            continue
        full = os.path.join(yaml_dir, fn)
        with open(full, "r") as f:
            txt = f.read()

        # Try JSON first
        try:
            data = json.loads(txt)
        except Exception:
            # Minimal YAML->JSON-ish: booleans + single quotes
            txt2 = txt.replace(": true", ": 1").replace(": false", ": 0").replace("'", '"')
            try:
                data = json.loads(txt2)
            except Exception as e:
                print(f"[WARN] Could not parse {fn}: {e}")
                continue

        if "scenario_name" not in data:
            print(f"[SKIP] {fn}: missing scenario_name")
            continue

        scenarios.append(data)
    return scenarios

# -----------------------------
# Main generator
# -----------------------------

def main(yaml_dir, out_sv):
    scenarios = load_scenarios(yaml_dir)

    # First pass: collect all variable names across all scenarios
    all_var_names = set()
    case_blocks = []

    for sc in scenarios:
        var_names, block = emit_case(sc)
        all_var_names |= var_names
        case_blocks.append(block)

    with open(out_sv, "w") as f:
        # Header up to the point before any statements
        f.write(sv_header())

        # Declarations: MUST come before any procedural statement
        f.write(format_decl_lines(all_var_names))

        # Then start the if/else chain
        f.write(sv_after_decls())

        # All cases
        for block in case_blocks:
            f.write(block + "\n")

        # Footer
        f.write(sv_footer())

    print(f"[OK] wrote {out_sv} with {len(scenarios)} scenarios")

# -----------------------------
# Entrypoint
# -----------------------------

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 yaml_flow/tools/yaml2sv.py <yaml_dir> <out_sv>")
        sys.exit(1)
    main(sys.argv[1], sys.argv[2])

