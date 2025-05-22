# sanguche

Data analysis code for the paper:

> Deepthi Gopal, Henri Kauhanen, Christopher Kitching, Tobias Galla & Ricardo Bermúdez-Otero (in prep.) Contact helps dispreferred combinations of typological features to survive: geospatial evidence. Manuscript, Universities of Uppsala, Konstanz, Manchester, and the Balearic Isles.

Requirements:

- Julia (both versions 1.5.3 and 1.10.4)
- R (version 4.2.2)
- MrBayes version 3.2.7a compiled with BEAGLE and MPI support
- BEAGLE version 4.0.1
- RevBayes version 1.2.3
- GNU make
- Bash
- an internet connection (to download the WALS and Grambank datasets and great-circle distances)


## Roadmap

The code is divided into four parts:

1. **Preparations.** In this first part, the data (WALS and Grambank) are downloaded and prepared for later use.
2. **"Sandwichness" analysis.** This part measures Delta (neighbourhood entropy differential) values from the actual empirical geographical distribution of languages.
3. **Phylogenetic analysis.** This part first creates a set of posterior trees, then runs Jäger and Wahle's continuous time Markov chain model on those phylogenies to obtain "phylogenetically corrected" phi coefficients (along with other relevant summary statistics) for all feature pairs of interest.
4. **Post-processing.** This part combines the output of parts 2 and 3 into the final combined dataset, plus runs statistics and produces plots.

Each part needs to be run on our two datasets, WALS and Grambank, separately.


## Instructions, Part 1: Preparations

Part 1 requires both Julia version 1.5.3 and Julia version 1.10.4.

First, install Juliaup by following the instructions at <https://github.com/JuliaLang/juliaup>. Then type the following to add the required Julia versions and to install all required dependencies:

```
juliaup add 1.5.3
juliaup add 1.10.4
make Jdeps
```

To download the two databases and prepare them for later use, type:

```
make data DATASET=wals
make data DATASET=grambank
```


## Instructions, Part 2: "Sandwichness" analysis

Part 2 requires Julia version 1.10.4.

To reproduce the analysis from scratch, type the following on the command line, paying special attention to the capitalization:

```
make sandwich DATASET=wals LIMTYPE=rank NPROC=8
make sandwich DATASET=grambank LIMTYPE=rank NPROC=8
```

`LIMTYPE` can be either `km` (distance-limited neighbourhoods) or `rank` (neighbourhoods limited by number of neighbours). `NPROC` specifies the number of parallel processes to use (best set to the number of physical cores in your processor).

Note that each argument, `DATASET`, `LIMTYPE` and `NPROC`, are mandatory.

Results are saved in the `results/wals/` and `results/grambank/` directories, respectively. The `*.csv` files are in ordinary comma-separated values format; the `*.jls` files are serializations of Julia dataframes which can be loaded into a Julia session using the tools provided by the Serialization package.

To speed up processing, parts of the analysis are parallelized over processor cores. To control the number of worker processes, modify the `NPROCS` variable in the `Makefile` (it is generally best to set this equal to the number of physical cores in your processor, assuming this is the only task the computer is running).

Temporary files are saved in various subdirectories of `wals/` and `grambank/` (.gitignored by default). Since some of these are also needed by the phylogenetic analysis (Part 3, see below), it is best to leave them untouched for now.


## Instructions, Part 3: Phylogenetic analysis

This bit is (very) **time-consuming**, as estimating the posterior distributions for the largest language families takes considerable time. We have attempted to parallelize the code as much as is feasible, but, in practice, on our system (AMD Ryzen 3950X, 128GB DDR4 RAM, and an NVIDIA GeForce RTX 2070 Super), the wall clock time of Part 3 is on the order of 4 days for WALS and on the order of 10 days for Grambank.

As configuring the system for all the dependencies of the Bayesian procedure is also tricky, we assume not all readers will be interested in reproducing Part 3. However, if you wish to do so, detailed instructions can be found in [README_Part3.md](README_Part3.md).

Part 3 requires Julia 1.5.3 (already installed in Part 1).

The relevant output (for further processing) of Part 3 consists of four files:

- `results/wals/bfCorr.csv`
- `results/wals/correlations.csv`
- `results/grambank/bfCorr.csv`
- `results/grambank/correlations.csv`

As long as these exist, the code in Part 4 will be able to combine the results of Part 2 and Part 3 into the final set of results.

Part 3 is an adaptation of the code to Jäger and Wahle (FIXME), released under the MIT Licence.


## Instructions, Part 4: Post-processing

The final part, which combines the output of Parts 2 and 3, is quick. It depends on Julia version 1.10.4 and R version 4.4.2.

```
make Rdeps
make postprocess DATASET=wals
make stats DATASET=wals
make plots DATASET=wals
```

Replace `wals` with `grambank` to produce the same for Grambank.

The resulting statistics and plots will appear in `results/`, `results/tables/` and `results/plots/`.


## Postlude: Brief description of code logic of Part 2

The data analysis in Part 2 is broken down into two major phases. All source code is contained in the `src/code/` directory; the relationship between the phases can be examined in the `Makefile`.

The starting point for Part 2 is the output of Part 1, the prepared datasets. To produce these, Part 1 first downloads the databases from the internet, then wrangles them into a format suitable for our analysis. At this stage, we also construct features VO for Grambank from four original Grambank features, as described in the paper.

After this, Part 2 proceeds as follows:

1. **Phase 1: Dictionary preparation.** We obtain the subset of the data for every feature–feature pair of interest. These subsets are stored in a dictionary for later use. We also prepare a second dictionary which contains the nearest geographical neighbours table for each language, for each feature–feature pair. The latter are obtained from great-circle distance data which are downloaded from <https://github.com/hkauhanen/wals-distances> and <https://github.com/hkauhanen/grambank-distances>.
1. **Phase 2: Neighbourhood entropy computation.** We next cycle through the dictionaries created in the previous step, calculating neighbourhood entropies in each case.


## Acknowledgements

We are grateful to Gerhard Jäger and Johannes Wahle for making available the code to their paper, "Phylogenetic typology", <https://doi.org/10.3389/fpsyg.2021.682132>.

This project has received funding from the European Research Council (ERC) under the European Union's Horizon 2020 research and innovation programme (grant agreement n° 851423).


