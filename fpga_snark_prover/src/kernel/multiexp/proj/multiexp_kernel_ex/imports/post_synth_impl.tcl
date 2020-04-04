# This is a generated file. Use and modify at your own risk.
################################################################################

catch {
if {[lsearch [tclapp::list_apps] {xilinx::designutils}] == -1} {
tclapp::install designutils
}
}

catch {::tclapp::xilinx::designutils::report_failfast -no_methodology_check -show_resources -detailed_report failfast -file failfast.summary.rpt}
