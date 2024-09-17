cd modelFitting

for i in {28..36}; do 
  julia +1.5.3 universal.jl $i
done

cd ..
