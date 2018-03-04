

from cython.operator cimport dereference as deref
from numbers import Number
from enum import Enum


class Measure(Enum):
    UNKNOWN = 0
    NOMINAL = 1
    ORDINAL = 2
    SCALE   = 3


cdef int _handle_metadata(readstat_metadata_t *metadata, void *ctx):
    parser = <object>ctx
    try:
        Parser.__handle_metadata(parser, metadata)
        return readstat_handler_status_t.READSTAT_HANDLER_OK
    except Exception as e:
        print(e)
        return readstat_handler_status_t.READSTAT_HANDLER_ABORT


cdef int _handle_value_label(const char *val_labels, readstat_value_t value, const char *label, void *ctx):
    parser = <object>ctx
    try:
        Parser.__handle_value_label(parser, val_labels, value, label)
        return readstat_handler_status_t.READSTAT_HANDLER_OK
    except Exception as e:
        print(e)
        return readstat_handler_status_t.READSTAT_HANDLER_ABORT


cdef int _handle_variable(int index, readstat_variable_t *variable, const char *val_labels, void *ctx):
    parser = <object>ctx
    try:
        Parser.__handle_variable(parser, index, variable, val_labels)
        return readstat_handler_status_t.READSTAT_HANDLER_OK
    except Exception as e:
        print(e)
        return readstat_handler_status_t.READSTAT_HANDLER_ABORT


cdef int _handle_value(int obs_index, readstat_variable_t *variable, readstat_value_t value, void *ctx):
    parser = <object>ctx
    try:
        Parser.__handle_value(parser, obs_index, variable, value)
        return readstat_handler_status_t.READSTAT_HANDLER_OK
    except Exception as e:
        print(e)
        return readstat_handler_status_t.READSTAT_HANDLER_ABORT


cdef _resolve_value(readstat_value_t value):
    cdef readstat_type_t t

    if readstat_value_is_system_missing(value):
        return None

    t = readstat_value_type(value)

    if t == READSTAT_TYPE_STRING:
        return readstat_string_value(value).decode('utf-8')
    elif t == READSTAT_TYPE_INT8:
        return readstat_int8_value(value)
    elif t == READSTAT_TYPE_INT16:
        return readstat_int16_value(value)
    elif t == READSTAT_TYPE_INT32:
        return readstat_int32_value(value)
    elif t == READSTAT_TYPE_FLOAT:
        return readstat_float_value(value)
    elif t == READSTAT_TYPE_DOUBLE:
        return readstat_double_value(value)
    else:
        return None


cdef class Parser:

    cdef readstat_parser_t *_this
    cdef int _row_count
    cdef int _var_count

    cpdef parse(self, path, format='sav'):

        cdef readstat_error_t status

        self._this = readstat_parser_init();
        self._var_count = -1
        self._row_count = -1
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
        elif format == 'xport':
            status = readstat_parse_xport(self._this, path_enced, <void*>self)
        else:
            raise ValueError('Unrecognised format {}'.format(format))

        readstat_parser_free(self._this)

        if status != READSTAT_OK:
            message = readstat_error_message(status).decode('utf-8')
            raise ValueError(message)


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
        md._this = deref(metadata)
        self.handle_metadata(md)

    cdef __handle_value_label(self, const char *val_labels, readstat_value_t value, const char *label):
        if val_labels != NULL:
            labels_key = val_labels.decode('utf-8')
        else:
            labels_key = None
        raw_value  = _resolve_value(value)
        label_str  = label.decode('utf-8')
        self.handle_value_label(labels_key, raw_value, label_str)

    cdef __handle_variable(self, int index, readstat_variable_t *variable, const char *val_labels):
        var = Variable()
        var._this = deref(variable)
        if val_labels != NULL:
            labels_key = val_labels.decode('utf-8')
        else:
            labels_key = None
        self.handle_variable(index, var, labels_key)
        if index == self._var_count - 1:
            self.finalize_variables()

    cdef __handle_value(self, int obs_index, readstat_variable_t *variable, readstat_value_t value):
        v = _resolve_value(value)
        var_index = readstat_variable_get_index(variable)
        self.handle_value(var_index, obs_index, v)
        if var_index == self._var_count - 1 and obs_index == self._row_count - 1:
            self.finalize_values()


cdef class MetaData:

    cdef readstat_metadata_t _this

    @property
    def row_count(self):
        return readstat_get_row_count(&self._this)

    @property
    def var_count(self):
        return readstat_get_var_count(&self._this)

cdef class Variable:

    cdef readstat_variable_t _this

    @property
    def index(self):
        return readstat_variable_get_index(&self._this)

    @property
    def index_after_skipping(self):
        return readstat_variable_get_index_after_skipping(&self._this)

    @property
    def name(self):
        return readstat_variable_get_name(&self._this).decode('utf-8')

    @property
    def label(self):
        cdef const char *label;
        label = readstat_variable_get_label(&self._this);
        if label != NULL:
            return label.decode('utf-8')
        else:
            return None

    @property
    def format(self):
        return readstat_variable_get_format(&self._this).decode('utf-8')

    @property
    def type(self):
        t = readstat_variable_get_type(&self._this)
        if t == READSTAT_TYPE_STRING:
            return str
        elif t == READSTAT_TYPE_INT8:
            return int
        elif t == READSTAT_TYPE_INT16:
            return int
        elif t == READSTAT_TYPE_INT32:
            return int
        elif t == READSTAT_TYPE_FLOAT:
            return float
        elif t == READSTAT_TYPE_DOUBLE:
            return float
        else:
            return None

    @property
    def type_class(self):
        tc = readstat_variable_get_type_class(&self._this)
        if tc == readstat_type_class_t.READSTAT_TYPE_CLASS_STRING:
            return str
        else:
            return Number

    @property
    def storage_width(self):
        return readstat_variable_get_storage_width(&self._this)

    @property
    def display_width(self):
        return readstat_variable_get_display_width(&self._this)

    @property
    def measure(self):
        cdef readstat_measure_t t
        t = readstat_variable_get_measure(&self._this)
        if t == READSTAT_MEASURE_NOMINAL:
            return Measure.NOMINAL
        elif t == READSTAT_MEASURE_ORDINAL:
            return Measure.ORDINAL
        elif t == READSTAT_MEASURE_SCALE:
            return Measure.SCALE
        else:
            return Measure.UNKNOWN

    @property
    def alignment(self):
        return readstat_variable_get_alignment(&self._this)

    @property
    def missing_ranges_count(self):
        return readstat_variable_get_missing_ranges_count(&self._this)

    # @property
    # def missing_range(self):
    #    readstat_value_t readstat_variable_get_missing_range_lo(const readstat_variable_t *variable, int i);
    #    readstat_value_t readstat_variable_get_missing_range_hi(const readstat_variable_t *variable, int i);
