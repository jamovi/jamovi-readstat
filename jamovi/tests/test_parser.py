
import unittest
import os.path
from collections import OrderedDict
from numbers import Number

from jamovi.readstat import Parser
from jamovi.readstat import Measure
from jamovi.readstat import Error

TOOTHGROWTH_PATH = os.path.join(os.path.dirname(__file__), 'Tooth Growth.sav')


class ExampleParser(Parser):

    def __init__(self):

        self._tmp_value_labels = { }

        self.metadata = None
        self.variables = [ ]
        self.labels = [ ]
        self.finalized = False
        self.values = [ ]

    def handle_metadata(self, metadata):
        self.metadata = metadata

    def handle_value_label(self, labels_key, value, label):
        if labels_key not in self._tmp_value_labels:
            labels = OrderedDict()
            self._tmp_value_labels[labels_key] = labels
        else:
            labels = self._tmp_value_labels[labels_key]
        labels[value] = label

    def handle_variable(self, index, variable, labels_key):
        self.variables.append(variable)
        self.labels.append(self._tmp_value_labels.get(labels_key, None))

    def finalize_variables(self):
        self._tmp_value_labels = { }  # discard, no longer needed
        self.finalized = True
        self.values = [ [ None ] * self.metadata.row_count for i in range(self.metadata.var_count) ]

    def handle_value(self, var_index, row_index, value):
        self.values[var_index][row_index] = value

    def finalize_values(self):
        for var_index in range(self.metadata.var_count):
            var_labels = self.labels[var_index]
            if var_labels is None:
                continue
            var_values = self.values[var_index]
            for row_index in range(self.metadata.row_count):
                value = var_values[row_index]
                label = var_labels.get(value, None)
                if label is not None:
                    var_values[row_index] = (value, label)


class TestCore(unittest.TestCase):

    def test_parser(self):
        parser = ExampleParser()

        with self.assertRaises(Error):
            parser.parse('something not existing')

        parser.parse(TOOTHGROWTH_PATH)

        self.assertTrue(parser.finalized)

        md = parser.metadata
        self.assertIsNotNone(md)
        self.assertEqual(md.row_count, 60)
        self.assertEqual(md.var_count, 4)

        vs = parser.variables
        values = parser.values
        self.assertEqual(len(vs), 4)

        l3n = vs[0]
        self.assertEqual(l3n.name, 'len')
        self.assertEqual(l3n.type, float)
        self.assertEqual(l3n.type_class, Number)
        self.assertEqual(l3n.measure, Measure.SCALE)
        self.assertEqual(values[0][0],  4.2)
        self.assertEqual(values[0][1],  11.5)
        self.assertEqual(values[0][59], 23.0)

        supp = vs[1]
        self.assertEqual(supp.name, 'supp')
        self.assertEqual(supp.type, str)
        self.assertEqual(supp.type_class, str)
        self.assertEqual(supp.measure, Measure.NOMINAL)
        self.assertEqual(values[1][0],  ('VC', 'Vitamin C'))
        self.assertEqual(values[1][59], ('OJ', 'Orange Juice'))

        dose = vs[2]
        self.assertEqual(dose.name, 'dose')
        self.assertEqual(dose.type, float)
        self.assertEqual(dose.type_class, Number)
        self.assertEqual(dose.measure, Measure.ORDINAL)
        self.assertEqual(values[2][0],  (500.0, 'small'))
        self.assertEqual(values[2][59], (2000.0, 'large'))


if __name__ == '__main__':
    unittest.main()
