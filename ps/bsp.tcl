createhw -name HW_Platform -hwspec ../../FPGA/system_wrapper.hdf
createbsp -name BSP -proc ps7_cortexa9_0 -hwproject HW_Platform -os standalone
configbsp -hw HW_Platform -bsp BSP stdin ps7_uart_1
configbsp -hw HW_Platform -bsp BSP stdout ps7_uart_1
configbsp -hw HW_Platform -bsp BSP compiler arm-xilinx-eabi-gcc
configbsp -hw HW_Platform -bsp BSP archiver arm-xilinx-eabi-ar
setlib -hw HW_Platform -bsp fsbl_bsp -lib xilffs
configbsp -hw HW_Platform -bsp fsbl_bsp  enable_mmc true
setlib -hw HW_Platform -bsp BSP -lib xilrsa
updatemss -hw HW_Platform -mss BSP/system.mss
regenbsp -hw HW_Platform -bsp BSP