

from libc.time cimport time_t
from libc.stdint cimport int32_t
from libc.stdint cimport int16_t
from libc.stdint cimport int8_t
from libc.stdint cimport uint8_t

cdef extern from "<sys/types.h>":
    ctypedef long off_t


cdef extern from "libs/ReadStat/src/readstat.h":

    cdef enum readstat_handler_status_t:
        READSTAT_HANDLER_OK
        READSTAT_HANDLER_ABORT
        READSTAT_HANDLER_SKIP_VARIABLE

    cpdef enum readstat_type_t "readstat_type_e":
        READSTAT_TYPE_STRING
        READSTAT_TYPE_INT8
        READSTAT_TYPE_INT16
        READSTAT_TYPE_INT32
        READSTAT_TYPE_FLOAT
        READSTAT_TYPE_DOUBLE
        READSTAT_TYPE_STRING_REF

    cpdef enum readstat_type_class_t "readstat_type_class_e":
        READSTAT_TYPE_CLASS_STRING
        READSTAT_TYPE_CLASS_NUMERIC

    cpdef enum readstat_measure_t "readstat_measure_e":
        READSTAT_MEASURE_UNKNOWN
        READSTAT_MEASURE_NOMINAL
        READSTAT_MEASURE_ORDINAL
        READSTAT_MEASURE_SCALE

    cpdef enum readstat_alignment_t "readstat_alignment_e":
        READSTAT_ALIGNMENT_UNKNOWN,
        READSTAT_ALIGNMENT_LEFT,
        READSTAT_ALIGNMENT_CENTER,
        READSTAT_ALIGNMENT_RIGHT

    cpdef enum readstat_compress_t "readstat_compress_e":
        READSTAT_COMPRESS_NONE
        READSTAT_COMPRESS_ROWS
        READSTAT_COMPRESS_BINARY

    cpdef enum readstat_endian_t "readstat_endian_e":
        READSTAT_ENDIAN_NONE
        READSTAT_ENDIAN_LITTLE
        READSTAT_ENDIAN_BIG

    cpdef enum readstat_error_t "readstat_error_e":
        READSTAT_OK
        READSTAT_ERROR_OPEN = 1
        READSTAT_ERROR_READ
        READSTAT_ERROR_MALLOC
        READSTAT_ERROR_USER_ABORT
        READSTAT_ERROR_PARSE
        READSTAT_ERROR_UNSUPPORTED_COMPRESSION
        READSTAT_ERROR_UNSUPPORTED_CHARSET
        READSTAT_ERROR_COLUMN_COUNT_MISMATCH
        READSTAT_ERROR_ROW_COUNT_MISMATCH
        READSTAT_ERROR_ROW_WIDTH_MISMATCH
        READSTAT_ERROR_BAD_FORMAT_STRING
        READSTAT_ERROR_VALUE_TYPE_MISMATCH
        READSTAT_ERROR_WRITE
        READSTAT_ERROR_WRITER_NOT_INITIALIZED
        READSTAT_ERROR_SEEK
        READSTAT_ERROR_CONVERT
        READSTAT_ERROR_CONVERT_BAD_STRING
        READSTAT_ERROR_CONVERT_SHORT_STRING
        READSTAT_ERROR_CONVERT_LONG_STRING
        READSTAT_ERROR_NUMERIC_VALUE_IS_OUT_OF_RANGE
        READSTAT_ERROR_TAGGED_VALUE_IS_OUT_OF_RANGE
        READSTAT_ERROR_STRING_VALUE_IS_TOO_LONG
        READSTAT_ERROR_TAGGED_VALUES_NOT_SUPPORTED
        READSTAT_ERROR_UNSUPPORTED_FILE_FORMAT_VERSION
        READSTAT_ERROR_NAME_BEGINS_WITH_ILLEGAL_CHARACTER
        READSTAT_ERROR_NAME_CONTAINS_ILLEGAL_CHARACTER
        READSTAT_ERROR_NAME_IS_RESERVED_WORD
        READSTAT_ERROR_NAME_IS_TOO_LONG
        READSTAT_ERROR_BAD_TIMESTAMP
        READSTAT_ERROR_BAD_FREQUENCY_WEIGHT
        READSTAT_ERROR_TOO_MANY_MISSING_VALUE_DEFINITIONS
        READSTAT_ERROR_NOTE_IS_TOO_LONG
        READSTAT_ERROR_STRING_REFS_NOT_SUPPORTED
        READSTAT_ERROR_STRING_REF_IS_REQUIRED
        READSTAT_ERROR_ROW_IS_TOO_WIDE_FOR_PAGE
        READSTAT_ERROR_TOO_FEW_COLUMNS
        READSTAT_ERROR_TOO_MANY_COLUMNS


    const char *readstat_error_message(readstat_error_t error_code);

    cdef struct readstat_metadata_t "readstat_metadata_s":
        pass

    int readstat_get_row_count(readstat_metadata_t *metadata);
    int readstat_get_var_count(readstat_metadata_t *metadata);
    time_t readstat_get_creation_time(readstat_metadata_t *metadata);
    time_t readstat_get_modified_time(readstat_metadata_t *metadata);
    int readstat_get_file_format_version(readstat_metadata_t *metadata);
    int readstat_get_file_format_is_64bit(readstat_metadata_t *metadata);
    readstat_compress_t readstat_get_compression(readstat_metadata_t *metadata);
    readstat_endian_t readstat_get_endianness(readstat_metadata_t *metadata);
    const char *readstat_get_table_name(readstat_metadata_t *metadata);
    const char *readstat_get_file_label(readstat_metadata_t *metadata);
    const char *readstat_get_file_encoding(readstat_metadata_t *metadata);

    cdef struct readstat_value_t "readstat_value_s":
        pass

    # Internal data structures

    cdef struct readstat_value_label_t "readstat_value_label_s":
        pass

    cdef struct readstat_label_set_t "readstat_label_set_s":
        pass

    cdef struct readstat_missingness_t "readstat_missingness_s":
        pass

    cdef struct readstat_variable_t "readstat_variable_s":
        pass

    # Value accessors

    readstat_type_t readstat_value_type(readstat_value_t value);
    readstat_type_class_t readstat_value_type_class(readstat_value_t value);

    int readstat_value_is_missing(readstat_value_t value, readstat_variable_t *variable);
    int readstat_value_is_system_missing(readstat_value_t value);
    int readstat_value_is_tagged_missing(readstat_value_t value);
    int readstat_value_is_defined_missing(readstat_value_t value, readstat_variable_t *variable);
    char readstat_value_tag(readstat_value_t value);

    char readstat_int8_value(readstat_value_t value);
    int16_t readstat_int16_value(readstat_value_t value);
    int32_t readstat_int32_value(readstat_value_t value);
    float readstat_float_value(readstat_value_t value);
    double readstat_double_value(readstat_value_t value);
    const char *readstat_string_value(readstat_value_t value);

    readstat_type_class_t readstat_type_class(readstat_type_t type);


    # Accessor methods for use inside variable handlers

    int readstat_variable_get_index(const readstat_variable_t *variable);
    int readstat_variable_get_index_after_skipping(const readstat_variable_t *variable);
    const char *readstat_variable_get_name(const readstat_variable_t *variable);
    const char *readstat_variable_get_label(const readstat_variable_t *variable);
    const char *readstat_variable_get_format(const readstat_variable_t *variable);
    readstat_type_t readstat_variable_get_type(const readstat_variable_t *variable);
    readstat_type_class_t readstat_variable_get_type_class(const readstat_variable_t *variable);
    size_t readstat_variable_get_storage_width(const readstat_variable_t *variable);
    int readstat_variable_get_display_width(const readstat_variable_t *variable);
    readstat_measure_t readstat_variable_get_measure(const readstat_variable_t *variable);
    readstat_alignment_t readstat_variable_get_alignment(const readstat_variable_t *variable);

    int readstat_variable_get_missing_ranges_count(const readstat_variable_t *variable);
    readstat_value_t readstat_variable_get_missing_range_lo(const readstat_variable_t *variable, int i);
    readstat_value_t readstat_variable_get_missing_range_hi(const readstat_variable_t *variable, int i);



    ctypedef int (*readstat_metadata_handler)(readstat_metadata_t *metadata, void *ctx);
    ctypedef int (*readstat_note_handler)(int note_index, const char *note, void *ctx);
    ctypedef int (*readstat_variable_handler)(int index, readstat_variable_t *variable,
            const char *val_labels, void *ctx);
    ctypedef int (*readstat_fweight_handler)(readstat_variable_t *variable, void *ctx);
    ctypedef int (*readstat_value_handler)(int obs_index, readstat_variable_t *variable,
            readstat_value_t value, void *ctx);
    ctypedef int (*readstat_value_label_handler)(const char *val_labels,
            readstat_value_t value, const char *label, void *ctx);
    ctypedef void (*readstat_error_handler)(const char *error_message, void *ctx);
    ctypedef int (*readstat_progress_handler)(double progress, void *ctx);


#if defined _WIN32 || defined __CYGWIN__
#   ctypedef _off64_t readstat_off_t;
#else
    ctypedef off_t readstat_off_t;
#endif

    cdef enum readstat_io_flags_t "readstat_io_flags_e":
        READSTAT_SEEK_SET
        READSTAT_SEEK_CUR
        READSTAT_SEEK_END

    ctypedef int (*readstat_open_handler)(const char *path, void *io_ctx);
    ctypedef int (*readstat_close_handler)(void *io_ctx);
    ctypedef readstat_off_t (*readstat_seek_handler)(readstat_off_t offset, readstat_io_flags_t whence, void *io_ctx);
    ctypedef ssize_t (*readstat_read_handler)(void *buf, size_t nbyte, void *io_ctx);
    ctypedef readstat_error_t (*readstat_update_handler)(long file_size, readstat_progress_handler progress_handler, void *user_ctx, void *io_ctx);

    cdef struct readstat_io_t "readstat_io_s":
        pass

    cdef struct readstat_callbacks_t "readstat_callbacks_s":
        pass

    cdef struct readstat_parser_t "readstat_parser_s":
        pass

    readstat_parser_t *readstat_parser_init();
    void readstat_parser_free(readstat_parser_t *parser);
    void readstat_io_free(readstat_io_t *io);

    readstat_error_t readstat_set_metadata_handler(readstat_parser_t *parser, readstat_metadata_handler metadata_handler);
    readstat_error_t readstat_set_note_handler(readstat_parser_t *parser, readstat_note_handler note_handler);
    readstat_error_t readstat_set_variable_handler(readstat_parser_t *parser, readstat_variable_handler variable_handler);
    readstat_error_t readstat_set_fweight_handler(readstat_parser_t *parser, readstat_fweight_handler fweight_handler);
    readstat_error_t readstat_set_value_handler(readstat_parser_t *parser, readstat_value_handler value_handler);
    readstat_error_t readstat_set_value_label_handler(readstat_parser_t *parser, readstat_value_label_handler value_label_handler);
    readstat_error_t readstat_set_error_handler(readstat_parser_t *parser, readstat_error_handler error_handler);
    readstat_error_t readstat_set_progress_handler(readstat_parser_t *parser, readstat_progress_handler progress_handler);


    readstat_error_t readstat_set_open_handler(readstat_parser_t *parser, readstat_open_handler open_handler);
    readstat_error_t readstat_set_close_handler(readstat_parser_t *parser, readstat_close_handler close_handler);
    readstat_error_t readstat_set_seek_handler(readstat_parser_t *parser, readstat_seek_handler seek_handler);
    readstat_error_t readstat_set_read_handler(readstat_parser_t *parser, readstat_read_handler read_handler);
    readstat_error_t readstat_set_update_handler(readstat_parser_t *parser, readstat_update_handler update_handler);
    readstat_error_t readstat_set_io_ctx(readstat_parser_t *parser, void *io_ctx);

    # Usually inferred from the file, but sometimes a manual override is desirable.
    # In particular, pre-14 Stata uses the system encoding, which is usually Win 1252
    # but could be anything. `encoding' should be an iconv-compatible name.
    readstat_error_t readstat_set_file_character_encoding(readstat_parser_t *parser, const char *encoding);

    # Defaults to UTF-8. Pass in NULL to disable transliteration.
    readstat_error_t readstat_set_handler_character_encoding(readstat_parser_t *parser, const char *encoding);

    readstat_error_t readstat_set_row_limit(readstat_parser_t *parser, long row_limit);

    readstat_error_t readstat_parse_dta(readstat_parser_t *parser, const char *path, void *user_ctx);
    readstat_error_t readstat_parse_sav(readstat_parser_t *parser, const char *path, void *user_ctx);
    readstat_error_t readstat_parse_por(readstat_parser_t *parser, const char *path, void *user_ctx);
    readstat_error_t readstat_parse_sas7bdat(readstat_parser_t *parser, const char *path, void *user_ctx);
    readstat_error_t readstat_parse_sas7bcat(readstat_parser_t *parser, const char *path, void *user_ctx);
    readstat_error_t readstat_parse_xport(readstat_parser_t *parser, const char *path, void *user_ctx);


    cdef struct readstat_string_ref_t "readstat_string_ref_s":
        pass

    ctypedef size_t (*readstat_variable_width_callback)(readstat_type_t type, size_t user_width);
    ctypedef readstat_error_t (*readstat_variable_ok_callback)(readstat_variable_t *variable);

    ctypedef readstat_error_t (*readstat_write_int8_callback)(void *row_data, const readstat_variable_t *variable, int8_t value);
    ctypedef readstat_error_t (*readstat_write_int16_callback)(void *row_data, const readstat_variable_t *variable, int16_t value);
    ctypedef readstat_error_t (*readstat_write_int32_callback)(void *row_data, const readstat_variable_t *variable, int32_t value);
    ctypedef readstat_error_t (*readstat_write_float_callback)(void *row_data, const readstat_variable_t *variable, float value);
    ctypedef readstat_error_t (*readstat_write_double_callback)(void *row_data, const readstat_variable_t *variable, double value);
    ctypedef readstat_error_t (*readstat_write_string_callback)(void *row_data, const readstat_variable_t *variable, const char *value);
    ctypedef readstat_error_t (*readstat_write_string_ref_callback)(void *row_data, const readstat_variable_t *variable, readstat_string_ref_t *ref);
    ctypedef readstat_error_t (*readstat_write_missing_callback)(void *row_data, const readstat_variable_t *variable);
    ctypedef readstat_error_t (*readstat_write_tagged_callback)(void *row_data, const readstat_variable_t *variable, char tag);

    ctypedef readstat_error_t (*readstat_begin_data_callback)(void *writer);
    ctypedef readstat_error_t (*readstat_write_row_callback)(void *writer, void *row_data, size_t row_len);
    ctypedef readstat_error_t (*readstat_end_data_callback)(void *writer);
    ctypedef void (*readstat_module_ctx_free_callback)(void *module_ctx);

    cdef struct readstat_writer_callbacks_t "readstat_writer_callbacks_s":
        pass

    ctypedef ssize_t (*readstat_data_writer)(const void *data, size_t len, void *ctx);




    cdef struct readstat_value_t "readstat_value_s":
        pass

    cdef struct readstat_parser_t "readstat_parser_s":
        pass

    cdef struct readstat_writer_t "readstat_writer_s":
        pass

    # First call this...
    readstat_writer_t *readstat_writer_init();

    # Then specify a function that will handle the output bytes...
    readstat_error_t readstat_set_data_writer(readstat_writer_t *writer, readstat_data_writer data_writer);

    # Next define your value labels, if any. Create as many named sets as you'd like.
    readstat_label_set_t *readstat_add_label_set(readstat_writer_t *writer, readstat_type_t type, const char *name);
    void readstat_label_double_value(readstat_label_set_t *label_set, double value, const char *label);
    void readstat_label_int32_value(readstat_label_set_t *label_set, int32_t value, const char *label);
    void readstat_label_string_value(readstat_label_set_t *label_set, const char *value, const char *label);
    void readstat_label_tagged_value(readstat_label_set_t *label_set, char tag, const char *label);

    # Now define your variables. Note that `storage_width' is used for:
    # * READSTAT_TYPE_STRING variables in all formats
    # * READSTAT_TYPE_DOUBLE variables, but only in the SAS XPORT format (valid values 3-8, defaults to 8)
    readstat_variable_t *readstat_add_variable(readstat_writer_t *writer, const char *name, readstat_type_t type,
            size_t storage_width);
    void readstat_variable_set_label(readstat_variable_t *variable, const char *label);
    void readstat_variable_set_format(readstat_variable_t *variable, const char *format);
    void readstat_variable_set_label_set(readstat_variable_t *variable, readstat_label_set_t *label_set);
    void readstat_variable_set_measure(readstat_variable_t *variable, readstat_measure_t measure);
    void readstat_variable_set_alignment(readstat_variable_t *variable, readstat_alignment_t alignment);
    void readstat_variable_set_display_width(readstat_variable_t *variable, int display_width);
    void readstat_variable_add_missing_double_value(readstat_variable_t *variable, double value);
    void readstat_variable_add_missing_double_range(readstat_variable_t *variable, double lo, double hi);
    readstat_variable_t *readstat_get_variable(readstat_writer_t *writer, int index);

    # "Notes" appear in the file metadata. In SPSS these are stored as
    # lines in the Document Record; in Stata these are stored using
    # the "notes" feature.
    #
    # Note that the line length in SPSS is 80 characters; ReadStat will
    # produce a write error if a note is longer than this limit.
    void readstat_add_note(readstat_writer_t *writer, const char *note);

    # String refs are used for creating a READSTAT_TYPE_STRING_REF column,
    # which is only supported in Stata. String references can be shared
    # across columns, and inserted with readstat_insert_string_ref().
    readstat_string_ref_t *readstat_add_string_ref(readstat_writer_t *writer, const char *string);
    readstat_string_ref_t *readstat_get_string_ref(readstat_writer_t *writer, int index);

    # Optional metadata
    readstat_error_t readstat_writer_set_file_label(readstat_writer_t *writer, const char *file_label);
    readstat_error_t readstat_writer_set_file_timestamp(readstat_writer_t *writer, time_t timestamp);
    readstat_error_t readstat_writer_set_fweight_variable(readstat_writer_t *writer, const readstat_variable_t *variable);

    readstat_error_t readstat_writer_set_file_format_version(readstat_writer_t *writer,
            uint8_t file_format_version);
    # e.g. 104-119 for DTA; 5 or 8 for SAS Transport.
    # SAV files support 2 or 3, where 3 is equivalent to setting
    # readstat_writer_set_compression(READSTAT_COMPRESS_BINARY)

    readstat_error_t readstat_writer_set_table_name(readstat_writer_t *writer, const char *table_name);
    # Only used in XPORT files at the moment (defaults to DATASET)

    readstat_error_t readstat_writer_set_file_format_is_64bit(readstat_writer_t *writer,
            int is_64bit); # applies only to SAS files; defaults to 1=true
    readstat_error_t readstat_writer_set_compression(readstat_writer_t *writer,
            readstat_compress_t compression);
            # READSTAT_COMPRESS_BINARY is supported only with SAV files (i.e. ZSAV files)
            # READSTAT_COMPRESS_ROWS is supported only with sas7bdat and SAV files

    # Optional error handler
    readstat_error_t readstat_writer_set_error_handler(readstat_writer_t *writer,
            readstat_error_handler error_handler);

    # Call one of these at any time before the first invocation of readstat_begin_row
    readstat_error_t readstat_begin_writing_dta(readstat_writer_t *writer, void *user_ctx, long row_count);
    readstat_error_t readstat_begin_writing_por(readstat_writer_t *writer, void *user_ctx, long row_count);
    readstat_error_t readstat_begin_writing_sas7bcat(readstat_writer_t *writer, void *user_ctx);
    readstat_error_t readstat_begin_writing_sas7bdat(readstat_writer_t *writer, void *user_ctx, long row_count);
    readstat_error_t readstat_begin_writing_sav(readstat_writer_t *writer, void *user_ctx, long row_count);
    readstat_error_t readstat_begin_writing_xport(readstat_writer_t *writer, void *user_ctx, long row_count);

    # Start a row of data (that is, a case or observation)
    readstat_error_t readstat_begin_row(readstat_writer_t *writer);

    # Then call one of these for each variable
    readstat_error_t readstat_insert_int8_value(readstat_writer_t *writer, const readstat_variable_t *variable, int8_t value);
    readstat_error_t readstat_insert_int16_value(readstat_writer_t *writer, const readstat_variable_t *variable, int16_t value);
    readstat_error_t readstat_insert_int32_value(readstat_writer_t *writer, const readstat_variable_t *variable, int32_t value);
    readstat_error_t readstat_insert_float_value(readstat_writer_t *writer, const readstat_variable_t *variable, float value);
    readstat_error_t readstat_insert_double_value(readstat_writer_t *writer, const readstat_variable_t *variable, double value);
    readstat_error_t readstat_insert_string_value(readstat_writer_t *writer, const readstat_variable_t *variable, const char *value);
    readstat_error_t readstat_insert_string_ref(readstat_writer_t *writer, const readstat_variable_t *variable, readstat_string_ref_t *ref);
    readstat_error_t readstat_insert_missing_value(readstat_writer_t *writer, const readstat_variable_t *variable);
    readstat_error_t readstat_insert_tagged_missing_value(readstat_writer_t *writer, const readstat_variable_t *variable, char tag);

    # Finally, close out the row
    readstat_error_t readstat_end_row(readstat_writer_t *writer);

    # Once you've written all the rows, clean up after yourself
    readstat_error_t readstat_end_writing(readstat_writer_t *writer);
    void readstat_writer_free(readstat_writer_t *writer);
