# See LICENSE for license details.
base_dir := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
FPGA_NAME := ddr200t
FPGA_DIR := $(base_dir)/${FPGA_NAME}
INSTALL_RTL ?= $(base_dir)/install/rtl

include common.mk
