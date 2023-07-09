PXEinstall - test
=======================
Test environment running PXE in qemu in docker with generated files from boot/output. 


Usage
=======================
Either manually generate boot files with preferred configuration options in boot directory then copy output/* files to test/tftp, then run 
```
make
```
Alternatively, you can just run 
```
make
```
from the root of the repository, i.e. cd .. to run tests with default configuration options.
