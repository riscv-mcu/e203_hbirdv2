.. _mcs:

How to generate mcs for FPGA 
============================

This chapter will introduce how to generate mcs file for Nuclei ddr200t development board.

After HBirdv2 E203 SoC is implemented on the FPGA subsystem of Nuclei ddr200t development board, we can develop embedded applications with it, just like with a real MCU chip.

Before starting the process of MCS generation, you should make sure that your environment is ready, which means e203_hbirdv2 project is ready in your working machine. About environmnet setting, please refer to :ref:`Get ready <get_ready>`.

.. note::
   - Nuclei ddr200t and mcu200t development boards could be used to support HBirdv2 E203 SoC development, here we just take Nuclei ddr200t development board as an example to introduce the development process. For Nuclei mcu200t development board, the development process is similar. 
   - About the details of Nuclei ddr200t and mcu200t development boards, please refer to `Nuclei Development Board <https://www.nucleisys.com/developboard.php>`__.


FPGA MCS generation
###################

**1. Prepare RTL**

.. code-block:: shell

   cd <your_e203_dir>/fpga
   
   make install FPGA_NAME=ddr200t
        
.. note::
   After running above commands, a folder named *install* will be created under *<your_e203_dir>/fpga* directory, and all RTL files needed to generate FPGA bitstream file are loacted in *install/rtl* folder.
 
**2. Generate bit file**

.. code-block:: shell

   make bit FPGA_NAME=ddr200t

.. note::
   Since the FPGA chip used in Nuclei ddr200t development board is Xilinx FPGA, so make sure that Vivado is installed in your machine before running above command.

**3. Generate mcs file**

.. code-block:: shell

   make mcs FPGA_NAME=ddr200t

.. note::
   If above steps run successfully, the FPGA MCS file will be generated under *<your_e203_dir>/fpga/ddr200t/obj* directory, named *system.mcs*.


FPGA MCS download
#################

**1. Hardware connenction**
 
- Connect Nuclei ddr200t development board and your computer with micro USB cable. 
- Connect power supply and turn on the power switch on Nuclei ddr200t development board.

.. _figure_mcs_1:

.. figure:: /asserts/medias/mcs_fig1.png
   :width: 600
   :alt: mcs_fig1

   Connect with PC and power supply 


**2. Open Vivado, and select "Open Hardware Manager"**

.. _figure_mcs_2:

.. figure:: /asserts/medias/mcs_fig2.png
   :width: 600
   :alt: mcs_fig2

   Open Vivado Hardware Manager


**3. Click "Auto Connect" button**

.. _figure_mcs_3:

.. figure:: /asserts/medias/mcs_fig3.png
   :width: 600
   :alt: mcs_fig3

   Connect FPGA system on Nuclei ddr200t

**4. Right-click on FPGA Device, and select "Add Configuration Memory Device"**

.. _figure_mcs_4:

.. figure:: /asserts/medias/mcs_fig4.png
   :width: 600
   :alt: mcs_fig4

   Add Configuration Memory Device

**5. Select Flash with following type**

.. _figure_mcs_5:

.. figure:: /asserts/medias/mcs_fig5.png
   :width: 600
   :alt: mcs_fig5

   Select Flash 

.. note::
   After completeing above steps, a dialog with info "Do you want to program the configuation memory device now?" will arise, then select "OK".

**6. Add <your_e203_dir>/fpga/ddr200t/obj/system.mcs as "Configuration file", then click "OK"**

.. _figure_mcs_6:

.. figure:: /asserts/medias/mcs_fig6.png
   :width: 600
   :alt: mcs_fig6

   Add MCS file

**7. Downloading**

.. _figure_mcs_7:

.. figure:: /asserts/medias/mcs_fig7.png
   :width: 600
   :alt: mcs_fig7

   Downloading


.. _figure_mcs_8:

.. figure:: /asserts/medias/mcs_fig8.png
   :width: 400
   :alt: mcs_fig8

   Download successfully


.. note::
   MCS file is downloaded to on-board nor flash, and each time Nuclei ddr200 development board is powered on, the bit stream will be loaded to FPGA from flash automatically.
