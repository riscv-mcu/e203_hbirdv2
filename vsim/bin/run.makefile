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

RTL_V_FILES		:= $(wildcard ${VSRC_DIR}/*/*.v ${VSRC_DIR}/*/*/*.v)
TB_V_FILES		:= $(wildcard ${VTB_DIR}/*.v)

# The following portion is depending on the EDA tools you are using, Please add them by yourself according to your EDA vendors
#To-ADD: to add the simulatoin tool
SIM_TOOL      := vcs

#To-ADD: to add the simulatoin tool options 
ifeq ($(SIM_TOOL),vcs)
SIM_OPTIONS   := +v2k -sverilog -q +lint=all,noSVA-NSVU,noVCDE,noUI,noSVA-CE,noSVA-DIU  -debug_access+all -full64 -timescale=1ns/10ps
SIM_OPTIONS   += +incdir+"${VSRC_DIR}/core/"+"${VSRC_DIR}/perips/"+"${VSRC_DIR}/perips/apb_i2c/"
endif
ifeq ($(SIM_TOOL),iverilog)
SIM_OPTIONS   := -o vvp.exec -I "${VSRC_DIR}/core/" -I "${VSRC_DIR}/perips/" -I "${VSRC_DIR}/perips/apb_i2c/" -D DISABLE_SV_ASSERTION=1 -g2005-sv
endif



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

#To-ADD: to add the simulatoin executable
ifeq ($(SIM_TOOL),vcs)
SIM_EXEC      := ${RUN_DIR}/simv +ntb_random_seed_automatic
endif
ifeq ($(SIM_TOOL),iverilog)
SIM_EXEC      := vvp ${RUN_DIR}/vvp.exec -lxt2	
endif


#To-ADD: to add the waveform tool
ifeq ($(SIM_TOOL),vcs)
WAV_TOOL := verdi
endif
ifeq ($(SIM_TOOL),iverilog) 
WAV_TOOL := gtkwave
endif

#To-ADD: to add the waveform tool options 
ifeq ($(WAV_TOOL),verdi)
WAV_OPTIONS   := +v2k -sverilog
endif
ifeq ($(WAV_TOOL),gtkwave)
WAV_OPTIONS   := 
endif

ifeq ($(SMIC130LL),1) 
WAV_OPTIONS   += +define+SMIC130_LL
endif
ifeq ($(GATE_SIM),1) 
WAV_OPTIONS   += +define+GATE_SIM  
endif
ifeq ($(GATE_SDF),1) 
WAV_OPTIONS   += +define+GATE_SDF
endif


#To-ADD: to add the include dir
ifeq ($(WAV_TOOL),verdi)
WAV_INC      := +incdir+"${VSRC_DIR}/core/"+"${VSRC_DIR}/perips/"+"${VSRC_DIR}/perips/apb_i2c/"
endif
ifeq ($(WAV_TOOL),gtkwave)
WAV_INC      := 
endif

#To-ADD: to add RTL and TB files
ifeq ($(WAV_TOOL),verdi)
WAV_RTL      := ${RTL_V_FILES} ${TB_V_FILES}
endif
ifeq ($(WAV_TOOL),gtkwave)
WAV_RTL      := 
endif

#To-ADD: to add the waveform file 
ifeq ($(WAV_TOOL),verdi)
WAV_FILE      := -ssf ${TEST_RUNDIR}/tb_top.fsdb
endif
ifeq ($(WAV_TOOL),gtkwave)
WAV_FILE      := ${TEST_RUNDIR}/tb_top.vcd
endif

all: run

compile.flg: ${RTL_V_FILES} ${TB_V_FILES}
	@-rm -rf compile.flg
	sed -i '1i\`define ${SIM_TOOL}\'  ${VTB_DIR}/tb_top.v
	${SIM_TOOL} ${SIM_OPTIONS}  ${RTL_V_FILES} ${TB_V_FILES} ;
	touch compile.flg

compile: compile.flg 

wave: 
	gvim -p ${TESTCASE}.spike.log ${TESTCASE}.dump &
	${WAV_TOOL} ${WAV_OPTIONS} ${WAV_INC} ${WAV_RTL} ${WAV_FILE}  & 

run: compile
	rm -rf ${TEST_RUNDIR}
	mkdir ${TEST_RUNDIR}
	cd ${TEST_RUNDIR}; ${SIM_EXEC} +DUMPWAVE=${DUMPWAVE} +TESTCASE=${TESTCASE} +SIM_TOOL=${SIM_TOOL} 2>&1 | tee ${TESTNAME}.log; cd ${RUN_DIR}; 


.PHONY: run clean all 

