deps:
  cd jl; julia +1.5.3 deps_JW.jl
  cd jl; julia +1.10.4 deps.jl
  Rscript -e "install.packages(c('lme4', 'ggplot2', 'ggsci', 'tidyverse', 'rmarkdown'), repos = 'https://cloud.r-project.org')"

preprocess:
  cd jl; julia +1.5.3 preprocess_wals.jl
  cd jl; julia +1.5.3 preprocess_grambank.jl
  cd jl; julia +1.5.3 preprocess_Jaeger.jl

data:
  cd jl; julia +1.5.3 createData.jl wals
  cd jl; julia +1.10.4 make_dicts.jl wals
  cd jl; julia +1.5.3 createData.jl grambank
  cd jl; julia +1.10.4 make_dicts.jl grambank

joincounts:
  cd jl; julia +1.10.4 -p 10 jclang.jl wals
  cd jl; julia +1.10.4 -p 10 jclang.jl grambank

report:
  cd Rmd; Rscript -e "library(rmarkdown); render('report.Rmd', 'pdf_document')"
