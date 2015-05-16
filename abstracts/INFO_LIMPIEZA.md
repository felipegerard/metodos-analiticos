
Limpieza de la colección de abstracts
===================================================

0. Descripción del proceso
----------------------------

La limpieza de los datos consiste en los siguientes pasos:

1. Conversión de archivos de texto a JSON estructurado en _bash_ (`abstract2json.sh`):
    {
	"1":{
	    "Titulo":{"Ejemplo de título"},
	    "Fecha":{"2013-01-02"},
	    "Abstract":{"Ejemplo de abstract"},
	    ...
	    },
	"2":{
	    "Titulo":{"Ejemplo de otro título"},
	    "Fecha":{"2003-03-02"},
	    "Abstract":{"Ejemplo de otro abstract"},
	    ...
	    },
	...
    }
2. Conversión de JSON estructurado a data.frame de R para el análisis en _R_ (`json2dataframe_abstracts.R`):


1. Texto --> JSON
--------------------------------

El primer paso es sustituir los signos de puntuación y los saltos de línea en caracteres manejables. El fin de esto es que no afecten los JSON ni generen resultados raros. Usando los comandos `tr` y `sed` convertimos los saltos de línea en " <br> ", los puntos por "<punto>", etc.

Ya con la puntuación resuelta, pasamos los txt a JSON. Los archivos originales ya venían en un formato razonable similar a JSON, "nombre_de_atributo:descri`ción", así que lo pudimos convertir sin problema agregando las comillas pertinentes, etc. Hubo que tener cuidado con el encoding de los textos y con el hecho de que el formato no era 100% formal. Para esta parte utilizamos sobre todo `sed` y `awk`.


2. JSON --> data.frame
---------------------------------------

Primero nos aseguramos de que el formato sea legible en _R_. Cuando no, utilizamos _Python_ para limpiar el formato. Una vez habiendo leído la lista a _R_ con la librería `jsonlite`, convertimos la lista recursiva a `data.frame`. Para ahorrar tiempo, utilizamos la función `mclapply` del paquete `parallel`. Finalmente, regresamos la puntuación a su forma original para que el texto recuperado sea legible.


Ejemplo
----------

### 1. Texto original: 

Title       : RFLP Patterns as a Measure of Diversity in Small Populations
Type        : Award
NSF Org     : MCB
Latest
Amendment
Date        : May 31,  1990
File        : a9000031

Award Number: 9000031
Award Instr.: Standard Grant
Prgm Manager: Maryanna P. Henkart
MCB  DIV OF MOLECULAR AND CELLULAR BIOSCIENCE
BIO  DIRECT FOR BIOLOGICAL SCIENCES
    Start Date  : June 1,  1990
Expires     : May 31,  1994        (Estimated)
    Expected
    Total Amt.  : $300000             (Estimated)
Investigator: Marcia M. Miller mamiller@coh.org  (Principal Investigator current)
    Sponsor     : Beckman Res Inst Cty Hope
    1500 E. Duarte Road
    Duarte, CA  910103000    /   -

    NSF Program : 1114      CELL BIOLOGY
    Fld Applictn: 0000099   Other Applications NEC
    61        Life Science Biological
    Program Ref : 9285,
    Abstract    :

    Studies of chickens have provided serological and nucleic acid
    probes useful in defining the major histocompatibility complex
    (MHC) in other avian species.  Methods used in detecting genetic
    diversity at loci within the MHC of chickens and mammals will be
    applied to determining the extent of MHC polymorphism within
    small populations of ring-necked pheasants, wild turkeys, cranes,
    Andean condors and other species.  The knowledge and expertise
    gained from working with the MHC of the chicken should make for
    rapid progress in defining the polymorphism of the MHC in these
    species and in detecting the polymorphism of MHC gene pool within
    small wild and captive populations of these birds.

    Genes within the major histocompatibility complex (MHC) are known
    to encode molecules that provide the context for recognition of
    foreign antigens by the immune system.  Whether a given animal is
    able to mount an immune response to the challenge of a pathogen
    is determined, in part, by the allelic makeup of its MHC.  In
    many species, an unusually high degree of polymorphism is
    maintained at multiple loci within the MHC in freely breeding
    populations.  The allelic pool within a population presumably
    provides diversity upon which to draw in the face of
    environmental challenge.  The objective of the proposed research
    is to extend ongoing studies of the MHC of domesticated fowl to
    include avian species experiencing severe reduction in population
    size.  Knowledge of the MHC gene pool within populations and of
    the haplotypes of individual animals may be useful in the
    husbandry of species requiring intervention for their
    preservation.

### 2. JSON
"51758":{
    "Title":"RFLP Patterns as a Measure of Diversity in Small Populations",
    "Date":"May 31<coma> 1990",
    "Award Number":"9000031",
    "Investigator":"Marcia M<punto> Miller mamillercoh<punto>org <abre_parent>Principal Investigator current<cierra_parent>",
    "Sponsor":"Beckman Res Inst Cty Hope<br> 1500 E<punto> Duarte Road<br> Duarte<coma> CA 910103000 <diagonal> <guion><br>",
    "Fld Applictn":"0000099 Other Applications NEC <br> 61 Life Science Biological",
    "Abstract":"<br> <br> Studies of chickens have provided serological and nucleic acid <br> probes useful in defining the major histocompatibility complex <br> <abre_parent>MHC<cierra_parent> in other avian species<punto> Methods used in detecting genetic <br> diversity at loci within the MHC of chickens and mammals will be <br> applied to determining the extent of MHC polymorphism within <br> small populations of ring<guion>necked pheasants<coma> wild turkeys<coma> cranes<coma> <br> Andean condors and other species<punto> The knowledge and expertise <br> gained from working with the MHC of the chicken should make for <br> rapid progress in defining the polymorphism of the MHC in these <br> species and in detecting the polymorphism of MHC gene pool within <br> small wild and captive populations of these birds<punto> <br> <br> Genes within the major histocompatibility complex <abre_parent>MHC<cierra_parent> are known <br> to encode molecules that provide the context for recognition of <br> foreign antigens by the immune system<punto> Whether a given animal is <br> able to mount an immune response to the challenge of a pathogen <br> is determined<coma> in part<coma> by the allelic makeup of its MHC<punto> In <br> many species<coma> an unusually high degree of polymorphism is <br> maintained at multiple loci within the MHC in freely breeding <br> populations<punto> The allelic pool within a population presumably <br> provides diversity upon which to draw in the face of <br> environmental challenge<punto> The objective of the proposed research <br> is to extend ongoing studies of the MHC of domesticated fowl to <br> include avian species experiencing severe reduction in population <br> size<punto> Knowledge of the MHC gene pool within populations and of <br> the haplotypes of individual animals may be useful in the <br> husbandry of species requiring intervention for their <br> preservation<punto><br>"
}

### 3. data.frame

Tiene las columnas del JSON anterior pero en versión y la puntuación en formato normal. No incluimos el ejemplo porque el formato no es práctico.
