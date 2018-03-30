
import platform
import glob

from distutils.core import setup
from distutils.extension import Extension
from Cython.Build import cythonize


source_files = [ ]
source_files += glob.glob('jamovi/libs/ReadStat/src/*.c')
source_files += glob.glob('jamovi/libs/ReadStat/src/spss/*.c')
source_files += glob.glob('jamovi/libs/ReadStat/src/sas/*.c')
source_files += glob.glob('jamovi/libs/ReadStat/src/stata/*.c')
source_files += [ 'jamovi/readstat.pyx' ]

library_dirs = [ ]
libraries = [ ]
include_dirs = [ ]
extra_link_args = [ ]
extra_compile_args = [ '-DHAVE_ZLIB' ]

if platform.system() == 'Darwin':
    libraries.append('iconv')
elif platform.system() == 'Windows':
    include_dirs.append('jamovi/libs')
    library_dirs.append('jamovi/libs')
    libraries.append('libiconv-static')
    libraries.append('libz-static')
elif platform.system() == 'Linux':
    libraries.append('z')
else:
    raise RuntimeError('Unsupported OS')

ext = Extension(
    'jamovi.readstat',
    sources=source_files,
    library_dirs=library_dirs,
    libraries=libraries,
    include_dirs=include_dirs,
    extra_compile_args=extra_compile_args,
    extra_link_args=extra_link_args)

setup(
    name='jamovi-readstat',
    version='0.1.0',
    ext_modules=cythonize([ext]),
)
