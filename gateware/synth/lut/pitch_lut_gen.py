#!/usr/bin/env python
"""
pitch_lut_gen.py is a cli utility that generates waveform lookup tables
"""
import argparse
import numpy as np

#https://stackoverflow.com/questions/7822956/how-to-convert-negative-integer-value-to-hex-in-python
def tohex(val, nbits):
	return '{:04X}'.format(((val + (1 << nbits)) % (1 << nbits)))

def gen_pitch_lut():
	CLOCK_FREQ = 12000000
	N_COUNTER = 28
	WIDTH = 16

	X = np.arange(0,128,1, dtype=float)
	Y = 2**((X-69)/12)*440 * (2**(N_COUNTER)/CLOCK_FREQ)
	Y = np.around(Y)
	Y = Y.astype(int)
	y_to_large_mask = Y > 2**WIDTH-1
	Y[y_to_large_mask] = 2**WIDTH-1
	hex_list = []

	for y_elm in Y:

		hex_list.append('{}'.format(tohex(int(y_elm), WIDTH)).replace('0x',''))

	
	return hex_list	


if __name__ == '__main__':
	parser = argparse.ArgumentParser(description='pitch_gen.py is a cli utility that generates midi frequencies lookup tables')
	

	args = parser.parse_args()

	pitch_list = gen_pitch_lut()

	
	file_name = 'lut_pitch.hex'
	
	print('generate: {}'.format(file_name))
	with open(file_name, 'w') as writer:
		for hex_elm in pitch_list:
			writer.write(hex_elm + '\n')	
