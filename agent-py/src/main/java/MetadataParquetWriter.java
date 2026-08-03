import blue.strategic.parquet.Dehydrator;
import blue.strategic.parquet.ValueWriter;

import org.apache.hadoop.conf.Configuration;

import org.apache.parquet.column.ParquetProperties;
import org.apache.parquet.hadoop.ParquetFileWriter;
import org.apache.parquet.hadoop.ParquetWriter;
import org.apache.parquet.hadoop.api.WriteSupport;
import org.apache.parquet.hadoop.metadata.CompressionCodecName;
import org.apache.parquet.io.LocalOutputFile;
import org.apache.parquet.io.OutputFile;
import org.apache.parquet.io.api.Binary;
import org.apache.parquet.io.api.RecordConsumer;
import org.apache.parquet.schema.LogicalTypeAnnotation;
import org.apache.parquet.schema.MessageType;
import org.apache.parquet.schema.PrimitiveType;

import java.io.File;
import java.io.IOException;
import java.util.Map;

/**
   A parquet-floor style writer that also attaches file-level
   key/value metadata to the Parquet footer.

   blue.strategic.parquet.ParquetWriter cannot do this: it keeps the
   underlying parquet-mr builder private, and its WriteSupport hands
   back Collections.emptyMap() as the extra metadata.  So we drive the
   same parquet-mr builder ourselves, with the same settings (Snappy,
   PARQUET_2_0) and the same Dehydrator/ValueWriter callback style,
   but supply a WriteContext carrying the metadata map.  parquet-mr
   merges that map into the footer, alongside the writer.model.name
   entry it adds itself.
*/
public final class MetadataParquetWriter
{
  private MetadataParquetWriter() {}

  /**
     Open a writer whose footer will carry metadata.  An empty map
     just means no extra footer entries.  The caller owns the
     returned writer and must close it.
  */
  public static <T> ParquetWriter<T>
  open(MessageType schema, File file, Dehydrator<T> dehydrator,
       Map<String, String> metadata)
  throws IOException
  {
    OutputFile out = new LocalOutputFile(file.toPath());
    return new Builder<T>(out, schema, dehydrator, metadata)
      .withWriteMode(ParquetFileWriter.Mode.OVERWRITE)
      .withCompressionCodec(CompressionCodecName.SNAPPY)
      .withWriterVersion(ParquetProperties.WriterVersion.PARQUET_2_0)
      .build();
  }

  private static final class Builder<T>
    extends ParquetWriter.Builder<T, Builder<T>>
  {
    private final MessageType schema;
    private final Dehydrator<T> dehydrator;
    private final Map<String, String> metadata;

    Builder(OutputFile file, MessageType schema,
            Dehydrator<T> dehydrator, Map<String, String> metadata)
    {
      super(file);
      this.schema = schema;
      this.dehydrator = dehydrator;
      this.metadata = metadata;
    }

    @Override
    protected Builder<T> self()
    {
      return this;
    }

    @Override
    protected WriteSupport<T> getWriteSupport(Configuration conf)
    {
      return new MetaWriteSupport<T>(schema, dehydrator, metadata);
    }
  }

  /**
     Mirrors parquet-floor's SimpleWriteSupport, which is
     package-private and therefore not reusable, so that records land
     on disk exactly as ParquetWriter.writeFile() would have written
     them.  The one difference is init(), which reports our metadata
     instead of an empty map.
  */
  private static final class MetaWriteSupport<T>
    extends WriteSupport<T>
  {
    private final MessageType schema;
    private final Dehydrator<T> dehydrator;
    private final Map<String, String> metadata;
    private final ValueWriter valueWriter = this::writeField;
    private RecordConsumer recordConsumer;

    MetaWriteSupport(MessageType schema, Dehydrator<T> dehydrator,
                     Map<String, String> metadata)
    {
      this.schema = schema;
      this.dehydrator = dehydrator;
      this.metadata = metadata;
    }

    @Override
    public WriteContext init(Configuration configuration)
    {
      return new WriteContext(schema, metadata);
    }

    @Override
    public void prepareForWrite(RecordConsumer recordConsumer)
    {
      this.recordConsumer = recordConsumer;
    }

    @Override
    public void write(T record)
    {
      recordConsumer.startMessage();
      dehydrator.dehydrate(record, valueWriter);
      recordConsumer.endMessage();
    }

    @Override
    public String getName()
    {
      return "LogToParquet";
    }

    private void writeField(String name, Object value)
    {
      int index = schema.getFieldIndex(name);
      PrimitiveType type = schema.getType(index).asPrimitiveType();

      recordConsumer.startField(name, index);
      switch (type.getPrimitiveTypeName())
      {
        case INT32:
          recordConsumer.addInteger((Integer) value);
          break;
        case INT64:
          recordConsumer.addLong((Long) value);
          break;
        case DOUBLE:
          recordConsumer.addDouble((Double) value);
          break;
        case BOOLEAN:
          recordConsumer.addBoolean((Boolean) value);
          break;
        case FLOAT:
          recordConsumer.addFloat((Float) value);
          break;
        case BINARY:
          LogicalTypeAnnotation annotation =
            type.getLogicalTypeAnnotation();
          if (annotation != LogicalTypeAnnotation.stringType() &&
              annotation != LogicalTypeAnnotation.jsonType())
          {
            throw new UnsupportedOperationException
              ("Unsupported logical type: " + annotation);
          }
          recordConsumer.addBinary(Binary.fromString((String) value));
          break;
        default:
          throw new UnsupportedOperationException
            ("Unsupported type: " + type.getPrimitiveTypeName());
      }
      recordConsumer.endField(name, index);
    }
  }
}


/*
  Local Variables:
  c-basic-offset: 2
  End:
*/
