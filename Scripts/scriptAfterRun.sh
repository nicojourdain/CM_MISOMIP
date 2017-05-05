
iter=$( awk '/Time:/ {print $3}' output.out | tail -1 )
iter=$((iter / 100 ))
echo $iter

timea=$(awk '/Time:/ {print $4}' output.out | tail -1)
echo $timea

mv <MeshNamePath>/Mesh/*vtu <MeshNamePath>/Results/$1
echo $1 $iter $timea >> Run.db 
