cd modelFitting

for i in {8..14}; do 
  julia +1.5.3 universal.jl $i
done

cd ..
