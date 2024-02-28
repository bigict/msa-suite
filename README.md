# MSA-suite

## Motivations
Improve protein structure prediction accuracy by MSA searching strategies

## FAQ
1. How to run [msa-suite](http://github.com/bigict/msa-suite)  
   Install dependencies: [hh-suite](https://github.com/soedinglab/hh-suite) && [qhhmer](https://github.com/kad-ecoli/qhmmer)
   ```shell
   $ git clone git@github.com:bigict/msa-suite.git
   $ cd msa-suite
   $ git submodule update --init
   $ cd hh-suite
   $ cmake -DCMAKE_INSTALL_PREFIX=.. .
   $ make && make install
   $ cd ../qhmmer
   $ ./configure --prefix=`readlink -f ..`
   $ make && make install && make -D easel install
   $ cd ..
   $ python build_msa.py
   ```
2. Download databases
