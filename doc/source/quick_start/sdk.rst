.. _sdk:

How to develop with HBird SDK
=============================

This chapter will introduce how to run Hello World demo on HBirdv2 E203 SoC with HBird SDK.

HBird SDK introduction
######################

HBird SDK is a software platform built based on Makefile, which supports running in Windows/Linux system. As an intermediate platform that connect the upper-level application and underlying hardware, HBird SDK provides the application interface(API) required to operate the underlying hardware platform, so that users don't need to face cumbersome register configuration when developing applications, thereby improving development efficiency. 

The architecture of HBird SDK is shown in the figure below.

.. _figure_sdk_0:

.. figure:: /asserts/medias/sdk_fig0.png
   :width: 800
   :alt: sdk_fig0

   HBird SDK Architecture 


Setup tools and environment
###########################

.. _quickstart_setup_tools_env_windows:

Install and setup tools in Windows
----------------------------------

**1. Preparation**

- Create a folder in your Windows Environment, which is used to store development tools.
 
  .. note::
     
     Assuming that the directory is *<nuclei-tools>*, the abbreviation will be used in the following text.

**2. Tools download**

- Download the following tools from `Nuclei Download Center <https://nucleisys.com/download.php>`__.

  .. _figure_sdk_1:
  
  .. figure:: /asserts/medias/sdk_fig1.png
     :width: 750
     :alt: sdk_fig1
  
     Nuclei tools need to be downloaded for Windows


**3. Tools setup**

Create *gcc*, *openocd*, *build-tools* folders under *<nuclei-tools>* directory.

- Extract the downloaded **gnu toolchain** into a temp folder, then copy the files into *gcc* folder, and make sure the structure of *gcc* directory looks the same as the figure below.

  .. _figure_sdk_2:

  .. figure:: /asserts/medias/sdk_fig2.png
     :width: 550
     :alt: sdk_fig2

     The structure of Nuclei RISC-V GCC Toolchain directory 

- Extract the downloaded **openocd** into a temp folder, then copy the files into *openocd* folder, and make sure the structure of *openocd* directory looks the same as the figure below.

  .. _figure_sdk_3:

  .. figure:: /asserts/medias/sdk_fig3.png
     :width: 550
     :alt: sdk_fig3

     The structure of Nuclei OpenOCD directory 

- Extract the downloaded **build-tools** into a temp folder, then copy the files into *build-tools* folder, and make sure the structure of *build-tools* directory looks the same as the figure below.

  .. _figure_sdk_4:

  .. figure:: /asserts/medias/sdk_fig4.png
     :width: 550
     :alt: sdk_fig4

     The structure of Nuclei Windows Build Tools directory 


Install and setup tools in Linux
--------------------------------

**1. Preparation**

- Create a folder in your Linux Environment, which is used to store development tools.
 
  .. note::
    
     Assuming that the directory is *<nuclei-tools>*, the abbreviation will be used in the following text.

**2. Tools download**

- Download the following tools from `Nuclei Download Center <https://nucleisys.com/download.php>`__.

  .. _figure_sdk_5:
  
  .. figure:: /asserts/medias/sdk_fig5.png
     :width: 800
     :alt: sdk_fig5
  
     Nuclei tools need to be downloaded for Linux


**3. Tools setup**

- Create *gcc*, *openocd* folders under *<nuclei-tools>* directory.
- Then please follow the similar steps described in **Step3** in :ref:`quickstart_setup_tools_env_windows` to extract and copy necessary files.

  .. note::
     
     - Only *gcc* and *openocd* are required for Linux.
     - Extract the downloaded Linux tools, not the Windows version.

Get and setup HBird SDK
-----------------------

**1. HBird SDK download**

.. code-block:: shell
   
   git clone https://github.com/riscv-mcu/hbird-sdk.git

or

.. code-block:: shell

   git clone https://gitee.com/riscv-mcu/hbird-sdk.git

.. note::
   
   - Make sure Git tool has been installed in your working machine.
   - After this step, the project is cloned, and the complete hbird-sdk directory is available on this machine. Assuming that the directory is *<hbird-sdk>*, the abbreviation will be used in the following text. 

**2. Build environment setting for HBird SDK**

- Windows
  
  - Creat *setup_config.bat* in *<hbird-sdk>* folder, and open this file with your editor, then paste the following content.
  
    .. code-block:: shell

       set NUCLEI_TOOL_ROOT=<nuclei-tools>
   
    .. note::
       
       The *<nuclei-tools>* here indicates the path where the tools are stored as mentioned above, which should be subject to the actual situation of the user.

  - Open Windows command terminal and cd to *<hbird-sdk>* folder, then run the following commands to setup build environment for HBird SDK, the output will be similar as the figure below.

    .. code-block:: shell

       setup.bat
       echo $PATH
       which riscv-nuclei-elf-gcc openocd make rm
       make help

    .. _figure_sdk_6:

    .. figure:: /asserts/medias/sdk_fig6.png
       :width: 800
       :alt: sdk_fig6

       Setup Build Environment for HBird SDK in Windows Command Line

- Linux
 
  - Creat *setup_config.sh* in *<hbird-sdk>* folder, and open this file with your editor, then paste the following content.
  
    .. code-block:: shell

       NUCLEI_TOOL_ROOT=<nuclei-tools>   
    
    .. note::
       
       The *<nuclei-tools>* here indicates the path where the tools are stored as mentioned above, which should be subject to the actual situation of the user. 
  
  - Open Linux bash terminal and cd to *<hbird-sdk>* folder, then run the following commands to setup build environment for HBird SDK, the output will be similar as the figure below.

    .. code-block:: shell

       source setup.sh
       echo $PATH
       which riscv-nuclei-elf-gcc openocd make rm
       make help

    .. _figure_sdk_7:

    .. figure:: /asserts/medias/sdk_fig7.png
       :width: 800
       :alt: sdk_fig7

       Setup Build Environment for HBird SDK in Linux Bash


Compile Hello World demo
########################

- Enter Hello World demo folder

  .. code-block:: shell

     cd <hbird-sdk>/application/baremetal/helloworld  

- Compile Hello World demo

  .. code-block:: shell

     make dasm SOC=hbirdv2 BOARD=ddr200t CORE=e203 DOWNLOAD=flashxip

  .. note::

     **dasm**, this Makefile target means to compile the application, and the function of other Makefile variables are shown in the table below.

  .. _table_sdk_1:
  
  .. table:: Function of Makefile variables in HBird SDK build system

     +-----------+------------+---------------+----------------------------------------------------------------------------------------+
     | Parameter | Options    | Default Value | Description                                                                            |
     +-----------+------------+---------------+----------------------------------------------------------------------------------------+
     | SOC       | hbirdv2    | hbirdv2       | Declare which SoC is used in application during compiling                              |
     +           +------------+               +                                                                                        +
     |           | hbird      |               |                                                                                        |
     +-----------+------------+---------------+----------------------------------------------------------------------------------------+
     | BOARD     | ddr200t    | ddr200t       | Declare which Board is used in application during compiling                            |
     +           +------------+               +                                                                                        +
     |           | mcu200t    |               |                                                                                        |
     +           +------------+               +                                                                                        +
     |           | hbird_eval |               |                                                                                        |
     +-----------+------------+---------------+----------------------------------------------------------------------------------------+
     | CORE      | e203       | e203          | Declare which Core is used in application during comiling                              |
     +-----------+------------+---------------+----------------------------------------------------------------------------------------+
     | DOWNLOAD  | ilm        | ilm           | Declare the download mode of the application                                           |
     +           +------------+               +                                                                                        +
     |           | flash      |               | - ilm: Program will be downloaded into ilm(itcm) and run directly in ilm               |
     +           +------------+               +                                                                                        +
     |           | flashxip   |               | - flash: Program will be downloaded into flash, and will be copied to ilm when running |
     +           +            +               +                                                                                        +
     |           |            |               | - flashxip: Program will be downloaded into flash, and run directly in flash           |
     +-----------+------------+---------------+----------------------------------------------------------------------------------------+
     | V         | 1          | NA            | If V=1, it will display compiling message in verbose including compiling options       |
     +-----------+------------+---------------+----------------------------------------------------------------------------------------+
     | SILENT    | 1          | NA            | If SILENT=1, it will not display any compiling message                                 |
     +-----------+------------+---------------+----------------------------------------------------------------------------------------+

 
.. _quickstart_run_hello_world:

Run Hello World demo
####################

**1. Hardware connection**

- Connect Nuclei ddr200t development board and your computer with HBird Debugger.
- Connect power supply and turn on the power switch on Nuclei dde200t development board.

.. figure:: /asserts/medias/sdk_fig8.png
   :width: 500
   :alt: sdk_fig8

   Connect with PC and power supply 


**2. Debugger driver install**

- Windows

  - HBird Debugger could be used without any driver installation in Windows.

  - Since HBird Debugger has the functionality that “convert the UART to USB”, so if you have completed hardware connection as described in **Step1**, then you will be able to see a USB Serial Port (e.g., COM8) show up in your Windows Device Manager.

- Linux

  - After hardware connection as described in **Step1** completed, you can use the following command to check the USB status.
 
    .. code-block:: console

       lsusb   // The example information displayed as below
       ...
       Bus 001 Device 010: ID 0403:6010 Future Technology Devices International, Ltd FT2232xxxx

  - Use the following command to set udev rules, to make this USB can be accessed by plugdev group.

    .. code-block:: console
    
       sudo vi /etc/udev/rules.d/99-openocd.rules
       // Use vi command to edit the file, and add the following lines
       SUBSYSTEM=="usb", ATTR{idVendor}=="0403",
       ATTR{idProduct}=="6010", MODE="664", GROUP="plugdev"
       SUBSYSTEM=="tty", ATTRS{idVendor}=="0403",
       ATTRS{idProduct}=="6010", MODE="664", GROUP="plugdev"

  - Add your user name into the plugdev group.
     
    .. code-block:: console

       whoami  
       // Use above command to check your user name, assuming it is your_user_name
       // Use below command to add your_user_name into plugdev group
       sudo usermod -a -G plugdev your_user_name

  - Double check if your user name is really belong to plugdev group.

    .. code-block:: console

       groups      // The example information showed as below after this command
       ... plugdev ...
       // As long as you can see plugdev in groups, then means it is really belong to. 

**3. Download and run**

- Use the following commands to compile and download application program.

  .. code-block:: shell
  
     cd <hbird-sdk>/application/baremetal/helloworld
     make upload SOC=hbirdv2 BOARD=ddr200t CORE=e203 DOWNLOAD=flash
  
  .. note::
     - The *<hbird-sdk>* here indicates the path where the HBird SDK project is stored as mentioned above, which should be subject to the actual situation of the user.    
     - **upload**, this Makefile target means to compile and upload the application, and the function of other Makefile variables are shown in this table :ref:`table_sdk_1`.
     

**3. Run result**

The function of Hello World demo is to print some info in the screen of PC through UART, so the serial port display terminal should be ready first.

- In Windows, there are so many serial port display terminals that can be used, such as Tera Term, PuTTY, etc. You can choose one you like, and install it, then using the following parameters to setup the UART terminal.

  .. code-block:: shell
  
     115200 baud, 8 bits data, no parity, 1 stop bit (115200-8-N-1)
     The port number depends on your device.

- In Linux, taking Ubuntu 18.04 as an example, you can use the following command to open UART terminal.

  .. code-block:: shell
  
     sudo screen /dev/ttyUSB1 115200

- After UART terminal opened, you can press the **MCU_RESET** button on Nuclei ddr200t development board to reset MCU and the Hello World program  will be executed again, the result is shown in the figure below.

  .. figure:: /asserts/medias/sdk_fig10.png
     :width: 700
     :alt: sdk_fig10
    
     Hello World demo output
  
  .. note::
    
     Since the application program is uploaded to MCU Flash, so you can re-execute the program by re-powering or pressing **MCU_RESET** button. 

   
Debug Hello World demo
######################

**1. Hardward connection**

- Same as **Step1** in :ref:`quickstart_run_hello_world`.

**2. Debugger driver install**

- Same as **Step2** in :ref:`quickstart_run_hello_world`.

  .. note::
     
     If the Debugger driver has been installed successfully, don't need to install it again.

**3. Debug**

- Use the following commands to compile application program and enter debug mode.

  .. code-block:: shell
  
     cd <hbird-sdk>/application/baremetal/helloworld
     make debug SOC=hbirdv2 BOARD=ddr200t CORE=e203
  
  .. note::
         
     - The *<hbird-sdk>* here indicates the path where the HBird SDK project is stored as mentioned above, which should be subject to the actual situation of the user.    
     - **debug**, this Makefile target means to compile application and enter debug mode, the function of other Makefile variables are shown in this table :ref:`table_sdk_1`.
  
- After entering debug mode, using the following GDB command, the compiled program will be uploaded, shown in the figure below.

  .. code-block:: shell
  
     load
  
  .. figure:: /asserts/medias/sdk_fig11.jpg
     :width: 800
     :alt: sdk_fig11
  
     Program download   

- Some commonly used GDB debugging commands are shown as following.

  - Set breakpoint
  
    .. code-block:: shell
       
       b main
  
  - Check breakpoint info, result shown in the figure below
  
    .. code-block:: shell
       
       info b
  
    .. figure:: /asserts/medias/sdk_fig12.jpg
       :width: 800
       :alt: sdk_fig12
    
       Breakpoint info   
  
  - Read memory data, result shown in the figure below
  
    .. code-block:: shell
       
       x 0x80000000
       x 0x80000004
       x 0x80000008
  
    .. figure:: /asserts/medias/sdk_fig13.jpg
       :width: 800
       :alt: sdk_fig13
    
       Memory data
  
  - Read register value, result shown in the figure below
  
    .. code-block:: shell
       
       info reg
       info reg mstatus
       info reg csr768
  
    .. figure:: /asserts/medias/sdk_fig14.jpg
       :width: 800
       :alt: sdk_fig14
    
       Register value
  
  - Continue execution, stop at the breakpoint, result shown in the figure below
  
    .. code-block:: shell
       
       continue
  
    .. figure:: /asserts/medias/sdk_fig15.jpg
       :width: 800
       :alt: sdk_fig15
    
       Stop at breakpoint
  
  - Single step, result shown in the figure below
  
    .. code-block:: shell
       
       ni 
  
    .. figure:: /asserts/medias/sdk_fig16.jpg
       :width: 800
       :alt: sdk_fig16
    
       Single step
