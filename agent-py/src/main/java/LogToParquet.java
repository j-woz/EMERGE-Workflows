import org.json.simple.JSONValue;

import blue.strategic.parquet.ParquetWriter;
import blue.strategic.parquet.Dehydrator;

import org.apache.parquet.schema.MessageType;
import org.apache.parquet.schema.Types;
import org.apache.parquet.schema.PrimitiveType.PrimitiveTypeName;

import java.io.*;
import java.util.*;

/**
   Convert an EMERGE results JSON-lines log into a Parquet file
   matching the reference "long" format (see part-000000.parquet):

   - each record's output_dat text table is exploded into one row
     per Day
   - columns: row_id (=task_id), seed, Day, then a fixed subset of
     the simulation columns (renamed  /  to  _ )
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

    List<Map<String, Object>> records = readJsonLines(inputPath);
    if (records.isEmpty())
    {
      System.err.println("No records found in input file");
      System.exit(1);
    }
    System.out.println("Loaded " + records.size() +
                       " records from " + inputPath);

    // Explode every record's output_dat into flat per-Day rows.
    List<Object[]> rows = new ArrayList<>();
    for (Map<String, Object> record : records)
    {
      explode(record, rows);
    }
    System.out.println("Exploded to " + rows.size() + " rows");

    MessageType schema = buildSchema();
    System.out.println("Schema:\n" + schema);

    writeToParquet(rows, schema, outputPath);
    System.out.println("Written " + rows.size() + " rows to " +
                       outputPath);
  }

  private static List<Map<String, Object>>
  readJsonLines(String filePath)
  throws IOException
  {
    List<Map<String, Object>> records = new ArrayList<>();
    try (BufferedReader reader =
         new BufferedReader(new FileReader(filePath)))
    {
      String line;
      while ((line = reader.readLine()) != null)
      {
        line = line.trim();
        if (line.isEmpty()) continue;
        try
        {
          @SuppressWarnings("unchecked")
          Map<String, Object> obj =
            (Map<String, Object>) JSONValue.parse(line);
          if (obj != null) records.add(obj);
        }
        catch (Exception e)
        {
          System.err.println("Warning: Failed to parse JSON: " +
                             e.getMessage());
        }
      }
    }
    return records;
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

  private static void
  writeToParquet(List<Object[]> rows, MessageType schema,
                 String outputPath)
  throws IOException
  {
    File out = new File(outputPath);

    List<String> names = new ArrayList<>();
    names.add("row_id");
    names.add("seed");
    names.add("Day");
    names.addAll(Arrays.asList(DATA_COLUMNS));

    Dehydrator<Object[]> dehydrator = (row, valueWriter) ->
    {
      for (int i = 0; i < names.size(); i++)
      {
        valueWriter.write(names.get(i), row[i]);
      }
    };

    try (ParquetWriter<Object[]> writer =
         ParquetWriter.writeFile(schema, out, dehydrator))
    {
      for (Object[] row : rows)
      {
        writer.write(row);
      }
    }
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
