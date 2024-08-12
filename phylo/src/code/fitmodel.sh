cd modelFitting

for i in {1..45}; do julia +1.5.3 universal.jl $i; done

cd ..
