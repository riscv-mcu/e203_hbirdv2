#!/bin/bash
#
# Script to compile and run the 2D Convolution with DMA testbench
# using Icarus Verilog
#

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=====================================================${NC}"
echo -e "${BLUE}  2D Convolution with DMA - Simulation Script${NC}"
echo -e "${BLUE}=====================================================${NC}"
echo ""

# Directories
PROJECT_ROOT="/home/runner/work/e203_hbirdv2/e203_hbirdv2"
RTL_DIR="${PROJECT_ROOT}/rtl/e203"
TB_DIR="${PROJECT_ROOT}/tb"
WORK_DIR="${PROJECT_ROOT}/sim_conv2d"

# Create working directory
echo -e "${GREEN}[1/4] Creating working directory...${NC}"
mkdir -p ${WORK_DIR}
cd ${WORK_DIR}

# Compile with Icarus Verilog
echo -e "${GREEN}[2/4] Compiling design with iverilog...${NC}"

# Check if iverilog is available
if ! command -v iverilog &> /dev/null; then
    echo -e "${RED}ERROR: iverilog not found!${NC}"
    echo "Please install Icarus Verilog to run this simulation."
    echo "On Ubuntu/Debian: sudo apt-get install iverilog"
    exit 1
fi

# Compile
iverilog -g2005-sv \
    -o conv2d_dma_sim.out \
    -I ${RTL_DIR}/core \
    -I ${RTL_DIR}/perips \
    ${TB_DIR}/tb_conv2d_dma.v \
    ${RTL_DIR}/perips/e203_dma_ctrl.v \
    2>&1 | tee compile.log

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo -e "${RED}ERROR: Compilation failed!${NC}"
    echo "Check compile.log for details"
    exit 1
fi

echo -e "${GREEN}Compilation successful!${NC}"
echo ""

# Run simulation
echo -e "${GREEN}[3/4] Running simulation...${NC}"
vvp conv2d_dma_sim.out 2>&1 | tee simulation.log

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo -e "${RED}ERROR: Simulation failed!${NC}"
    exit 1
fi

echo ""

# Check results
echo -e "${GREEN}[4/4] Checking results...${NC}"
if grep -q "PASS: All data transferred correctly!" simulation.log; then
    echo -e "${GREEN}✓ Test PASSED!${NC}"
    EXIT_CODE=0
else
    echo -e "${RED}✗ Test FAILED!${NC}"
    EXIT_CODE=1
fi

echo ""
echo -e "${BLUE}=====================================================${NC}"
echo -e "${BLUE}  Simulation Summary${NC}"
echo -e "${BLUE}=====================================================${NC}"
echo "Working directory: ${WORK_DIR}"
echo "Simulation log: ${WORK_DIR}/simulation.log"
echo "Waveform file: ${WORK_DIR}/tb_conv2d_dma.vcd"
echo ""

if command -v gtkwave &> /dev/null; then
    echo "To view waveforms, run:"
    echo "  gtkwave ${WORK_DIR}/tb_conv2d_dma.vcd"
else
    echo "Install GTKWave to view waveforms:"
    echo "  sudo apt-get install gtkwave"
fi

echo ""
exit ${EXIT_CODE}
