cd modelFitting

for i in {1..9}; do 
  julia +1.5.3 universal.jl $i
done

cd ..
