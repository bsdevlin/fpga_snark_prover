# This is a generated file. Use and modify at your own risk.
################################################################################

open_project prj
open_solution sol
set_part  xcvu9p-flga2104-2-e
add_files ../multiexp_kernel_cmodel.cpp
set_top multiexp_kernel
config_sdx -optimization_level none -target xocc
config_rtl -auto_prefix=0
csynth_design
exit

