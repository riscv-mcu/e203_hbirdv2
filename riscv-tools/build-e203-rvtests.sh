#! /bin/bash
#
# Script to build RISC-V ISA simulator, proxy kernel
# Tools will be installed to $PREFIX.

PREFIX=$PWD/prebuilt_tools/prefix
. build.common

echo "Starting RISC-V Toolchain build process"

build_project riscv-tests --prefix=$PREFIX/riscv-nuclei-elf --with-xlen=32

echo -e "\\nRISC-V Toolchain installation completed!"
