# sanguche

Data analysis code for the paper:

> Deepthi Gopal, Henri Kauhanen, Christopher Kitching, Tobias Galla & Ricardo Bermúdez-Otero (in prep.) Paper title.

Requirements:

- Julia (version 1.10.2 or newer)
- GNU make
- an internet connection (to download the WALS and Grambank datasets and great-circle distances)


## Instructions

To reproduce the analysis from scratch, type the following on the command line:

```
make DATASET=wals
make DATASET=grambank
```

Note the capitalization!

Results are saved in the `results/wals/` and `results/grambank/` directories, respectively. The `results.csv` files are in ordinary comma-separated values format; the `results.jls` files are serializations of Julia dataframes which can be loaded into a Julia session by `using Serialization, DataFrames; results = serialize("results.jls")`.

To speed up processing, parts of the analysis are parallelized over processor cores. To control the number of worker processes, modify the `PROCS` variable in the `Makefile` (it is generally best to set this equal to the number of physical cores in your processor). The variable `J` can be used to set the path to the Julia executable, and the variable `DEGREE` controls how many nearest neighbours are employed at a maximum in the calculation of neighbourhood entropies.

Temporary files are saved in `tmp/`. If you wish to delete these, type:

```
make clean
```


## Brief description of code logic

The data analysis is broken down into four major phases. All source code is contained in the `jl/` directory; the relationships between the various phases can be examined in the `Makefile`.

1. **Data preparation.** Data (either WALS or Grambank) are first downloaded from the internet, then wrangled into a format suitable for our analysis.
1. **Dictionary preparation.** We next obtain the subset of the data for every feature–feature pair of interest. These subsets are stored in a dictionary for later use. We also prepare a second dictionary which contains the nearest geographical neighbours table for each language, for each feature–feature pair. The latter are obtained from great-circle distance data which are downloaded from <https://github.com/hkauhanen/wals-distances> and <https://github.com/hkauhanen/grambank-distances>.
1. **Neighbourhood entropy computation.** We then cycle through the dictionaries created in the previous step, calculating neighbourhood entropies in each case.
1. **Pretty printing.** Finally, the resulting dataframes are pretty-printed. At this stage, for instance, we merge our results with those of Jäger & Wahle (`aux/JW.csv`).


## Acknowledgements

The file `aux/JW.csv` contains part of the results of Jäger and Wahle's paper "Phylogenetic typology", <https://doi.org/10.3389/fpsyg.2021.682132>. These data are reproduced here under the MIT licence.

This project has received funding from the European Research Council (ERC) under the European Union's Horizon 2020 research and innovation programme (grant agreement n° 851423).


