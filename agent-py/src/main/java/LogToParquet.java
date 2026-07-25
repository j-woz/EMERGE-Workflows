import org.json.simple.JSONValue;

import blue.strategic.parquet.ParquetWriter;
import blue.strategic.parquet.Dehydrator;

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
  // The 17 data columns selected from output_dat, in reference
  // order.  Names here are the RENAMED (/ -> _) forms that appear
  // in the parquet.
  private static final String[] DATA_COLUMNS = {
    "Su", "PS_PI", "S_PI_NH", "S_PI_H", "PS_I", "S_I_NH", "S_I_H",
    "A_PI", "A_I", "H_NI", "H_I", "ICU", "V", "R", "D", "NewS",
    "NewH"
  };

  public static void main(String[] args)
  throws Exception
  {
    if (args.length < 2)
    {
      System.err.println("Usage: java -cp <jar> LogToParquet " +
                         "<input.log> <output.parquet>");
      System.exit(1);
    }

    String inputPath = args[0];
    String outputPath = args[1];

    long blockSize = detectBlockSize(inputPath);
    System.out.println("Block size: " + blockSize/1024 + " KB");

    // Predict block count from the file size: each record occupies
    // exactly one fixed-size block.
    long fileSize = new File(inputPath).length();
    long blocks = (blockSize > 0) ? (fileSize / blockSize) : 0;
    System.out.println("File size: " + fileSize/1024 + " KB");
    System.out.println("Expected blocks: " + blocks);

    MessageType schema = buildSchema();
    System.out.println("Schema:\n" + schema);

    long[] counts = convert(inputPath, outputPath, blockSize,
                            schema);

    System.out.println("Loaded " + counts[0] +
                       " records from " + inputPath);
    System.out.println("Wrote " + counts[1] + " rows to " +
                       outputPath);
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
     rows, and write them.  Returns {recordCount, rowCount}.
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

    try (ParquetWriter<Object[]> writer =
         ParquetWriter.writeFile(schema, out, dehydrator);
         InputStream in =
         new BufferedInputStream(new FileInputStream(inputPath)))
    {
      int n;
      while ((n = readBlock(in, buf)) > 0)
      {
        String block = new String(buf, 0, n,
                                  StandardCharsets.UTF_8);
        Map<String, Object> record = parseBlock(block);
        if (record == null) continue;
        records++;

        List<Object[]> blockRows = new ArrayList<>();
        explode(record, blockRows);
        for (Object[] row : blockRows)
        {
          writer.write(row);
        }
        rows += blockRows.size();
      }
    }

    return new long[] { records, rows };
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
     [row_id(long), seed(long), Day(int), 17 floats...].
  */
  private static void
  explode(Map<String, Object> record, List<Object[]> rows)
  {
    long rowId = asLong(record.get("task_id"));
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

      Object[] row = new Object[3 + DATA_COLUMNS.length];
      row[0] = rowId;
      row[1] = seed;
      row[2] = Integer.parseInt(tok[dayIdx]);
      for (int c = 0; c < DATA_COLUMNS.length; c++)
      {
        Integer idx = colIndex.get(DATA_COLUMNS[c]);
        row[3 + c] =
          (idx != null) ? Float.parseFloat(tok[idx]) : 0.0f;
      }
      rows.add(row);
    }
  }

  private static List<String> columnNames()
  {
    List<String> names = new ArrayList<>();
    names.add("row_id");
    names.add("seed");
    names.add("Day");
    names.addAll(Arrays.asList(DATA_COLUMNS));
    return names;
  }

  private static MessageType buildSchema()
  {
    Types.MessageTypeBuilder b = Types.buildMessage();
    b.required(PrimitiveTypeName.INT64).named("row_id");
    b.required(PrimitiveTypeName.INT64).named("seed");
    b.required(PrimitiveTypeName.INT32).named("Day");
    for (String col : DATA_COLUMNS)
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
}


/*
  Local Variables:
  c-basic-offset: 2
  End:
*/
