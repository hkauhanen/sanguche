cd modelFitting

for i in {19..27}; do 
  julia +1.5.3 universal.jl $i
done

cd ..
