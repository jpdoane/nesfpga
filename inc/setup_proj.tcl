# Check if the correct number of arguments is provided
if {[llength $argv] != 3} {
    puts "Usage: tclsh synth.tcl <top_module> <device> <proj_path>"
    exit 1
}
set TOPMODULE [lindex $argv 0]
set DEVICE [lindex $argv 1]
set PROJ [lindex $argv 2]

puts "Constructing design $TOPMODULE for device $DEVICE"

set TIME_start [clock seconds] 
proc create_report { reportName command } {
  set status "."
  append status $reportName ".fail"
  if { [file exists $status] } {
    eval file delete [glob $status]
  }
  send_msg_id runtcl-4 info "Executing : $command"
  set retval [eval catch { $command } msg]
  if { $retval != 0 } {
    set fp [open $status w]
    close $fp
    send_msg_id runtcl-5 warning "$msg"
  }
}


create_project -part $DEVICE -force $TOPMODULE $TOPMODULE 

#set_part $DEVICE
set_param project.singleFileAddWarning.threshold 0
# set_param project.compositeFile.enableAutoGeneration 0 # <-- this line makes block diagram fail
set_param synth.vivado.isSynthRun true
set_property webtalk.parent_dir ${PROJ}/cache/wt [current_project]
#set_property default_lib xil_defaultlib [current_project]
set_property default_lib work [current_project]
set_property target_language Verilog [current_project]
set_property ip_output_repo ${PROJ}/cache/ip [current_project]
set_property ip_cache_permissions {read write} [current_project]


# load verilog source
set fh [open "${PROJ}/sources.tcl" r]
while {[gets $fh filename] >= 0} {
  puts "Reading source $filename"
  # read_verilog -library xil_defaultlib -sv $filename
  read_verilog -sv $filename
}
close $fh

set fh [open "${PROJ}/bd_sources.tcl" r]
while {[gets $fh filename] >= 0} {
  puts "Building block design from tcl file $filename"
  source $filename
  set_property synth_checkpoint_mode None [get_files $design_name.bd]
  generate_target all [get_files $design_name.bd]
}
close $fh
puts "Done with BD"

# Mark all dcp files as not used in implementation to prevent them from being
# stitched into the results of this synthesis run. Any black boxes in the
# design are intentionally left as such for best results. Dcp files will be
# stitched into the design at a later time, either when this synthesis run is
# opened, or when it is stitched into a dependent implementation run.
foreach dcp [get_files -quiet -all -filter file_type=="Design\ Checkpoint"] {
  set_property used_in_implementation false $dcp
}

# load constraints
set fh [open "${PROJ}/constraints.tcl" r]
while {[gets $fh filename] >= 0} {
    read_xdc $filename
    set_property used_in_implementation false [get_files $filename]
    puts "Read constriant: $filename"
}
close $fh

set_param ips.enableIPCacheLiteLoad 0

#write_project_tcl -no_copy_sources -use_bd_files -force ${PROJ}/make_proj.tcl