RUN_DIR      := ${PWD}

TESTCASE     := ${RUN_DIR}/../../riscv-tools/riscv-tests/isa/generated/rv32ui-p-addi
DUMPWAVE     := 1

SMIC130LL    := 0
GATE_SIM     := 0
GATE_SDF     := 0
GATE_NOTIME     := 0


VSRC_DIR     := ${RUN_DIR}/../install/rtl
VTB_DIR      := ${RUN_DIR}/../install/tb
TESTNAME     := $(notdir $(patsubst %.dump,%,${TESTCASE}.dump))
TEST_RUNDIR  := ${TESTNAME}

RTL_V_FILES		:= $(wildcard ${VSRC_DIR}/*/*.v ${VSRC_DIR}/*/*.sv ${VSRC_DIR}/*/*/*.v ${VSRC_DIR}/*/*/*.sv)
TB_V_FILES		:= $(wildcard ${VTB_DIR}/*.v ${VTB_DIR}/*.sv)

# The following portion is depending on the EDA tools you are using, Please add them by yourself according to your EDA vendors
SIM_TOOL      := #To-ADD: to add the simulatoin tool
SIM_TOOL      := vcs
SIM_OPTIONS   := #To-ADD: to add the simulatoin tool options 
SIM_OPTIONS   := +v2k -sverilog -q +lint=all,noSVA-NSVU,noVCDE,noUI,noSVA-CE,noSVA-DIU  -debug_access+all -full64 -timescale=1ns/10ps
SIM_OPTIONS   += +incdir+"${VSRC_DIR}/core/"+"${VSRC_DIR}/perips/"+"${VSRC_DIR}/perips/apb_i2c/" 
ifeq ($(SMIC130LL),1) 
SIM_OPTIONS   += +define+SMIC130_LL
endif
ifeq ($(GATE_SIM),1) 
SIM_OPTIONS   += +define+GATE_SIM  +lint=noIWU,noOUDPE,noPCUDPE
endif
ifeq ($(GATE_SDF),1) 
SIM_OPTIONS   += +define+GATE_SDF
endif
ifeq ($(GATE_NOTIME),1) 
SIM_OPTIONS   += +nospecify +notimingcheck 
endif
ifeq ($(GATE_SDF_MAX),1) 
SIM_OPTIONS   += +define+SIM_MAX
endif
ifeq ($(GATE_SDF_MIN),1) 
SIM_OPTIONS   += +define+SIM_MIN
endif

SIM_EXEC      := #To-ADD: to add the simulatoin executable
SIM_EXEC      := ${RUN_DIR}/simv +ntb_random_seed_automatic
# SIM_EXEC      := echo "Test Result Summary: PASS" # This is a fake run to just direct print PASS info to the log, the user need to actually replace it to the real EDA command

WAV_TOOL      := #To-ADD: to add the waveform tool
WAV_TOOL      := verdi
WAV_OPTIONS   := #To-ADD: to add the waveform tool options 
WAV_OPTIONS   := +v2k -sverilog 
ifeq ($(SMIC130LL),1) 
WAV_OPTIONS   += +define+SMIC130_LL
endif
ifeq ($(GATE_SIM),1) 
WAV_OPTIONS   += +define+GATE_SIM  
endif
ifeq ($(GATE_SDF),1) 
WAV_OPTIONS   += +define+GATE_SDF
endif
WAV_PFIX      := #To-ADD: to add the waveform file postfix
WAV_PFIX      := fsdb

all: run

compile.flg: ${RTL_V_FILES} ${TB_V_FILES}
	@-rm -rf compile.flg
	${SIM_TOOL} ${SIM_OPTIONS}  ${RTL_V_FILES} ${TB_V_FILES} ;
	touch compile.flg

compile: compile.flg 

wave: 
	gvim -p ${TESTCASE}.spike.log ${TESTCASE}.dump &
	${WAV_TOOL} ${WAV_OPTIONS} +incdir+"${VSRC_DIR}/core/"+"${VSRC_DIR}/perips/"  ${RTL_V_FILES} ${TB_V_FILES} -ssf ${TEST_RUNDIR}/tb_top.${WAV_PFIX} & 

run: compile
	rm -rf ${TEST_RUNDIR}
	mkdir ${TEST_RUNDIR}
	cd ${TEST_RUNDIR}; ${SIM_EXEC} +DUMPWAVE=${DUMPWAVE} +TESTCASE=${TESTCASE} |& tee ${TESTNAME}.log; cd ${RUN_DIR}; 


.PHONY: run clean all 

