#!/bin/bash

###################################################################################### 
################           Declaration section           #############################
######################################################################################

n=(5 7)			# Positions of mutations, space-separated
code=(GLY ALA)		# Three-letter code of new residues, space-separated
outpfilename="pHLIP-mutant"	# Prefix for output PDB/PSF files of mutant

nChains=5			# Number of chains (for aggregation)
aggfilename="pHLIP-multiple"	# Prefix for output PDB/PSF files of aggregate

inpfilename="pHLIP.pdb"		# Input PDB file (for pHLIP)


#####################################################################################
#################          Scripting begins              ############################
#####################################################################################

# Generate and run setup-mutator script
#echo ${code[1]}
nRes=${#code[@]}
nPos=${#n[@]}

if [ $nRes -ne $nPos ]; then
	echo "Error: You entered $nRes residues but $nPos positions."
	exit
fi

echo "package require psfgen" > setup-mutator.pgn
echo "psfcontext reset" >> setup-mutator.pgn
echo "topology top_all36_prot.rtf" >> setup-mutator.pgn
echo "segment U {" >> setup-mutator.pgn
echo "	pdb $inpfilename" >> setup-mutator.pgn

i=0
while [[ $i -lt $nRes ]]
do
	newPos=${n[$i]}
	newRes=${code[$i]}
	echo "	mutate $newPos $newRes" >> setup-mutator.pgn	
	i=$((i+1))
done

echo "}" >> setup-mutator.pgn
echo "coordpdb $inpfilename U" >> setup-mutator.pgn
echo "regenerate angles dihedrals" >> setup-mutator.pgn
echo "guesscoord" >> setup-mutator.pgn
echo "writepdb $outpfilename.pdb" >> setup-mutator.pgn
echo "writepsf $outpfilename.psf" >> setup-mutator.pgn
echo "exit" >> setup-mutator.pgn


vmd -dispdev text -e setup-mutator.pgn
#rm setup-mutator.pgn


# Generate chain names
declare -a names
i=0
for ch in {A..Z};
do
	if [ $i -lt $nChains ]; then
		eval names[$i]=$ch
	else
		break
	fi
	i=$((i+1))
done


# Generate and run setup-multiple script
echo "package require psfgen" > setup-multiple.pgn
echo "psfcontext reset" >> setup-multiple.pgn
echo "topology top_all36_prot.rtf" >> setup-multiple.pgn
j=0
while [[ $j -lt $nChains ]]
do
	segname=${names[$j]}
	echo "segment $segname {pdb $outpfilename.pdb}" >> setup-multiple.pgn
	echo "coordpdb $outpfilename.pdb $segname" >> setup-multiple.pgn
	j=$((j+1))
done
echo "regenerate angles dihedrals" >> setup-multiple.pgn
echo "guesscoord" >> setup-multiple.pgn
echo "writepdb $aggfilename-overlaid.pdb" >> setup-multiple.pgn
echo "writepsf $aggfilename.psf" >> setup-multiple.pgn
echo "exit" >> setup-multiple.pgn

vmd -dispdev text -e setup-multiple.pgn
#rm setup-multiple.pgn


# Generate random coordinates
./generateRandom.py $nChains

# Generate and run random coordinates script
echo "set fp [open "\"RandomCoords.rnd"\" r]" > rand-coords.pgn
echo "set file_data [read \$fp]" >> rand-coords.pgn
echo "close \$fp" >> rand-coords.pgn
echo "set lines [split \$file_data "\"'\'n"\"]" >> rand-coords.pgn
echo "set seg B" >> rand-coords.pgn
echo "set end [expr $nChains + 65]" >> rand-coords.pgn
echo "for {set i 67} {\$i < \$end} {incr i 1} {" >> rand-coords.pgn
echo "	set b [format %c \$i]" >> rand-coords.pgn
echo "	lappend seg \$b" >> rand-coords.pgn
echo "}" >> rand-coords.pgn
echo "set i 0" >> rand-coords.pgn
echo "mol load psf $aggfilename.psf" >> rand-coords.pgn
echo "mol addfile $aggfilename-overlaid.pdb" >> rand-coords.pgn
echo "foreach line \$lines {" >> rand-coords.pgn
echo "        if {\$i < [expr $nChains -1]} {" >> rand-coords.pgn
echo "                set words [split \$line "\"'\'t"\"]" >> rand-coords.pgn
echo "                set X [lindex \$words 0]" >> rand-coords.pgn
echo "                set Y [lindex \$words 1]" >> rand-coords.pgn
echo "                set Z [lindex \$words 2]" >> rand-coords.pgn
echo "                set axis [lindex \$words 3]" >> rand-coords.pgn
echo "                set orient [lindex \$words 4]" >> rand-coords.pgn
echo "                set segn [lindex \$seg \$i]" >> rand-coords.pgn
echo "                set sel [atomselect top "\"segname \$segn"\"]" >> rand-coords.pgn
echo "                set movevec [list \$X \$Y \$Z]" >> rand-coords.pgn
echo "                \$sel moveby \$movevec" >> rand-coords.pgn
echo "                \$sel move [transaxis \$axis \$orient]" >> rand-coords.pgn
echo "                incr i 1" >> rand-coords.pgn
echo "        }" >> rand-coords.pgn
echo "}" >> rand-coords.pgn
echo "set all [atomselect top all]" >> rand-coords.pgn
echo "\$all writepdb $aggfilename.pdb" >> rand-coords.pgn
echo "exit" >> rand-coords.pgn

vmd -dispdev text -e rand-coords.pgn
#rm rand-coords.pgn
