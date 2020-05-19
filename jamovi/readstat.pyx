# cython: c_string_type=str, c_string_encoding=utf8, language_level=3

import math
from numbers import Number
from enum import Enum
from datetime import date
from datetime import timedelta
import os.path
from cython.operator cimport dereference as deref


class Measure(Enum):
    UNKNOWN = 0
    NOMINAL = 1
    ORDINAL = 2
    SCALE   = 3


class Error(OSError):
    pass


GREG_START = date(1582, 10, 14)


cdef int _os_open(path, mode):
    cdef int flags
    IF UNAME_SYSNAME == 'Windows':
        cdef Py_ssize_t length
        u16_path = PyUnicode_AsWideCharString(path, &length)
        if mode == 'r':
            flags = _O_RDONLY | _O_BINARY
        else:
            flags = _O_WRONLY | _O_CREAT | _O_BINARY
        return _wsopen(u16_path, flags, _SH_DENYRD, _S_IREAD | _S_IWRITE)
    ELSE:
        if mode == 'r':
            flags = O_RDONLY
        else:
            flags = O_WRONLY | O_CREAT | O_TRUNC
        return open(path.encode('utf-8'), flags, 0644)


cdef int _os_close(int fd):
    IF UNAME_SYSNAME == 'Windows':
        return _close(fd)
    ELSE:
        return close(fd)


cdef int _handle_open(const char* path, void* io_ctx):
    cdef unistd_io_ctx_t* ctx = <unistd_io_ctx_t*>io_ctx
    cdef int fd
    if not os.path.isfile(path):
        return -1
    fd = _os_open(path, 'r')
    ctx.fd = fd
    return fd


cdef int _handle_metadata(readstat_metadata_t *metadata, void *ctx):
    parser = <object>ctx
    parser._is_date = [False] * readstat_get_var_count(metadata)
    try:
        Parser.__handle_metadata(parser, metadata)
        return readstat_handler_status_t.READSTAT_HANDLER_OK
    except Exception as e:
        parser._error = e
        return readstat_handler_status_t.READSTAT_HANDLER_ABORT


cdef int _handle_value_label(const char *val_labels, readstat_value_t value, const char *label, void *ctx):
    parser = <object>ctx
    try:
        Parser.__handle_value_label(parser, val_labels, value, label)
        return readstat_handler_status_t.READSTAT_HANDLER_OK
    except Exception as e:
        parser._error = e
        return readstat_handler_status_t.READSTAT_HANDLER_ABORT


cdef int _handle_variable(int index, readstat_variable_t *variable, const char *val_labels, void *ctx):
    cdef const char *fmt;
    parser = <object>ctx
    try:
        fmt = readstat_variable_get_format(variable)
        format = fmt if fmt is not NULL else ''
        if format[0:4] == 'DATE' or format[1:5] == 'DATE':
            parser._is_date[index] = True
        Parser.__handle_variable(parser, index, variable, val_labels)
        return readstat_handler_status_t.READSTAT_HANDLER_OK
    except Exception as e:
        parser._error = e
        return readstat_handler_status_t.READSTAT_HANDLER_ABORT


cdef int _handle_value(int obs_index, readstat_variable_t *variable, readstat_value_t value, void *ctx):
    parser = <object>ctx
    try:
        Parser.__handle_value(parser, obs_index, variable, value)
        return readstat_handler_status_t.READSTAT_HANDLER_OK
    except Exception as e:
        parser._error = e
        return readstat_handler_status_t.READSTAT_HANDLER_ABORT


cdef _resolve_value(readstat_value_t value, is_date=False):
    cdef readstat_type_t t

    if readstat_value_is_system_missing(value):
        return None

    t = readstat_value_type(value)

    if t == READSTAT_TYPE_STRING:
        v = readstat_string_value(value)
        if v == '':
            v = None
    elif t == READSTAT_TYPE_INT8:
        v = readstat_int8_value(value)
    elif t == READSTAT_TYPE_INT16:
        v = readstat_int16_value(value)
    elif t == READSTAT_TYPE_INT32:
        v = readstat_int32_value(value)
    elif t == READSTAT_TYPE_FLOAT:
        v = readstat_float_value(value)
    elif t == READSTAT_TYPE_DOUBLE:
        v = readstat_double_value(value)
    else:
        v = None

    if v is not None and is_date:
        try:
            days = v / 24 / 60 / 60
            delta = timedelta(days=days)
            v = GREG_START + delta
        except OverflowError:
            v = None

    return v


cdef class Parser:

    cdef readstat_parser_t *_this
    cdef int _fd
    cdef int _row_count
    cdef int _var_count

    cpdef parse(self, path, format='sav'):

        cdef readstat_error_t status

        self._this = readstat_parser_init();
        self._fd = 0
        self._var_count = -1
        self._row_count = -1
        self._is_date = None
        self._error = None

        IF UNAME_SYSNAME == 'Windows':  # custom file opener for windows *sigh*
            readstat_set_open_handler(self._this, _handle_open)

        readstat_set_metadata_handler(self._this, _handle_metadata)
        readstat_set_value_label_handler(self._this, _handle_value_label)
        readstat_set_variable_handler(self._this, _handle_variable)
        readstat_set_value_handler(self._this, _handle_value)

        path_enced = path.encode('utf-8')

        if format == 'sav':
            status = readstat_parse_sav(self._this, path_enced, <void*>self)
        elif format == 'dta':
            status = readstat_parse_dta(self._this, path_enced, <void*>self)
        elif format == 'por':
            status = readstat_parse_por(self._this, path_enced, <void*>self)
        elif format == 'sas7bdat':
            status = readstat_parse_sas7bdat(self._this, path_enced, <void*>self)
        elif format == 'sas7bcat':
            status = readstat_parse_sas7bcat(self._this, path_enced, <void*>self)
        elif format == 'xpt':
            status = readstat_parse_xport(self._this, path_enced, <void*>self)
        else:
            raise ValueError('Unrecognised format {}'.format(format))

        readstat_parser_free(self._this)

        if status != READSTAT_OK:
            if self._error is not None:
                raise self._error
            else:
                message = readstat_error_message(status)
                error = Error(status, message)
                raise error


    def handle_metadata(self, metadata):
        pass

    def handle_value_label(self, labels_key, value, label):
        pass

    def handle_variable(self, index, variable, labels_key):
        pass

    def finalize_variables(self):
        pass

    def handle_value(self):
        pass

    def finalize_variables(self):
        pass

    def finalize_values(self):
        pass

    cdef __handle_metadata(self, readstat_metadata_t *metadata):
        self._row_count = readstat_get_row_count(metadata)
        self._var_count = readstat_get_var_count(metadata)
        md = MetaData()
        md._self = deref(metadata)
        self.handle_metadata(md)

    cdef __handle_value_label(self, const char *val_labels, readstat_value_t value, const char *label):
        if val_labels != NULL:
            labels_key = val_labels
        else:
            labels_key = None
        raw_value  = _resolve_value(value)
        label_str  = label
        self.handle_value_label(labels_key, raw_value, label_str)

    cdef __handle_variable(self, int index, readstat_variable_t *variable, const char *val_labels):
        var = Variable()
        var._self = deref(variable)
        if val_labels != NULL:
            labels_key = val_labels
        else:
            labels_key = None
        self.handle_variable(index, var, labels_key)
        if index == self._var_count - 1:
            self.finalize_variables()

    cdef __handle_value(self, int obs_index, readstat_variable_t *variable, readstat_value_t value):
        var_index = readstat_variable_get_index(variable)
        is_date = self._is_date[var_index]
        v = _resolve_value(value, is_date)
        self.handle_value(var_index, obs_index, v)
        if var_index == self._var_count - 1 and obs_index == self._row_count - 1:
            self.finalize_values()


cdef class MetaData:

    cdef readstat_metadata_t _self
    cdef readstat_metadata_t *_this

    def __init__(self):
        self._this = &self._self

    @property
    def row_count(self):
        return readstat_get_row_count(self._this)

    @property
    def var_count(self):
        return readstat_get_var_count(self._this)

cdef class Variable:

    cdef readstat_variable_t _self
    cdef readstat_variable_t *_this

    def __init__(self):
        self._this = &self._self

    @property
    def index(self):
        return readstat_variable_get_index(self._this)

    @property
    def index_after_skipping(self):
        return readstat_variable_get_index_after_skipping(self._this)

    property name:
        def __get__(self):
            return readstat_variable_get_name(self._this)

    property label:
        def __get__(self):
            cdef const char *label;
            label = readstat_variable_get_label(self._this);
            if label != NULL:
                return label
            else:
                return None

        def __set__(self, label):
            readstat_variable_set_label(self._this, label.encode('utf-8'))

    property format:
        def __get__(self):
            cdef const char* fmt
            fmt = readstat_variable_get_format(self._this)
            format = fmt if fmt is not NULL else ''
            return format

    property type:
        def __get__(self):
            t = readstat_variable_get_type(self._this)
            ret = None
            if t == READSTAT_TYPE_STRING:
                ret = str
            elif t == READSTAT_TYPE_INT8:
                ret = int
            elif t == READSTAT_TYPE_INT16:
                ret = int
            elif t == READSTAT_TYPE_INT32:
                ret = int
            elif t == READSTAT_TYPE_FLOAT:
                ret = float
            elif t == READSTAT_TYPE_DOUBLE:
                ret = float
            else:
                ret == None

            if ret is not None:
                if self.format[0:4] == 'DATE' or self.format[1:5] == 'DATE':
                    ret = date

            return ret

    property type_class:
        def __get__(self):
            tc = readstat_variable_get_type_class(self._this)
            if tc == readstat_type_class_t.READSTAT_TYPE_CLASS_STRING:
                return str
            else:
                return Number

    property storage_width:
        def __get__(self):
            return readstat_variable_get_storage_width(self._this)

    property display_width:
        def __get__(self):
            return readstat_variable_get_display_width(self._this)

    property measure:
        def __get__(self):
            cdef readstat_measure_t t
            t = readstat_variable_get_measure(self._this)
            if t == READSTAT_MEASURE_NOMINAL:
                return Measure.NOMINAL
            elif t == READSTAT_MEASURE_ORDINAL:
                return Measure.ORDINAL
            elif t == READSTAT_MEASURE_SCALE:
                return Measure.SCALE
            else:
                return Measure.UNKNOWN

        def __set__(self, value):
            cdef readstat_measure_t t
            if value is Measure.NOMINAL:
                t = READSTAT_MEASURE_NOMINAL
            elif value is Measure.ORDINAL:
                t = READSTAT_MEASURE_ORDINAL
            elif value is Measure.SCALE:
                t = READSTAT_MEASURE_SCALE
            else:
                t = READSTAT_MEASURE_UNKNOWN
            readstat_variable_set_measure(self._this, t)

    property alignment:
        def __get__(self):
            return readstat_variable_get_alignment(self._this)

    def is_missing(self, value):
        if value is None:
            return True
        elif isinstance(value, str):
            return value == ''
        elif isinstance(value, Number):
            for bounds in self.missing_ranges:
                if value >= bounds[0] and value <= bounds[1]:
                    return True
        else:
            return False

    property missing_ranges:
        def __get__(self):
            cdef readstat_value_t lo;
            cdef readstat_value_t hi;

            n = readstat_variable_get_missing_ranges_count(self._this)
            ranges = [None] * n

            for i in range(n):
                lo = readstat_variable_get_missing_range_lo(self._this, i)
                hi = readstat_variable_get_missing_range_hi(self._this, i)
                ranges[i] = (_resolve_value(lo), _resolve_value(hi))

            return ranges


cdef ssize_t _handle_write(const void *data, size_t len, void *ctx):
    cdef int fd = deref(<int*>ctx)
    IF UNAME_SYSNAME == 'Windows':
        return _write(fd, data, len)
    ELSE:
        return write(fd, data, len)


cdef class Writer:

    cdef object _format
    cdef object _row_count
    cdef readstat_writer_t *_writer
    cdef object _variables
    cdef object _current_row
    cdef int _fd

    def __init__(self):
        self._format = None
        self._row_count = 0
        self._writer = NULL
        self._variables = [ ]
        self._current_row = -1
        self._fd = 0

    def open(self, path, format):
        cdef readstat_variable_t *var;

        self._format = format
        self._writer = readstat_writer_init()
        readstat_set_data_writer(self._writer, _handle_write)
        self._fd = _os_open(path, 'w')

    def set_row_count(self, row_count):
        self._row_count = row_count

    def _begin_writing(self):

        if self._format == 'sav':
            begin_func = readstat_begin_writing_sav
        elif self._format == 'dta':
            begin_func = readstat_begin_writing_dta
        elif self._format == 'por':
            begin_func = readstat_begin_writing_por
        elif self._format == 'sas7bdat':
            begin_func = readstat_begin_writing_sas7bdat
        elif self._format == 'xpt':
            begin_func = readstat_begin_writing_xport
        else:
            raise ValueError('Unsupported format')

        begin_func(self._writer, &self._fd, self._row_count)

    def close(self):
        if self._writer != NULL:
            if self._current_row != -1:
                readstat_end_row(self._writer)
            readstat_end_writing(self._writer)
            readstat_writer_free(self._writer)
            _os_close(self._fd)

    def set_file_label(self, label):
        readstat_writer_set_file_label(self._writer, label.encode('utf-8'))

    def insert_value(self, row_no, col_no, value):
        cdef readstat_error_t status;
        cdef readstat_variable_t *variable

        if self._current_row == -1:
            self._begin_writing()

        if row_no != self._current_row:
            if self._current_row != -1:
                readstat_end_row(self._writer)
            readstat_begin_row(self._writer)
            self._current_row = row_no

        variable = readstat_get_variable(self._writer, col_no)

        status = READSTAT_OK
        if isinstance(value, int):
            if value != -2147483648:
                status = readstat_insert_int32_value(self._writer, variable, value)
            else:
                status = readstat_insert_missing_value(self._writer, variable)
        elif isinstance(value, float):
            if not math.isnan(value):
                status = readstat_insert_double_value(self._writer, variable, value)
            else:
                status = readstat_insert_missing_value(self._writer, variable)
        elif isinstance(value, str):
            if value != '':
                status = readstat_insert_string_value(self._writer, variable, value.encode('utf-8'))
            else:
                status = readstat_insert_missing_value(self._writer, variable)

        if status != READSTAT_OK:
            raise ValueError(readstat_error_message(status))


    def add_value_labels(self, Variable var, dtype, labels):
        cdef readstat_label_set_t *label_set
        cdef readstat_type_t t

        if dtype is str:
            t = READSTAT_TYPE_STRING
        else:
            t = READSTAT_TYPE_INT32

        label_set = readstat_add_label_set(
            self._writer, t,
            var.name.encode('utf-8'));

        for level in labels:
            if dtype is str:
                if level[0] == level[1]:
                    continue
                readstat_label_string_value(
                    label_set,
                    level[0].encode('utf-8'),
                    level[1].encode('utf-8'))
            else:
                if str(level[0]) == level[1]:
                    continue
                readstat_label_int32_value(
                    label_set,
                    level[0],
                    level[1].encode('utf-8'))

        readstat_variable_set_label_set(var._this, label_set)


    def add_variable(self, name, dtype, storage_width):
        cdef readstat_variable_t *variable
        cdef readstat_type_t data_type

        if dtype is float:
            data_type = READSTAT_TYPE_DOUBLE
        elif dtype is str:
            data_type = READSTAT_TYPE_STRING
        else:
            data_type = READSTAT_TYPE_INT32

        variable = readstat_add_variable(
            self._writer,
            name.encode('utf-8'),
            data_type,
            storage_width);

        var = Variable()
        var._this = variable
        return var
