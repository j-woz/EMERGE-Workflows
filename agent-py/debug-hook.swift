
import python;

report_tmp(int idx)
{
  python_persist("import debug",
                 "debug.report_tmp(%i)" % idx);
}

foreach idx in [0:5]
{
  report_tmp(idx);
}
