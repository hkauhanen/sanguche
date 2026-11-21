# sanguche

Data analysis code for the paper:

> Deepthi Gopal, Henri Kauhanen, Christopher Kitching, Tobias Galla & Ricardo Bermúdez-Otero (in prep.) Contact helps dispreferred combinations of typological features to survive: geospatial evidence. Manuscript, Universities of Uppsala, Konstanz, Manchester, and the Balearic Isles.

Requirements:

- Julia (both versions 1.5.3 and 1.10.4)
- R (version 4.5.0)
- [just](https://github.com/casey/just)
- an internet connection (to download the WALS and Grambank datasets and great-circle distances)


## Instructions

To replicate the analysis, run the following commands (in this order).
Make sure you have Julia versions 1.5.3 and 1.10.4 installed via
juliaup before proceeding!

```{bash}
just deps         # installs Julia dependencies
just preprocess   # downloads and preps data
just data         # preps data more
just joincounts   # computes join counts
just report       # typesets reports (R + some packages required)
```

The data and results will appear in directory `tmp/`. (This is gitignored
as some of the resulting files are very large.)

The report appears as `Rmd/report.pdf`.


## Acknowledgements

We are grateful to Gerhard Jäger and Johannes Wahle for making available the code to their paper, "Phylogenetic typology", <https://doi.org/10.3389/fpsyg.2021.682132>.



