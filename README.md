# conda-gmx-plumed-mpi
Conda installable mpi version of gromacs 2021.4 patched with plumed 2.8.0

 How I built: 
 
 First build the files required for conda-build (inspiration from pre-existing repos, openmpi failed but mpich worked -> not sure why)
 
 Install conda-build in base
 
 cd plumed_mpi
 
 conda build . -c bioconda -c conda-forge
 
 "anaconda upload" plumed_mpi to ajaymur1991
 
 cd gromacs_mpi 
 
 conda build . -c ajaymur1991 -c bioconda -c conda-forge
 
 "anaconda upload" plumed_mpi to ajaymur1991
 
 Then installed other required software and finally conda-packed the resulting environment (see nucl.yaml)
 
 
