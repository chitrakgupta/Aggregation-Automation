#!/usr/bin/python

# This code generates random configurations for a system of pHLIPS (to study aggregation)
# Number of pHLIPs will be passed as argument
# Assume that PDB already exists with multiple pHLIPs overlaid on each other. All but one of them have to be moved randomly.
# This code will generate random coordinates, which shall then be used in VMD

import random
import math
from sys import argv

f = open("RandomCoords.rnd","w")
n=int(argv[1])
# Loop over all pHLIPs

Rand=[]
for i in range(1,n):
# Generate 4 random numbers
	Rand1 = random.random()
	Rand2 = random.random()
	Rand3 = random.random()
	Rand4 = random.random()


# Generate r, theta, phi vectors from these numbers
	rVect = 40 * Rand1		# A random number between 0 and 40
	thetaVect = 180 * Rand2		# A random number between 0 and 180
	phiVect = 360 * Rand3		# A random number between 0 and 360
	orientVect = 360 * Rand4	# A random number between 0 and 360

# Convert theta and phi to radians
	thetaVectRad = math.pi * thetaVect/180.
	phiVectRad = math.pi * phiVect/180.

# Convert r, theta, phi to X, Y, Z
	xVect = rVect * math.sin(thetaVectRad) * math.cos(phiVectRad)
	yVect = rVect * math.sin(thetaVectRad) * math.sin(thetaVectRad)
	zVect = rVect * math.cos(thetaVectRad)

# Generate integer to determine axis of rotation
	axisCode = random.randint(1,3)
	if axisCode == 1:
		axis = "x"
	elif axisCode == 2:
		axis = "y"
	elif axisCode == 3:
		axis = "z"

	out = str(xVect) + "\t" + str(yVect) + "\t" + str(zVect) + "\t" + axis + "\t" + str(orientVect) + "\n"

	f.write(out)

f.close()
