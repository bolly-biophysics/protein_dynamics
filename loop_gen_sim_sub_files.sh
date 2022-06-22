#!/bin/bash

cd prot_production

for file in ./*
    do
        if [ -d "$file" ]
        then
            echo ${file#*/}
            prot=${file#*/}
            cd $file
            GPU_ID=(0 2 3 5)
            index=$(expr $(date +%N) % 4)

cat>min.sh<<EOF
#!/bin/bash

export CUDA_VISIBLE_DEVICES=${GPU_ID[$index]}
nohup pmemd.cuda -O -i min.in -o min.out -p $prot.prmtop -c $prot.inpcrd -r min.rst &
EOF

cat>heat.sh<<EOF
#!/bin/bash

export CUDA_VISIBLE_DEVICES=${GPU_ID[$index]}
nohup pmemd.cuda -O -i heat.in -o heat.out -p $prot.prmtop -c min.rst -r heat.rst -x heat.nc -ref min.rst &
EOF

cat>equil.sh<<EOF
#!/bin/bash

export CUDA_VISIBLE_DEVICES=${GPU_ID[$index]}
nohup pmemd.cuda -O -i equil.in -o equil.out -p $prot.prmtop -c heat.rst -r equil.rst -x equil.nc &
EOF

cat>run.sh<<EOF
#!/bin/bash

export CUDA_VISIBLE_DEVICES=${GPU_ID[$index]}
nohup pmemd.cuda -O -i md.in -o md.out -p $prot.prmtop -c equil.rst -r md.rst -x md.nc &
EOF

            chmod +x min.sh heat.sh equil.sh run.sh
            cd ..
        fi
    done
