# Detailed instructions, Part 3: Phylogenetic analysis

This documents details how Part 3 of the analysis (see [README.md](README.md) for overall summary) is set up and run. It is divided into two major sections:

1. Installing dependencies
1. Running the analysis

We employed the following system:

- AMD Ryzen 9 3950X (16 cores @ 3.5 GHz)
- 128GB of DDR4 RAM
- NVIDIA GeForce RTX 2070 SUPER GPU
- Debian 12 ("bookworm")
- Julia version 1.5.3
- R version 4.4.2

Many parts of the instructions to follow are specific to this hardware configuration; if your system differs from this considerably (e.g. a non-NVIDIA GPU, or no GPU at all; running on Windows; etc.) you will need to adapt the instructions, and possibly parts of the code, to suit.

We assume that you have super-user rights; if not, please configure this first.


## Installing dependencies

### 1. Install CUDA (version 12.6)

Follow the instructions at <https://docs.nvidia.com/cuda/cuda-installation-guide-linux>.

Run the deviceQuery sample to verify that installation was successful.


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

```
git clone --depth=1 https://github.com/beagle-dev/beagle-lib.git
cd beagle-lib
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX:PATH=$HOME -DBUILD_OPENCL=ON -DBUILD_JNI=OFF ..
sudo make install
```

*(N.B. This installs the BEAGLE libraries into `$HOME/lib`. If this is undesirable, modify the above commands as well as the commands in the MrBayes subsection below.)*

Then add `$HOME/lib` to path (e.g. `fish_add_path $HOME/lib` if using fish).


### 4. Install MrBayes

```
git clone --depth=1 https://github.com/NBISweden/MrBayes
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

Executing the following scripts runs the analysis.

```
make phyloprep DATASET=wals
make phyloprep DATASET=grambank

FIXME: add the remaining steps
```

This is fine-tuned for the hardware listed above. Your mileage may vary; in particular, you may find it necessary to tune the numbers of parallel processes used in `Makefile` and `run.sh`.

N.B. **This takes time.** For us, about 4 days for WALS and about 10 days for Grambank.


