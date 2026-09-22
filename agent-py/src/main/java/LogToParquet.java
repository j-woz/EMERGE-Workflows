import org.json.simple.JSONValue;

import blue.strategic.parquet.Dehydrator;

import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.DefaultParser;
import org.apache.commons.cli.HelpFormatter;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;

import org.apache.parquet.hadoop.ParquetWriter;

import org.apache.parquet.schema.MessageType;
import org.apache.parquet.schema.Types;
import org.apache.parquet.schema.PrimitiveType.PrimitiveTypeName;

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.util.*;

/**
   Convert an EMERGE results log into a Parquet file matching the
   reference "long" format (see part-000000.parquet):

   - each record's output_dat text table is exploded into one row
     per Day
   - columns: row_id (=task_id), seed, Day, then a fixed subset of
     the simulation columns (renamed  /  to  _ )

   The log is a sequence of fixed-size blocks, each holding one
   pretty-printed JSON object padded out to the block boundary.
   The object values (output_dat) contain literal newlines, which
   JSON forbids, so we escape control chars inside strings before
   parsing.  To keep memory bounded we auto-detect the block size,
   then read and write one block at a time.
*/
public class LogToParquet
{
  // The default 17 data columns selected from output_dat, in reference
  // order.  Names here are the RENAMED (/ -> _) forms that appear
  // in the parquet.
  private static final String[] DATA_COLUMNS = {
    "Su", "PS_PI", "S_PI_NH", "S_PI_H", "PS_I", "S_I_NH", "S_I_H",
    "A_PI", "A_I", "H_NI", "H_I", "ICU", "V", "R", "D", "NewS",
    "NewH"
  };

  // The data columns actually written, in reference order: all of
  // DATA_COLUMNS unless -c narrowed the selection.  Set once at
  // startup, before any schema or row is built.
  private static String[] dataColumns = DATA_COLUMNS;

  // Set true and rebuild to split the run time between our own
  // parsing and the Parquet API.  Being a compile-time constant, the
  // guarded blocks are dropped by javac when this is false, so the
  // read loop pays nothing for the instrumentation.
  private static final boolean profilingEnabled = false;

  // Nanoseconds in our JSON/table parsing, and in Parquet API calls
  private static long parseTime = 0;
  private static long parquetTime = 0;

  public static void main(String[] args)
  throws Exception
  {
    Options options = new Options();
    options.addOption("a", false,
                      "append every result*.log in PWD to one file");
    options.addOption("P", false,
                      "report conversion progress as a percentage");
    options.addOption("c", true,
                      "file naming the data columns to write");
    options.addOption("h", false,
                      "show this help message");

    CommandLine cmd = null;
    try
    {
      cmd = new DefaultParser().parse(options, args);
    }
    catch (ParseException e)
    {
      System.err.println("Error: " + e.getMessage());
      usage(options, 1);
    }

    // Asking for help is not an error, so it goes to stdout and
    // exits 0, letting "log2pqt -h | less" work
    if (cmd.hasOption("h")) usage(options, 0);

    boolean appendMode = cmd.hasOption("a");
    boolean progress = cmd.hasOption("P");
    String[] rest = cmd.getArgs();

    // -a takes the output alone; otherwise input and output
    if (rest.length != (appendMode ? 1 : 2)) usage(options, 1);

    // Narrow the schema before anything is built from it
    if (cmd.hasOption("c"))
      dataColumns = readColumns(cmd.getOptionValue("c"));

    MessageType schema = buildSchema();
    System.out.println("Schema:\n" + schema);

    if (appendMode)
    {
      String outputPath = rest[0];
      if (new File(outputPath).exists())
      {
        System.err.println("Error: output file already exists: " +
                           outputPath);
        System.exit(1);
      }

      File[] logFiles = new File(".").listFiles((dir, name) ->
        name.startsWith("result") && name.endsWith(".log"));

      if (logFiles == null || logFiles.length == 0)
      {
        System.err.println("Error: no result*.log files found in " +
                           new File(".").getAbsolutePath());
        System.exit(1);
      }
      Arrays.sort(logFiles);

      System.out.println("Input files: " + logFiles.length);
      for (File f : logFiles)
      {
        System.out.println("  " + f.getName() + "  " +
                           f.length()/1024 + " KB");
      }
      System.out.println();

      for (File f : logFiles) checkNotEmpty(f);

      try
      {
        convertAll(logFiles, outputPath, schema, progress);
      }
      catch (DuplicateTaskException e)
      {
        abortDuplicate(e, outputPath);
      }
    }
    else
    {
      String inputPath = rest[0];
      String outputPath = rest[1];

      checkNotEmpty(new File(inputPath));

      long blockSize = detectBlockSize(inputPath);
      System.out.println("Block size: " + blockSize/1024 + " KB");

      long fileSize = new File(inputPath).length();
      long blocks = (blockSize > 0) ? (fileSize / blockSize) : 0;
      System.out.println("File size: " + fileSize/1024 + " KB");
      System.out.println("Expected blocks: " + blocks);

      long startTime = System.currentTimeMillis();
      long[] counts = convert(inputPath, outputPath, blockSize,
                              schema);

      System.out.println("Loaded " + counts[0] +
                         " records from " + inputPath);
      System.out.println("Wrote " + counts[1] + " rows to " +
                         outputPath);
      reportRate(fileSize,
                 System.currentTimeMillis() - startTime);
      reportProfile();
    }
  }

  /**
     Read the column selection file: whitespace-separated names, in
     any arrangement across lines, with '#' comments.

     StreamTokenizer does that natively, so there is nothing to parse
     by hand.  Names are reordered to match DATA_COLUMNS, keeping the
     column order of the reference format whatever order the file
     lists them in.  An unrecognized name is an error: silently
     dropping it would produce a Parquet missing a column the caller
     asked for.
  */
  private static String[] readColumns(String path)
  throws IOException
  {
    if (!new File(path).isFile())
    {
      System.err.println("Error: column file not found: " + path);
      System.exit(1);
    }

    Set<String> wanted = new LinkedHashSet<>();

    try (Reader reader = new BufferedReader(new FileReader(path)))
    {
      StreamTokenizer tok = new StreamTokenizer(reader);
      tok.resetSyntax();
      tok.wordChars('!', '~');      // any printable: names, digits, _
      tok.whitespaceChars(0, ' ');  // space, tab, newline, CR
      tok.commentChar('#');

      while (tok.nextToken() != StreamTokenizer.TT_EOF)
      {
        if (tok.ttype == StreamTokenizer.TT_WORD) wanted.add(tok.sval);
      }
    }

    if (wanted.isEmpty())
    {
      System.err.println("Error: no column names in " + path);
      System.exit(1);
    }

    List<String> known = Arrays.asList(DATA_COLUMNS);
    List<String> unknown = new ArrayList<>(wanted);
    unknown.removeAll(known);
    if (!unknown.isEmpty())
    {
      System.err.println("Error: unknown column name(s) in " + path +
                         ": " + String.join(" ", unknown));
      System.err.println("Known columns: " + String.join(" ", known));
      System.exit(1);
    }

    List<String> selected = new ArrayList<>(known);
    selected.retainAll(wanted);
    System.out.println("Columns (" + selected.size() + " of " +
                       DATA_COLUMNS.length + "): " +
                       String.join(" ", selected));
    return selected.toArray(new String[0]);
  }

  /**
     Lay out column names in indented lines, wrapping before the help
     formatter can break the list at an arbitrary point.
  */
  private static String
  columnList(String[] names, String indent, int width)
  {
    StringBuilder out = new StringBuilder();
    StringBuilder line = new StringBuilder(indent);

    for (String name : names)
    {
      if (line.length() > indent.length() &&
          line.length() + 1 + name.length() > width)
      {
        out.append(line).append('\n');
        line = new StringBuilder(indent);
      }
      if (line.length() > indent.length()) line.append(' ');
      line.append(name);
    }
    out.append(line).append('\n');

    return out.toString();
  }

  /**
     An empty log means the run produced nothing, so there is no
     conversion to do.  Catch it up front rather than letting
     block-size detection return 0 and the read loop quietly write an
     empty Parquet that looks like a successful result.
  */
  private static void checkNotEmpty(File logFile)
  {
    if (logFile.length() != 0) return;

    System.err.println("Error: empty log file: " + logFile.getPath());
    System.exit(1);
  }

  /**
     Print the usage message and exit with the given status: 0 when
     help was asked for, 1 when the command line was wrong.
  */
  private static void usage(Options options, int status)
  {
    String header =
      "\nConvert EMERGE result logs to Parquet.\n\n";

    String footer =
      "\nWithout -a, one log is converted to one Parquet file.\n" +
      "With -a, every result*.log in the current directory is read\n" +
      "in one pass into a single Parquet file.  That file must not\n" +
      "already exist: Parquet cannot be appended to in place, so the\n" +
      "logs present are taken to be the whole input.\n" +
      "\n" +
      "Every task_id must be unique across the input.  The first\n" +
      "repeat stops the run; the partial output is left marked\n" +
      "incomplete in its footer.\n" +
      "\n" +
      "The columns file for -c holds whitespace-separated column\n" +
      "names, with # starting a comment.  Without it, all " +
      DATA_COLUMNS.length + " data\n" +
      "columns are written.  Known columns:\n" +
      columnList(DATA_COLUMNS, "  ", 66) +
      "\n" +
      "Every run reports its elapsed time and read bandwidth.\n";

    HelpFormatter formatter = new HelpFormatter();
    PrintWriter out =
      new PrintWriter(status == 0 ? System.out : System.err, true);

    formatter.printHelp(out, formatter.getWidth(),
                        "log2pqt [-P] [-c columns.txt] " +
                        "<input.log> <output.parquet>\n" +
                        "       log2pqt [-P] [-c columns.txt] " +
                        "-a <output.parquet>",
                        header, options, formatter.getLeftPadding(),
                        formatter.getDescPadding(), footer, false);

    System.exit(status);
  }

  /**
     Determine the fixed block size by locating the byte offset of
     the second top-level object.  Each record is written at the
     start of a block, so that offset is the block stride.  If the
     file holds only one block, the block size is the file length.
  */
  private static long detectBlockSize(String filePath)
  throws IOException
  {
    try (InputStream in =
         new BufferedInputStream(new FileInputStream(filePath)))
    {
      long pos = 0;
      int depth = 0;
      boolean inString = false;
      boolean escaped = false;
      boolean firstDone = false;

      int b;
      while ((b = in.read()) != -1)
      {
        char c = (char) b;

        if (firstDone)
        {
          // First object closed; the next '{' begins block two.
          if (c == '{') return pos;
        }
        else if (inString)
        {
          if (escaped)           escaped = false;
          else if (c == '\\')    escaped = true;
          else if (c == '"')     inString = false;
        }
        else
        {
          if (c == '"')          inString = true;
          else if (c == '{')     depth++;
          else if (c == '}')
          {
            depth--;
            if (depth == 0) firstDone = true;
          }
        }
        pos++;
      }

      // Only one block in the file.
      return pos;
    }
  }

  /**
     Stream the file one block at a time: read blockSize bytes,
     parse the single object it contains, explode it to per-Day
     rows, and write them.  The leading header block, if present,
     becomes the Parquet file's key/value metadata rather than data.
     Returns {recordCount, rowCount}.
  */
  private static long[]
  convert(String inputPath, String outputPath, long blockSize,
          MessageType schema)
  throws IOException
  {
    if (blockSize > Integer.MAX_VALUE)
    {
      throw new IOException("Block size too large: " + blockSize);
    }

    List<String> names = columnNames();
    Dehydrator<Object[]> dehydrator = (row, valueWriter) ->
    {
      for (int i = 0; i < names.size(); i++)
      {
        valueWriter.write(names.get(i), row[i]);
      }
    };

    long records = 0;
    long rows = 0;
    File out = new File(outputPath);
    byte[] buf = new byte[(int) blockSize];

    try (InputStream in =
         new BufferedInputStream(new FileInputStream(inputPath)))
    {
      // Read the first block before opening the writer: Parquet
      // key/value metadata has to be handed over up front.
      Map<String, Object> first = null;
      int n = readBlock(in, buf);
      if (n > 0)
      {
        first = parseBlock(new String(buf, 0, payloadLength(buf, n),
                                      StandardCharsets.UTF_8));
      }

      Map<String, String> metadata = new LinkedHashMap<>();
      if (isHeader(first))
      {
        for (Map.Entry<String, Object> entry : first.entrySet())
        {
          // "header" only marks the block; it is not real metadata
          if (entry.getKey().equals("header")) continue;
          metadata.put(entry.getKey(),
                       String.valueOf(entry.getValue()));
        }
        printMetadata(metadata);
        first = null;
      }

      try (ParquetWriter<Object[]> writer =
           MetadataParquetWriter.open(schema, out, dehydrator,
                                      metadata))
      {
        // The first block, when it held a result and not the header
        if (first != null)
        {
          records++;
          rows += writeRecord(writer, first);
        }

        while ((n = readBlock(in, buf)) > 0)
        {
          Map<String, Object> record =
            parseBlock(new String(buf, 0, payloadLength(buf, n),
                                  StandardCharsets.UTF_8));
          if (record == null) continue;
          records++;
          rows += writeRecord(writer, record);
        }

        if (profilingEnabled) closeTimed(writer);
      }
    }

    return new long[] { records, rows };
  }

  /**
     Append mode: write every result*.log into one Parquet file in a
     single streaming pass, with one writer held open across the whole
     set.  The logs are far too large to stage and concatenate, so the
     read loop simply moves on to the next file when one runs out.

     The caller has already established that the output file does not
     exist, so the logs on disk are the complete input.  Every task_id
     must therefore be unique across the set; the first repeat stops
     the conversion.
  */
  private static void
  convertAll(File[] logFiles, String outputPath, MessageType schema,
             boolean showProgress)
  throws IOException
  {
    List<String> names = columnNames();
    Dehydrator<Object[]> dehydrator = (row, valueWriter) ->
    {
      for (int i = 0; i < names.size(); i++)
      {
        valueWriter.write(names.get(i), row[i]);
      }
    };

    // The run's header block is written once, at the top of the first
    // log; the later parts carry results only.  Parquet key/value
    // metadata has to be handed over when the writer opens, so that
    // block is read up front.
    Map<String, String> metadata = readMetadata(logFiles[0]);
    if (metadata.isEmpty()) abortNoHeader(logFiles[0]);
    printMetadata(metadata);

    // task_id -> the log it was first seen in, for the error message
    Map<Long, String> seen = new HashMap<>();
    long records = 0;
    long rows = 0;

    // Progress runs over the byte total of the whole set, so it does
    // not restart at each file.
    long totalBytes = 0;
    for (File f : logFiles) totalBytes += f.length();
    long bytesDone = 0;
    int lastPercent = -1;
    long startTime = System.currentTimeMillis();

    try (ParquetWriter<Object[]> writer =
         MetadataParquetWriter.open(schema, new File(outputPath),
                                    dehydrator, metadata))
    {
      for (File logFile : logFiles)
      {
        long blockSize = detectBlockSize(logFile.getPath());
        if (blockSize <= 0 || blockSize > Integer.MAX_VALUE)
        {
          System.err.println("ERROR: bad block size " + blockSize +
                             " in " + logFile.getName() +
                             ": skipping file");
          continue;
        }

        long fileRecords = 0;
        long fileRows = 0;
        byte[] buf = new byte[(int) blockSize];

        try (InputStream in = new BufferedInputStream(
               new FileInputStream(logFile)))
        {
          int n;
          while ((n = readBlock(in, buf)) > 0)
          {
            bytesDone += n;
            if (showProgress)
              lastPercent = reportProgress(bytesDone, totalBytes,
                                           lastPercent);

            Map<String, Object> record =
              parseBlock(new String(buf, 0, payloadLength(buf, n),
                                    StandardCharsets.UTF_8));
            if (record == null || isHeader(record)) continue;

            long taskId = asLong(record.get("task_id"));
            String origin = seen.put(taskId, logFile.getName());
            if (origin != null)
              throw foundDuplicate(taskId, logFile.getName(),
                                   origin, metadata);

            fileRecords++;
            fileRows += writeRecord(writer, record);
          }
        }

        if (showProgress) clearProgress();
        System.out.println(logFile.getName() + ": " + fileRecords +
                           " records, " + fileRows + " rows");
        records += fileRecords;
        rows += fileRows;
      }

      // The writer's close() flushes the last row group and writes
      // the footer, so time it with the rest of the Parquet work.
      if (profilingEnabled) closeTimed(writer);
    }

    System.out.println();
    System.out.println("Loaded " + records + " records from " +
                       logFiles.length + " files");
    System.out.println("Wrote " + rows + " rows to " + outputPath);
    reportRate(bytesDone, System.currentTimeMillis() - startTime);
    reportProfile();
  }

  /**
     Close the writer inside the Parquet timer.  close() flushes the
     final row group and writes the footer, which is real Parquet work
     and would otherwise land outside both accumulators.  The
     try-with-resources close that follows is a no-op: ParquetWriter
     tracks whether it has already closed.
  */
  private static void closeTimed(ParquetWriter<Object[]> writer)
  throws IOException
  {
    long start = System.nanoTime();
    writer.close();
    parquetTime += System.nanoTime() - start;
  }

  /**
     Report where the run spent its time.  Parsing and Parquet will
     not add up to the wall clock: reading, the block scan, and the
     UTF-8 decode sit outside both.
  */
  private static void reportProfile()
  {
    if (!profilingEnabled) return;

    System.out.printf("Profile: parse %.1f s, parquet %.1f s\n",
                      parseTime / 1e9, parquetTime / 1e9);
  }

  /**
     Report how long the conversion took and how fast the logs were
     consumed.  The rate covers the whole pipeline -- read, parse,
     explode, compress, write -- so it runs well under what the
     filesystem alone would give.
  */
  private static void reportRate(long bytes, long elapsedMillis)
  {
    double seconds = elapsedMillis / 1e3;
    System.out.printf("Read %.0f MB in %.1f s: %.1f MB/s\n",
                      bytes / 1e6, seconds,
                      (seconds > 0) ? (bytes / 1e6 / seconds) : 0.0);
  }

  /**
     A task_id may only be written once.  Seeing it again means the
     input set is wrong -- the same results are staged twice -- so
     stop rather than write a file that silently disagrees with the
     logs.

     The rows written so far are left on disk, marked incomplete in
     the footer: throwing unwinds through the writer's close(), so the
     file is still valid Parquet and the marker travels with it.  The
     caller must delete it before re-running.
  */
  private static DuplicateTaskException
  foundDuplicate(long taskId, String logFile, String origin,
                   Map<String, String> metadata)
  {
    String message = "duplicate task_id " + taskId + ": found in " +
                     logFile + ", already read from " + origin;
    metadata.put("incomplete", message);
    return new DuplicateTaskException(message);
  }

  /** Raised on the first repeated task_id; stops the conversion. */
  private static final class DuplicateTaskException
  extends RuntimeException
  {
    DuplicateTaskException(String message) { super(message); }
  }

  /**
     Report a duplicate task_id and exit.  The partial output stays on
     disk so it can be inspected, but it is not a usable result.
  */
  private static void
  abortDuplicate(DuplicateTaskException e, String outputPath)
  {
    System.err.println();
    System.err.println("ERROR: " + e.getMessage());
    System.err.println("Partial output: " + outputPath);
    System.exit(1);
  }

  /**
     Redraw the progress line, but only when the whole-number percent
     has advanced: a block is small next to the total, so refreshing
     on every one would write thousands of identical lines.  Returns
     the percent now displayed, to be passed back on the next call.
  */
  private static int
  reportProgress(long done, long total, int lastPercent)
  {
    if (total <= 0) return lastPercent;

    int percent = (int) (100 * done / total);
    if (percent == lastPercent) return lastPercent;

    // No newline: the carriage return parks the cursor at the start
    // of the line so the next write covers this one.
    System.out.print("\rProgress: " + percent + "%");
    System.out.flush();
    return percent;
  }

  /**
     Retire the progress line so ordinary output does not land on top
     of it.  The spaces wipe the text the carriage return left behind.
  */
  private static void clearProgress()
  {
    System.out.print("\r                    \r");
    System.out.flush();
  }

  /**
     Report a first log that carries no header block and exit.  The
     run writes its header once, at the top of the first part, so the
     part holding it is missing from this directory.
  */
  private static void abortNoHeader(File logFile)
  {
    System.err.println();
    System.err.println("ERROR: no header block in " +
                       logFile.getName() + ", which sorts first " +
                       "and so should begin the run");
    System.err.println("The result*.log set here is incomplete: " +
                       "the part holding the header is missing");
    System.exit(1);
  }

  /**
     Read the header block of a log, if it has one, as the key/value
     metadata for the Parquet footer.
  */
  private static Map<String, String> readMetadata(File logFile)
  throws IOException
  {
    Map<String, String> metadata = new LinkedHashMap<>();

    long blockSize = detectBlockSize(logFile.getPath());
    if (blockSize <= 0 || blockSize > Integer.MAX_VALUE)
      return metadata;

    byte[] buf = new byte[(int) blockSize];
    Map<String, Object> first;
    try (InputStream in = new BufferedInputStream(
           new FileInputStream(logFile)))
    {
      int n = readBlock(in, buf);
      if (n <= 0) return metadata;
      first = parseBlock(new String(buf, 0, payloadLength(buf, n),
                                    StandardCharsets.UTF_8));
    }

    if (!isHeader(first)) return metadata;

    for (Map.Entry<String, Object> entry : first.entrySet())
    {
      // "header" only marks the block; it is not real metadata
      if (entry.getKey().equals("header")) continue;
      metadata.put(entry.getKey(), String.valueOf(entry.getValue()));
    }
    return metadata;
  }

  /**
     The header block is tagged header=true; logs written before that
     tag existed are recognized by carrying no result table.
  */
  private static boolean isHeader(Map<String, Object> record)
  {
    if (record == null) return false;
    return record.containsKey("header") ||
           !record.containsKey("output_dat");
  }

  /**
     Explode one record and write its rows.  Returns the row count.
  */
  private static long
  writeRecord(ParquetWriter<Object[]> writer,
              Map<String, Object> record)
  throws IOException
  {
    long start = profilingEnabled ? System.nanoTime() : 0;

    List<Object[]> rows = new ArrayList<>();
    explode(record, rows);

    if (profilingEnabled)
    {
      long now = System.nanoTime();
      parseTime += now - start;
      start = now;
    }

    for (Object[] row : rows)
    {
      writer.write(row);
    }

    if (profilingEnabled) parquetTime += System.nanoTime() - start;

    return rows.size();
  }

  /**
     Length of the record within a block, ignoring the NUL bytes that
     pad it out to the block boundary.  Roughly half of a block is
     padding, and decoding it to UTF-16 only to skip it later is the
     single largest avoidable cost in the read loop.
  */
  private static int payloadLength(byte[] buf, int n)
  {
    int end = n;
    while (end > 0 && buf[end - 1] == 0) end--;
    return end;
  }

  /**
     Read up to buf.length bytes, coping with short reads.  Returns
     the number of bytes read (0 at end of file).
  */
  private static int readBlock(InputStream in, byte[] buf)
  throws IOException
  {
    int total = 0;
    while (total < buf.length)
    {
      int r = in.read(buf, total, buf.length - total);
      if (r == -1) break;
      total += r;
    }
    return total;
  }

  /**
     Extract and parse the first top-level JSON object in a block,
     escaping the literal control chars that appear inside string
     values.  Trailing block padding is ignored.  Returns null if
     no object is found.
  */
  private static Map<String, Object> parseBlock(String block)
  {
    if (!profilingEnabled) return parseBlockInner(block);

    long start = System.nanoTime();
    Map<String, Object> record = parseBlockInner(block);
    parseTime += System.nanoTime() - start;
    return record;
  }

  private static Map<String, Object> parseBlockInner(String block)
  {
    StringBuilder obj = new StringBuilder();
    boolean inString = false;
    boolean escaped = false;
    int depth = 0;

    for (int i = 0; i < block.length(); i++)
    {
      char c = block.charAt(i);

      // Outside any object, skip padding / whitespace until '{'
      if (depth == 0 && !inString && c != '{') continue;

      if (inString)
      {
        if (escaped)
        {
          obj.append(c);
          escaped = false;
          continue;
        }
        if (c == '\\')
        {
          obj.append(c);
          escaped = true;
          continue;
        }
        if (c == '"')
        {
          obj.append(c);
          inString = false;
          continue;
        }
        // Escape literal control chars that are illegal in JSON
        // strings (the whole point of this preprocessing).
        if (c == '\n')      obj.append("\\n");
        else if (c == '\r') obj.append("\\r");
        else if (c == '\t') obj.append("\\t");
        else                obj.append(c);
        continue;
      }

      // Not in a string
      if (c == '"')
      {
        obj.append(c);
        inString = true;
        continue;
      }
      if (c == '{') depth++;
      obj.append(c);
      if (c == '}')
      {
        depth--;
        if (depth == 0) return parseObject(obj.toString());
      }
    }

    return null;
  }

  private static Map<String, Object> parseObject(String json)
  {
    try
    {
      @SuppressWarnings("unchecked")
      Map<String, Object> obj =
        (Map<String, Object>) JSONValue.parse(json);
      return obj;
    }
    catch (Exception e)
    {
      System.err.println("Warning: Failed to parse JSON: " +
                         e.getMessage());
      return null;
    }
  }

  /**
     Parse one record's output_dat table and append its per-Day
     rows.  Each row is:
     [row_id(long), params_id(long), seed(long), Day(int), 17 floats...].
  */
  private static void
  explode(Map<String, Object> record, List<Object[]> rows)
  {
    long rowId = asLong(record.get("task_id"));
    long paramsId = asLong(record.get("params_id"));
    long seed = asLong(record.get("seed"));
    String outputDat = (String) record.get("output_dat");
    if (outputDat == null) return;

    String[] lines = outputDat.split("\n");
    if (lines.length == 0) return;

    // Header: whitespace-separated column names, renamed / -> _
    String[] header = lines[0].trim().split("\\s+");
    Map<String, Integer> colIndex = new HashMap<>();
    for (int i = 0; i < header.length; i++)
    {
      colIndex.put(header[i].replace('/', '_'), i);
    }

    int dayIdx = colIndex.getOrDefault("Day", 0);

    for (int li = 1; li < lines.length; li++)
    {
      String dataLine = lines[li].trim();
      if (dataLine.isEmpty()) continue;
      String[] tok = dataLine.split("\\s+");
      // skip malformed rows
      if (tok.length < header.length) continue;

      Object[] row = new Object[4 + dataColumns.length];
      row[0] = rowId;
      row[1] = paramsId;
      row[2] = seed;
      row[3] = Integer.parseInt(tok[dayIdx]);
      for (int c = 0; c < dataColumns.length; c++)
      {
        Integer idx = colIndex.get(dataColumns[c]);
        row[4 + c] =
          (idx != null) ? Float.parseFloat(tok[idx]) : 0.0f;
      }
      rows.add(row);
    }
  }

  private static List<String> columnNames()
  {
    List<String> names = new ArrayList<>();
    names.add("row_id");
    names.add("params_id");
    names.add("seed");
    names.add("Day");
    names.addAll(Arrays.asList(dataColumns));
    return names;
  }

  private static MessageType buildSchema()
  {
    Types.MessageTypeBuilder b = Types.buildMessage();
    b.required(PrimitiveTypeName.INT64).named("row_id");
    b.required(PrimitiveTypeName.INT64).named("params_id");
    b.required(PrimitiveTypeName.INT64).named("seed");
    b.required(PrimitiveTypeName.INT32).named("Day");
    for (String col : dataColumns)
    {
      b.required(PrimitiveTypeName.FLOAT).named(col);
    }
    return b.named("schema");
  }

  private static long asLong(Object v)
  {
    if (v == null) return 0L;
    return ((Number) v).longValue();
  }

  /**
     Report the header block that is going into the Parquet footer.
  */
  private static void printMetadata(Map<String, String> metadata)
  {
    System.out.println("\nFile metadata (from header block):");
    int width = 0;
    for (String key : metadata.keySet())
    {
      width = Math.max(width, key.length());
    }
    for (Map.Entry<String, String> entry : metadata.entrySet())
    {
      System.out.printf("  %-" + width + "s  %s\n",
                        entry.getKey(), entry.getValue());
    }
    System.out.println();
  }
}


/*
  Local Variables:
  c-basic-offset: 2
  End:
*/
