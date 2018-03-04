
# jamovi-readstat

A python library for reading SPSS, SAS, and Stata data files, based on [ReadStat](https://github.com/WizardMac/ReadStat)

### to get

```
# clone
$ git clone https://github.com/jamovi/jamovi-readstat.git

# initialise the ReadStat submodule
$ cd jamovi-readstat/
$ git submodule init
$ git submodule update
```

### to install

```
$ python3 setup.py build install
```

### to run the unit tests

```
# first build in place
$ python3 setup.py build_ext --inplace

# run tests
$ python3 -m unittest discover
```

### to learn how to use it

probably easiest if you take a look at the [unit tests](https://github.com/jamovi/jamovi-readstat/blob/master/jamovi/tests/test_parser.py#L12)
