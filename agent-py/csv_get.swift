
(string line)
csv_get(location CSV_GET, string filename)
{
  @location=CSV_GET python_persist("import ",
                              "result_log.do_write(\"%s\", \"%s\")" %
                              (filename, record));
}
