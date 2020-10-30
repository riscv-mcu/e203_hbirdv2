.. _sim:

How to run simulation
=====================

This chapter will introduce how to run system level simulation test on HBirdv2 E203.

.. _get_ready:

Get ready
#########

**1. Setup environment**

- Recommended Linux system: 
    
  .. code-block:: shell

     Ubuntu 18.04

- Required tools:

  .. code-block:: shell
      
     sudo apt-get install autoconf automake autotools-dev curl device-tree-compiler libmpc-dev libmpfr-dev libgmp-dev
     gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev git

**2. Download e203_hbirdv2 project**

   .. code-block:: shell
      
      git clone https://github.com/riscv-mcu/e203_hbirdv2.git

   or

   .. code-block:: shell

      git clone https://gitee.com/riscv-mcu/e203_hbirdv2.git

   .. note::
      After this step, the project is cloned, and the complete e203_hbirdv2 directory is available on this machine. Assuming that the directory is <your_e203_dir>, the abbreviation will be used in the following text.


Compile self-test cases
#######################

**1. Install RISC-V GNU toolchain**

- Download RISC-V GNU toolchain from `Nuclei Download Center <https://nucleisys.com/download.php>`__.

  .. _figure_sim_1:

  .. figure:: /asserts/medias/sim_fig1.png
     :width: 800
     :alt: sim_fig1

     RISC-V GNU Toolchain


- Configure for riscv-tests

  .. code-block:: shell
      
     cp rv_linux_bare_9.21_centos64.tgz.bz2 ~/
             
     cd ~/

     tar -xjvf rv_linux_bare_9.21_centos64.tgz.bz2
     
     cd <your_e203_dir>/
     
     mkdir -p ./riscv-tools/prebuilt_tools/prefix/bin
     
     cd ./riscv-tools/prebuilt_tools/prefix/bin/
     
     ln -s ~/rv_linux_bare_19-12-11-07-12/bin/* .

  .. note::
     rv_linux_bare_9.21_centos64.tgz.bz2 is a sample version, the name depends on the specific version when downloading.

**2. Compile tests**

.. code-block:: shell

   cd <your_e203_dir>/riscv-tools/riscv-tests/isa

   source regen.sh

.. note::
   In <your_e203_dir>/riscv-tools/riscv-tests/isa/generated directory, there are pre-generated executable files.
   If the test codes have been changed, just using above commands could regenerate executable files.

Run simulation tests
####################

**1. Compile RTL**

.. code-block:: shell

   cd <your_e203_dir>/vsim
   
   make install
        
   make compile 

.. note::
   Since VCS tool is used in e230_hbirdv2 makefile as default, so make sure that VCS tool is installed in your machine before running simulation test. 

**2. Run default testcase**

.. code-block:: shell

   make run_test

.. _figure_sim_2:

.. figure:: /asserts/medias/sim_fig2.png
   :width: 800
   :alt: sim_fig2

   Default test simulation result


**3. Run regression**

.. code-block:: shell

   make regress_run


**4. Check regression result**

.. code-block:: shell

   make regress_collect

Regression result is printed as shown in the figure below.

.. _figure_sim_3:

.. figure:: /asserts/medias/sim_fig3.png
   :width: 800
   :alt: sim_fig3

   Regression result

