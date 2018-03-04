
from distutils.core import setup
from distutils.extension import Extension
from Cython.Build import cythonize
import glob

source_files = [ ]
source_files += glob.glob('jamovi/libs/ReadStat/src/*.c')
source_files += glob.glob('jamovi/libs/ReadStat/src/spss/*.c')
source_files += glob.glob('jamovi/libs/ReadStat/src/sas/*.c')
source_files += glob.glob('jamovi/libs/ReadStat/src/stata/*.c')
source_files += [ 'jamovi/readstat.pyx' ]

libraries = ['iconv']

ext = Extension(
    'jamovi.readstat',
    sources=source_files,
    libraries=libraries)

setup(
    name='jamovi-readstat',
    version='0.1.0',
    ext_modules = cythonize([ext]),
)
