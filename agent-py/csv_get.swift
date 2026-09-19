
(string line)
csv_get1(file f, location CSV_GET)
{
  line =
    @location=CSV_GET
    python_persist("import cfg_edit",
                   "cfg_edit.csv_get('%s')" %
                   filename(f));
}
