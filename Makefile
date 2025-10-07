# Added YAML flow support
YAML_FLOW = yaml_flow/avry_yaml_types_pkg.sv \
            yaml_flow/stimulus_auto_builder_pkg.sv \
            yaml_flow/action_executors_pkg.sv \
            yaml_flow/scenario_config_pkg.sv \
            yaml_flow/avry_flexible_seq_apb.sv \
            yaml_flow/avry_yaml_tests_pkg.sv

help:
	@echo "Usage: make SIMULATOR TEST=test_name [SCEN=name] [GUI=1] [DEBUG=1]"
	@echo "  SIMULATOR can be 'vcs'."
	@echo "Example: make vcs TEST=apb_read_write_test"
	@echo "  Runs a simulation for apb_read_write_test using VCS."
	@echo "YAML Flow:"
	@echo "  make vcs TEST=yaml_test SCEN=reset_traffic"
	@echo "  (yaml_test comes from yaml_flow/avry_yaml_tests_pkg.sv)"

# conditionals
#-------------------------------------------------------------------------------
UVM_OPTS=-full64 -sverilog -ntb_opts uvm-1.2 +vpi -debug_access+all
ROOT := $(CURDIR)
export ROOT := $(CURDIR)
WORK_DIR := $(ROOT)/WORK_DIR

# Build a log filename for each test/scenario combination
SIM_NAME := $(if $(TEST),$(TEST),sim)
SIM_NAME := $(SIM_NAME)$(if $(strip $(SCEN)),_$(SCEN),)
SIM_LOG  := $(WORK_DIR)/$(SIM_NAME).log

# --- ADD: incdir for yaml_flow so headers/types are found ---
compile_opts  :=
compile_opts  += +incdir+$(ROOT)/yaml_flow

compile_files := -f $(ROOT)/regs/src/filelist.f
compile_files += -f $(ROOT)/agents/apb/src/filelist.f
compile_files += -f $(ROOT)/sequence_lib/src/filelist.f
compile_files += -f $(ROOT)/env/src/filelist.f
compile_files += -f $(ROOT)/tb/src/filelist.f
compile_files += -f $(ROOT)/src/filelist.f

# --- ADD: compile the YAML flow SystemVerilog files too ---
compile_files += $(addprefix $(ROOT)/, $(YAML_FLOW))

# Allow passing a scenario name to YAML-driven tests (optional)
run_opts      := +UVM_TESTNAME=$(TEST)
run_opts      += +SCENARIO=$(SCEN)

top_module    := top

ifdef GUI
compile_opts  += -full64 -sverilog -ntb_opts uvm-1.2 +vpi -debug_access+all
run_opts      += -gui
endif

ifdef DEBUG
run_opts      += +UVM_VERBOSITY=UVM_DEBUG
endif

# constants
vcs_compile_opts := $(compile_opts) -timescale=1ns/10ps -ntb_opts uvm -sverilog
vcs_run_opts     := $(run_opts)

# -------------------------------
# YAML autogen (NEW)
# -------------------------------
SCEN_PKG := $(ROOT)/yaml_flow/scenario_config_pkg.sv
YAML_DIR := $(ROOT)/yaml_flow/yaml
GEN_PY   := $(ROOT)/yaml_flow/tools/yaml2sv.py

.PHONY: yaml
yaml: $(SCEN_PKG)

# Rebuild the scenario_config_pkg.sv whenever YAML changes
$(SCEN_PKG): $(YAML_DIR)/*.yaml $(GEN_PY)
	@echo "==> Generating scenario package from YAML"
	@python3 $(GEN_PY) $(YAML_DIR) $(SCEN_PKG)

# targets
vcs: run_vcs

prep_vcs:

run_vcs: yaml   # <-- ensure YAML is generated before compiling
	mkdir -p $(WORK_DIR) && \
	cd $(WORK_DIR) && \
	vcs $(UVM_OPTS) $(vcs_compile_opts) $(compile_files) && \
	(set -o pipefail; ./simv $(vcs_run_opts) 2>&1 | tee $(SIM_LOG))

clean_vcs:
	rm -rf $(WORK_DIR)/*

