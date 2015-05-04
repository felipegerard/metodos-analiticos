import json
import pprint
import re

class langDict(dict):
    def __init__(self, *args, **kwargs):
	dict.__init__(self, *args, **kwargs)
	pprint = __import__('pprint')
    def __str__(self):
	return pprint.pformat({k:v for k,v in self.iteritems() if k != 'Raw'})

print langDict({1:'aasdf as df sad fsa df sad fsad fas dfjksadfjksd sdkf kjasd fkasd faskd fkas',3:'sdfasd fsad fasdf asdfasfasdf asdfasdf asdfasfasfcxcvzxzvxvxvx',4:'dghfg fsa df asd fsa df sad fas df sd f asdf sd  dsf g dfg df g', 'Raw':'jojojo'})


def esc2punct(s):
    s = re.sub('<punto>','.',s)
    s = re.sub('<coma>',',',s)
    s = re.sub('<dos_puntos>',':',s)
    s = re.sub('<punto_coma>',';',s)
    s = re.sub('<asterisco>','*',s)
    s = re.sub('<comillas_dobles>','"',s)
    s = re.sub('<comillas_simples>',"'",s)
    s = re.sub('<backtick>','`',s)
    s = re.sub('<gato>','#',s)
    s = re.sub('<porcentaje>','%',s)
    s = re.sub('<abre_corchetes>','[',s)
    s = re.sub('<cierra_corchetes>',']',s)
    s = re.sub('<abre_parent>','(',s)
    s = re.sub('<cierra_parent>',')',s)
    s = re.sub('<guion>','-',s)
    s = re.sub('<ampersand>','&',s)
    s = re.sub('<diagonal>','/',s)
    return s


def record2json(rec):
    di = langDict({})
    try:
	prev = None
	for s in rec.split(' <br> <br> '):
	    #print s
	    if prev == None:
		di['Metadata'] = {'Meta':s}
		prev = '0' 
	    elif prev == '0':
		if s[0].isdigit():
		    di[s[0]] = {'Def':s[3:], 'Field':None}
		    prev = s[0]
		elif s[:4] == 'Defn':
		    di['1'] = {'Def':s[6:], 'Field':None}
		    prev = '0' # break?
	    elif int(prev) > 0:
		if s[0].isdigit():
		    di[s[0]] = {'Def':s[3:], 'Field':None}
		    prev = s[0]
		elif s[:4] == 'Defn':
		    di[prev] = {'Def':s[6:], 'Field':di[prev]['Def'][1:-1]}
		    prev = '0'
	m = di['Metadata']['Meta']
	di['Metadata'] = {'Pronun':m.split(',')[0], 'Type':m.split(' ')[1]}
	if len(m.split(' ')) >= 2:
	    di['Metadata']['Other'] = ' '.join(m.split(' ')[2:])
    except IndexError:
	di = {'IndexError':':('}
    di['Raw'] = rec
    return di

pprint.pprint(record2json(d['ACTION']))

d = langDict({esc2punct(k.encode('ascii','ignore')):esc2punct(v.encode('ascii','replace')) for k,v in
     json.load(open('gutenberg_dictionary_raw.json')).iteritems()})

dout = {k.lower():record2json(v) for k,v in d.iteritems()}

pprint.pprint(dout['general'])


out_file = open('gutenberg_dictionary_clean.json','w')
json.dump(dout, out_file, indent=4)                  
out_file.close()








