source setup_proj.tcl 

close [open __synthesis_is_running__ w]

# read synth command line args from file
set args {}
set fh [open "synth_args.tcl" r]
while {[gets $fh line] >= 0} {
    lappend args $line
}
close $fh
set fh [open "cart.tcl" r]
while {[gets $fh line] >= 0} {
    lappend args $line
}
close $fh
set synth_command "synth_design -top $TOPMODULE -part $DEVICE"
foreach arg $args {
    append synth_command " $arg"
}

eval $synth_command

# disable binary constraint mode for synth run checkpoints
set_param constraints.enableBinaryConstraints false
write_checkpoint -force -noxdef $TOPMODULE.dcp
create_report "synth_1_synth_report_utilization_0" "report_utilization -file ${TOPMODULE}_utilization_synth.rpt -pb ${TOPMODULE}_utilization_synth.pb"
file delete __synthesis_is_running__
close [open __synthesis_is_complete__ w]
