
'''
Permite limpiar detalles que R no entiende
'''

import json

infile = ''
outfile = ''

a = json.load(open(infile))

out_file = open(outfile,'w')
json.dump(dout, out_file, indent=4)
out_file.close()
