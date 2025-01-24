cd modelFitting

for i in {37..45}; do 
  julia +1.5.3 universal.jl $1 $i
done

cd ..
