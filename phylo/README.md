# Instructions, Part 2: Phylogenetic analysis

This documents details how Part 1 of the analysis is set up and run. It is divided into two major sections:

1. Installing dependencies
1. Running the analysis

We employed the following system:

- AMD Ryzen 9 3950X (16 cores @ FIXME GHz)
- 128GB of DDR4 RAM
- 2 x NVIDIA GeForce RTX 2070 SUPER GPU
- Debian 12 ("bookworm")
- Julia version 1.5.3
- R version 4.4.2

Many parts of the instructions to follow are specific to this hardware configuration; if your system differs from this 
considerably (e.g. a non-NVIDIA GPU, or no GPU at all; running on Windows; etc.) you will need to adapt
the instructions, and possibly parts of the code, to suit.

In particular, if your processor has fewer than 8 cores, you may wish to modify `src/code/runMrBayes.jl` so that the
MPI process is started with 4 or 2 processes instead.

We assume that you have `sudo` rights; if not, please configure this first.


## Installing dependencies

### 1. Install CUDA (version 12.6)

Follow the instructions at <https://docs.nvidia.com/cuda/cuda-installation-guide-linux>.

Run the deviceQuery sample to verify that installation was successful.


### 2. Install other dependencies

```
sudo apt install openmpi-bin /
openmpi-common /
mpi-default-dev /
cmake /
autoconf /
automake /
libtool /
subversion /
pkg-config
```


### 3. Install BEAGLE (version 4.0.1)

```
git clone --depth=1 https://github.com/beagle-dev/beagle-lib.git
cd beagle-lib
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX:PATH=$HOME -DBUILD_OPENCL=OFF -DBUILD_JNI=OFF ..
sudo make install
export LD_LIBRARY_PATH=$HOME/lib:$LD_LIBRARY_PATH
```


### 4. Install MrBayes

```
git clone --depth=1 https://github.com/NBISweden/MrBayes
cd MrBayes
./configure --with-beagle=$HOME --with-mpi
make
sudo make install
```


### 5. Install RevBayes

Download executable from <https://revbayes.github.io/download> and extract. Update path of your shell
so that the executable is found.


### 6. Install Julia 1.5.3

```
curl -fsSL https://install.julialang.org | sh
juliaup add 1.5.3
```


### 7. Take care of broken Python packages

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

Executing the following scripts runs the analysis:

```
bash run.sh wals
bash run.sh grambank
```

This is fine-tuned for the hardware listed above. Your mileage may vary; in particular, you may find it necessary to tune the numbers of parallel processes used in `Makefile` and `run.sh`.

N.B. **This takes time.** For us, FIXME.


