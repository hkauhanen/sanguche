cd modelFitting

for i in {15..21}; do 
  julia +1.5.3 universal.jl $i
done

cd ..
