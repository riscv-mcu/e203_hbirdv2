The Simulation Directory
========================

Here we use iVerilog+GTKWave for simulation by default, and VCS+Verdi are also supported in simulation environment, you can choose the simulation tool by Makefile variable **SIM**. If you want to run simulation tests directly, please make sure these EDA tools are installed in your working environment. 

Preparation
-----------
make clean

make install

Compile
-------
make compile SIM=iverilog **or** make compile SIM=VCS

Run Test
--------
make run_test SIM=iverilog **or** make run_test SIM=vcs

Check Waveform
--------------
make wave SIM=iverilog **or** make wave SIM=vcs


Note:
-----
If you use iVerilog as simulation tool, please make sure the tool verison is 12.0.


