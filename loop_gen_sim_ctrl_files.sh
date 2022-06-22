#!/bin/bash

mkdir prot_production
cd init_pdb
init_name="xxxx"

for file in ./*
    do
        if test -f $file
        then
            echo ${file#*/}
            if [ "${file##*.}" = "pdb" ]
            then
                prot=`basename ${file#*/} .pdb`
                cd ../prot_production
                mkdir $prot
                cd $prot
                cp ../../init_pdb/${file#*/} .
                pdb4amber -i $prot.pdb -o ${prot}_mod_1.pdb -y -d -p --no-conect 2> ${prot}_mod_1.log
                rm {${prot}_mod_1_renum.txt,${prot}_mod_1_nonprot.pdb,${prot}_mod_1_water.pdb,${prot}_mod_1_sslink}
                cp ../../add_TER.cpp .
                sed -i "s/$init_name/$prot/g" add_TER.cpp
                g++ add_TER.cpp
                N_res=`./a.out`

cat>leap.in<<EOF
source leaprc.protein.ff14SB
source leaprc.DNA.OL15
source leaprc.RNA.OL3
source leaprc.water.tip3p
loadamberparams frcmod.ionsjc_tip3p
loadamberparams frcmod.ions234lm_126_tip3p
model=loadpdb ${prot}_mod_2.pdb
solvateoct model TIP3PBOX 20.0
addIonsRand model K+ 0
addIonsRand model Cl- 0
saveamberparm model $prot.prmtop $prot.inpcrd
quit
EOF

                tleap -f leap.in

cat>min.in<<EOF
minimization script
&cntrl
imin = 1,
maxcyc = 6000,
ncyc = 3000,
ntb = 1,
ntr = 0,
cut = 12,
/
EOF

cat>heat.in<<EOF
heating script
&cntrl
imin = 0, irest = 0, ntx = 1,
ntb = 2, ntp = 1, pres0 = 1.0, taup = 2.0, 
ntpr = 10000, ntwr = 10000, ntwx = 10000,
ntt = 3, gamma_ln = 1.0, tempi = 0, temp0 = 300,
iwrap = 1, ntc = 2, ntf = 2,
nstlim = 50000, dt = 0.001,
cut = 10.0,
ntr = 1, restraint_wt = 100.0,
restraintmask = ":1-${N_res}",
/
EOF

cat>equil.in<<EOF
equilibration script
&cntrl
imin = 0, irest = 1, ntx = 5,
ntb = 2, ntp = 1, pres0 = 1.0, taup = 2.0,
ntpr = 10000, ntwr = 10000, ntwx = 10000,
ntt = 3, gamma_ln = 1.0, tempi = 300, temp0 = 300,
iwrap = 1, ntc = 2, ntf = 2,
nstlim = 100000, dt = 0.001,
cut = 10.0,
/
EOF

cat>md.in<<EOF
md script
&cntrl
imin = 0, irest = 1, ntx = 5,
ntb = 2, ntp = 1, pres0 = 1.0, taup = 2.0,
ntpr = 10000, ntwr = 10000, ntwx = 10000,
ntt = 3, gamma_ln = 1.0, tempi = 300, temp0 = 300,
iwrap = 1, ntc = 2, ntf = 2,
nstlim = 10000000, dt = 0.002,
cut = 10.0,
/
EOF

                cd ../../init_pdb
            fi
        fi
    done

cd ../prot_production

cat>sub.sh<<EOF
#!/bin/bash

for file in ./*
    do
        if [ -d "\$file" ]
        then
            cd \$file
            ./min.sh
            cd ..
        fi
    done
EOF

chmod +x sub.sh
