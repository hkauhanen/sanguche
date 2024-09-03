# sanguche

Data analysis code for the paper:

> Deepthi Gopal, Henri Kauhanen, Christopher Kitching, Tobias Galla & Ricardo Bermúdez-Otero (in prep.) Contact helps dispreferred combinations of typological features to survive: geospatial evidence. Manuscript, Universities of Uppsala, Konstanz, Manchester, and the Balearic Isles.

Requirements:

- Julia (both versions 1.5.3 and 1.10.4)
- R (version 4.2.2)
- MrBayes version 3.2.7a with BEAGLE and MPI support
- RevBayes version 1.2.3
- GNU make
- Bash
- an internet connection (to download the WALS and Grambank datasets and great-circle distances)


## Roadmap

The code is divided into three parts:

1. **Phylogenetic analysis.** This part first creates a set of posterior trees, then runs Jäger and Wahle's continuous time Markov chain model on those phylogenies to obtain "phylogenetically corrected" phi coefficients (along with other relevant summary statistics) for all feature pairs of interest.
2. **"Sandwichness" analysis.** This part measures Delta (neighbourhood entropy differential) values from the actual empirical geographical distribution of languages.
3. **Post-processing.** This part combines parts 1 and 2 into the final combined dataset, plus runs statistics and produces plots.

Each part needs to be run on our two datasets, WALS and Grambank, separately.


## Instructions, Part 1: Phylogenetic analysis

This bit is (very) time-consuming, as estimating the posterior distributions for all language families takes considerable time. We have attempted to parallelize the code as much as feasible, but, in practice, on our system (AMD Ryzen 3950X, 128GB DDR4 RAM, and 2 x NVIDIA GeForce RTX 2070 Super), the wall clock time of Part 1 is FIXME.

As configuring the system for all the dependencies of the Bayesian procedure is also tricky, we assume not all readers will be interested in reproducing Part 1. However, if you wish to do so, detailed instructions can be found in <phylo/README.md>. Part 1 requires Julia 1.5.3.

The relevant output of Part 1 is four files:

- `phylo/results/wals/bfCorr.csv`
- `phylo/results/wals/correlations.csv`
- `phylo/results/grambank/bfCorr.csv`
- `phylo/results/grambank/correlations.csv`

As long as these exist, the code in Part 3 will be able to combine the results of Part 1 and Part 2 into the final set of results.

Part 1 is an adaptation of the code to Jäger and Wahle (FIXME), released under the MIT Licence.


## Instructions, Part 2: "Sandwichness" analysis

Part 2 is considerably less time-consuming, taking between some minutes and an hour depending on available computing power.

Part 2 requires Julia version 1.10.4.

First, install Juliaup by following the instructions at <https://github.com/JuliaLang/juliaup>.

Then, to reproduce the analysis from scratch, type the following on the command line, paying special attention to the capitalization:

```
juliaup add 1.10.4
make Jdeps
make analysis DATASET=wals
make analysis DATASET=grambank
```

(For any subsequent reproductions of this analysis, you may omit the `make Jdeps` bit which simply installs all required Julia dependencies.)

Results are saved in the `results/wals/` and `results/grambank/` directories, respectively. The `results.csv` files are in ordinary comma-separated values format; the `results.jls` files are serializations of Julia dataframes which can be loaded into a Julia session by `using Serialization, DataFrames; results = serialize("results.jls")`.

To speed up processing, parts of the analysis are parallelized over processor cores. To control the number of worker processes, modify the `NPROCS` variable in the `Makefile` (it is generally best to set this equal to the number of physical cores in your processor, assuming this is the only task the computer is running).

Temporary files are saved in `tmp/`. If you wish to delete these after the analysis has been run, type:

```
make clean
```

If you also wish to delete results, type:

```
make purge
```


## Instructions, Part 3: Post-processing

The final part, which combines the output of Parts 1 and 2, is quick. It depends on Julia version 1.10.4 and R version 4.4.2.

```
make Rdeps
make posthoc
```

The resulting statistics and plots will appear in `results/tables/` and `results/plots/` and `results/tables/`, respectively.


## Interlude: Brief description of code logic of Part 2

The data analysis in Part 2 is broken down into four major phases. All source code is contained in the `jl/` directory; the relationships between the various phases can be examined in the `Makefile`.

1. **Data preparation.** Data (either WALS or Grambank) are first downloaded from the internet, then wrangled into a format suitable for our analysis. At this stage, we also construct features VO, PN and NRc for Grambank from pairs of features, as described in the paper.
1. **Dictionary preparation.** We next obtain the subset of the data for every feature–feature pair of interest. These subsets are stored in a dictionary for later use. We also prepare a second dictionary which contains the nearest geographical neighbours table for each language, for each feature–feature pair. The latter are obtained from great-circle distance data which is downloaded from <https://github.com/hkauhanen/wals-distances> and <https://github.com/hkauhanen/grambank-distances>.
1. **Neighbourhood entropy computation.** We then cycle through the dictionaries created in the previous step, calculating neighbourhood entropies in each case.
1. **Pretty printing.** The resulting dataframes are pretty-printed for subsequent use in Part 3.


## Acknowledgements

We are grateful to Gerhard Jäger and Johannes Wahle for making available the code to their paper, "Phylogenetic typology", <https://doi.org/10.3389/fpsyg.2021.682132>.

This project has received funding from the European Research Council (ERC) under the European Union's Horizon 2020 research and innovation programme (grant agreement n° 851423).


