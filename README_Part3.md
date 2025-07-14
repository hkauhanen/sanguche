# Detailed instructions, Part 3: Phylogenetic analysis

NB!!!! Running 3 large families for both datasets in parallel on the GPU takes up about 4.5 GB of VRAM. This means we can increase the number of families in the "large" MrBayes sets quite considerably, and thereby probably make things a bit faster. In general, the best strategy (wall-clock-runtime-wise) is to do WALS and Grambank in parallel, having the large families run on the GPU and the small ones on the CPU.




This document details how Part 3 of the analysis (see [README.md](README.md) for overall summary) is set up and run. It is divided into two major sections:

1. Installing dependencies
1. Running the analysis

We employed the following system:

- Intel i5-13600KF processor
- 64 GB of DDR4 RAM
- NVIDIA GeForce RTX 3080 GPU
- Debian 12 ("bookworm")
- Julia version 1.5.3
- R version 4.4.2

Many parts of the instructions to follow are specific to this hardware configuration; if your system differs from this considerably (e.g. a non-NVIDIA GPU, or no GPU at all; running on Windows; etc.) you will need to adapt the instructions, and possibly parts of the code, to suit.

We assume that you have super-user rights; if not, please configure this first.


## Installing dependencies

### 1. Install CUDA

Follow the instructions at <https://docs.nvidia.com/cuda/cuda-installation-guide-linux>.

Run the deviceQuery sample to verify that installation was successful.

Alternatively, if on Debian, you can install CUDA directly from the Debian repository.


### 2. Install other dependencies

On Debian (with sudo configured for the user):

```
sudo apt install openmpi-bin \
openmpi-common \
mpi-default-dev \
cmake \
autoconf \
automake \
libtool \
subversion \
pkg-config \
curl
```


### 3. Install BEAGLE (version 4.0.1)

Important: BEAGLE will not work with GCC versions later than 11. Make sure that gcc <= 11 is installed and then switch to using it with the following commands:

```
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 60
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-11 60
```

(assuming you're downgrading for example from version 12 to version 11).

Then, to build BEAGLE:

```
git clone --branch v4.0.1 --depth=1 https://github.com/beagle-dev/beagle-lib.git
cd beagle-lib
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX:PATH=$HOME -DBUILD_OPENCL=OFF -DBUILD_JNI=OFF ..
make
sudo make install
```

*(N.B. This installs the BEAGLE libraries into `$HOME/lib`. If this is undesirable, modify the above commands as well as the commands in the MrBayes subsection below.)*

Then add `$HOME/lib` to path (e.g. `fish_add_path $HOME/lib` if using fish).

Then:

```
export LD_LIBRARY_PATH=$HOME/lib:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=$HOME/lib/pkgconfig:$PKG_CONFIG_PATH
export PATH=/usr/local/cuda-12.9/bin:$PATH
```

NB: put exports also in .bashrc so they get loaded when new shells are started


### 4. Install MrBayes

```
git clone --branch v3.2.7 --depth=1 https://github.com/NBISweden/MrBayes
cd MrBayes
./configure --with-beagle=$HOME --with-mpi
make
sudo make install
```


### 5. Install RevBayes

Download executable from <https://revbayes.github.io/download> and extract. Update path of your shell so that the executable can be found.


### 6. Take care of broken Python packages

Fire up Julia with `julia +1.5.3` and do:

```
using Pkg
Pkg.add("PyCall")
Pkg.add("Conda")
using Conda
Conda.add("ete3")
Conda.add("six")
```

This step was necessary for mysterious reasons.


## Running the analysis

Executing the following scripts runs the analysis for WALS (repeat with `grambank` in place of `wals` to run it for Grambank). The lines commented with `TIME-CONSUMING` take a long time; be prepared for runtimes on the order of one week for `mrbayes` and one day for `model`, depending on the dataset and the hardware used.

```
make data DATASET=wals              # (this should have already been run in Step 1)
make phyloprep DATASET=wals
make familyprep DATASET=wals
make revbayes DATASET=wals NPROC=8  # adjust NPROC if necessary
make mrbayes_small DATASET=wals NPROC=8 BEAGLERES=0 AGGRESSIVE=0 PRECISION=double
make mrbayes_large DATASET=wals NPROC=3 BEAGLERES=1 AGGRESSIVE=0 PRECISION=double # TIME-CONSUMING (~1 week)
make posterior DATASET=wals
make model DATASET=wals             # TIME-CONSUMING (~1 day)
make correlations DATASET=wals
```

The order of the above operations is important.

This is fine-tuned for the hardware listed above. Your mileage may vary; in particular, you may find it necessary to tune the numbers of parallel processes used in `Makefile`.

`BEAGLERES` is used to select the Beagle resource (device) in MrBayes. This should be set to the fastest resource available, a determination that may depend on the size of the language family. In practice, I have found small families to be quickest on the CPU and large families quickest on the GPU. Launch MrBayes and type `showbeagle` to obtain the ID number of the relevant resource and set `BEAGLERES` to this number.

While MrBayes is running, a trace of the convergence can be produced with the following command. Output goes to the `log/` directory.

```
make treelog DATASET=wals
```

This assumes that R is installed and the following packages are available: ggplot2, ggsci, reshape2.


