################################################
# File Name    : dc_syn.tcl                    #
# Author       : ChongHa_Xu                    #
# Description  :                               #
#                                              #
# Desing_Source-                               #
#        Circuit     :Circuit_Name.v(.sv)      #
#        Constraints :Constraint.sdc           #
#                                              #
################################################
set Design_Source ../src
set Project_Name TPA 
################################################




############ Read Files ############
####################################
read_file -format verilog  $Design_Source/$Project_Name.v
#read_file -format sverilog  $Design_Source/$Project_Name.sv
current_design $Project_Name
link
####################################

######## Setting Constraints ######
#################################
source -echo -verbose $Design_Source/$Project_Name.sdc
check_design
set high_fanout_net_threshold 0
uniquify
set_fix_multiple_port_nets -all -buffer_constants [get_designs *]
#set_max_area 0
####################################



######## Synthesis all design #####
####################################
#compile -map_effort high -area_effort high
#compile -map_effort high -area_effort high -inc
compile_ultra
####################################



########## Write Out ###############
####################################
set Project_Name_syn [append Project_Name "_syn"]
file mkdir Results
file mkdir Reports
write -format ddc     -hierarchy -output "./Results/$Project_Name_syn.ddc"
write_sdf -version 1.0 "./Results/$Project_Name_syn.sdf"
write -format verilog -hierarchy -output "./Results/$Project_Name_syn.v"
report_area > ./Reports/area.log
report_timing -delay_type min > ./Reports/timing_min.log
report_timing -delay_type max > ./Reports/timing_max.log
report_qor   >  ./Reports/$Project_Name_syn.qor
####################################
quit
