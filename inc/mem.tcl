# Check if the correct number of arguments is provided
if {[llength $argv] != 4} {
    puts "Usage: tclsh impl.tcl <top_module> <device> <impl_dcp> <proj_path>"
    exit 1
}
set TOPMODULE [lindex $argv 0]
set DEVICE [lindex $argv 1]
set IMPL_DCP [lindex $argv 2]
set PROJ [lindex $argv 3]

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
proc start_step { step } {
  set stopFile ".stop.rst"
  if {[file isfile .stop.rst]} {
    puts ""
    puts "*** Halting run - EA reset detected ***"
    puts ""
    puts ""
    return -code error
  }
  set beginFile ".$step.begin.rst"
  set platform "$::tcl_platform(platform)"
  set user "$::tcl_platform(user)"
  set pid [pid]
  set host ""
  if { [string equal $platform unix] } {
    if { [info exist ::env(HOSTNAME)] } {
      set host $::env(HOSTNAME)
    }
  } else {
    if { [info exist ::env(COMPUTERNAME)] } {
      set host $::env(COMPUTERNAME)
    }
  }
  set ch [open $beginFile w]
  puts $ch "<?xml version=\"1.0\"?>"
  puts $ch "<ProcessHandle Version=\"1\" Minor=\"0\">"
  puts $ch "    <Process Command=\".planAhead.\" Owner=\"$user\" Host=\"$host\" Pid=\"$pid\">"
  puts $ch "    </Process>"
  puts $ch "</ProcessHandle>"
  close $ch
}

proc end_step { step } {
  set endFile ".$step.end.rst"
  set ch [open $endFile w]
  close $ch
}

proc step_failed { step } {
  set endFile ".$step.error.rst"
  set ch [open $endFile w]
  close $ch
}


puts "Initilizing design $TOPMODULE for device $DEVICE"

start_step write_mem
set ACTIVE_STEP write_mem
set rc [catch {
  create_msg_db write_mem.pb
  create_project -in_memory -part xc7z010clg400-1
  set_property design_mode GateLvl [current_fileset]

  add_files -quiet $IMPL_DCP
  puts "Read: $IMPL_DCP"

  write_mem_info $TOPMODULE.mmi

  close_msg_db -file write_mem.pb
} RESULT]
if {$rc} {
  step_failed write_mem
  return -code error $RESULT
} else {
  end_step write_mem
  unset ACTIVE_STEP 
}
