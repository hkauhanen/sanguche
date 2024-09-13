cd modelFitting

for i in {0..3}; do 
  for j in {0..14}; do
    let "k = $i*10 + $j"
    #echo $k; sleep 2 &   ### debugging/testing
    julia +1.5.3 universal.jl $k &
  done
  let "k = $i*10 + 15"
  #echo $k; sleep 2 ;     ### debugging/testing
  julia +1.5.3 universal.jl $k ;
done

cd ..
