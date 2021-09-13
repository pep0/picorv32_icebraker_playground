#!/usr/bin/env python
"""
lut_gen.py is a cli utility that generates waveform lookup tables
"""
import argparse
import numpy as np

#https://stackoverflow.com/questions/7822956/how-to-convert-negative-integer-value-to-hex-in-python
def tohex(val, nbits):
    return '{:04X}'.format(((val + (1 << nbits)) % (1 << nbits)))

def sin_lut(width:int, depth:int, scale=0.76)->list:
	X = np.linspace(0, np.pi/2, num=2**depth, endpoint=True)
	Y = np.sin(X)
	max_amplitude = 2**(width-1)*scale
	Y = Y*max_amplitude

	hex_list = []

	for y_elm in Y:

		
            hex_list.append('{}'.format(tohex(int(y_elm), width)).replace('0x',''))
	
	return hex_list	


if __name__ == '__main__':
	parser = argparse.ArgumentParser(description='lut_gen.py is a cli utility that generates waveform lookup tables')
	

	parser.add_argument('width',type=int, action='store', help='bit width of lut elements')
	parser.add_argument('depth',type=int, action='store', help='depth of address lines of lut elements')
	args = parser.parse_args()

	sin_lut_list = sin_lut(int(args.width), int(args.depth))
	file_name = 'lut_sin_{}w_{}d.hex'.format(args.width, args.depth)
	
	print('generate: {}'.format(file_name))
	with open(file_name, 'w') as writer:
		for hex_elm in sin_lut_list:
			writer.write(hex_elm + '\n')	
