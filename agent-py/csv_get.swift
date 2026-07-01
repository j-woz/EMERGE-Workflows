
(string line)
csv_get1(string filename, location CSV_GET)
{
  line =
    @location=CSV_GET
    python_persist("import cfg_edit",
                   "cfg_edit.csv_get('%s')" %
                   filename);
}
