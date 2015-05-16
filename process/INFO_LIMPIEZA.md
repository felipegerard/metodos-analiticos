
Limpieza del diccionario conseguido en Gutenberg
===================================================

0. Descripción del proceso
----------------------------

La limpieza de los datos consiste en los siguientes pasos:

1. Conversión de texto a JSON simple. Lo hicimos en _bash_ (`txt_2_json.sh`):
    {
	"PALABRA 1":{"TEXTO RELACIONADO"},
	"PALABRA 2":{"TEXTO RELACIONADO"},
	...
    }

2. Conversión de JSON simple a JSON estructurado con la información clasificada en _Python_ (`jsonsimple2jsonstruct.py`):
    {
	"PALABRA 1":{
	    "1":{
		"Def":"Definición 1 de la palabra
		"Field":"Campo en el que la definición es válida"
	    },
	    "2":{
		"Def":"Definición 2 de la palabra
		"Field":"Campo en el que la definición es válida"
	    },
	    ...,
	    "Raw":"TEXTO RELACIONADO COMPLETO",
	    "Metadata": {
		"Other":"OTRA INFORMACIÓN SOBRE LA PALABRA",
		"Type":"ARTÍCULO, VERBO, ADJETIVO, ETC",
		"Pronun":"PRONUNCIACIÓN DE LA PALABRA"
	    },
	...
    }
3. Conversión de JSON estructurado a un data.frame de R para el análisis en _R_ (`json2dataframe.R`):


1. Texto --> JSON simple
--------------------------------

El primer paso es sustituir los signos de puntuación y los saltos de línea en caracteres manejables. El fin de esto es que no afecten los JSON ni generen resultados raros. Usando los comandos `tr` y `sed` convertimos los saltos de línea en " <br> ", los puntos por "<punto>", etc.

Ya teniendo la puntuación resuelta, nos dimos cuenta de que las entradas del diccionario vienen en mayúsculas, lo que nos permitió distinguir las palabras (ie. la clave) del texto asociado a ellas. Utilizando más `sed` y `awk` convertimos el input en la estructura de JSON simple con las palabras como llave y todo su texto asociado como valor.

El uso del archivo `txt_2_json.sh` es `cat archivo.txt | txt_2_json.sh`, y arroja el JSON simple al stdout.


2. JSON simple --> JSON estructurado
---------------------------------------

Utilizando `jsonsimple2jsonstruct.py` leemos el JSON generado en la etapa anterior a _Python_, en formato de diccionario. Tuvimos que tener mucho cuidado con el encoding del texto, puesto que contenía muchos caracteres especiales problemáticos que nos dieron muchos problemas (acentos raros, letras escandinavas, etc). Al final optamos por usar ASCII.

Ya con el diccionario en _Python_ reinsertamos la puntuación adecuada y luego hicimos un programa que separa el texto de las entradas en sus diversas partes. Como el texto del diccionario original no era 100% estándar, no todos los campos se leyeron bien en todos los casos. Por ejemplo el tipo de palabra nos dio muchos problemas. Sin embargo, las definiciones (incluso cuando había más de una) y la pronunciación resultaron ser de bastante calidad. El tema es que algunas palabras tienen entradas adicionales como sinónimos o diferencias en el formato que hacen virtualmente imposible leeros todos de manera correcta.

A pesar de las dificultades, logramos obtener un diccionario razonablemente limpio que exportamos a JSON para procesarlo en la siguiente etapa.


3. JSON --> data.frame
--------------------------------------

Finalmente, dado que íbamos a hacer el análisis y la aplicación en _R_, tuvimos que pasar la información a un `data.frame`. La decisión de tomar estas desviaciones y no usar _R_ de entrada es que _bash_ es excelente para procesar texto en masa y que la información tenía una estructura que naturalmente se puede expresar como un JSON. Pensamos que tal vez habría sido confuso hacer el proceso directamente en _R_.

Hay manera de leer JSON directamente a _R_, en forma de listas anidadas. Sin embargo, esta estructura es difícil de explotar. Hicimos una serie de funciones pequeñas que convierten las listas anidadas en un `data.frame` explotable por nuestro algoritmo. Cabe mencionar que como _R_ es más lento, en especial en procesos iterativos no vectorizados, utilizamos la función `mclapply` del paquete `parallel` para acelerar el procesamiento.



Ejemplo
----------

### 1. Texto original: 

...
ABSOLVABLE
Ab*solv"a*ble, a.

Defn: That may be absolved.

ABSOLVATORY
Ab*solv"a*to*ry, a.

Defn: Conferring absolution; absolutory.

ABSOLVE
Ab*solve" (#; 277), v. t. [imp. & p. p. Absolved; p. pr. & vb. n.
Absolving.] Etym: [L. absolvere to set free, to absolve; ab + solvere
to loose. See Assoil, Solve.]

1. To set free, or release, as from some obligation, debt, or
responsibility, or from the consequences of guilt or such ties as it
would be sin or guilt to violate; to pronounce free; as, to absolve a
subject from his allegiance; to absolve an offender, which amounts to
an acquittal and remission of his punishment.
Halifax was absolved by a majority of fourteen. Macaulay.

2. To free from a penalty; to pardon; to remit (a sin); -- said of
the sin or guilt.
In his name I absolve your perjury. Gibbon.

3. To finish; to accomplish. [Obs.]
The work begun, how soon absolved. Milton.

4. To resolve or explain. [Obs.] "We shall not absolve the doubt."
Sir T. Browne.
...

### 2. JSON simple
{
...,
"ABSOLVABLE":"Ab<asterisco>solv<comillas_dobles>a<asterisco>ble<coma> a<punto> <br> <br> Defn<dos_puntos> That may be absolved<punto>",
"ABSOLVATORY":"Ab<asterisco>solv<comillas_dobles>a<asterisco>to<asterisco>ry<coma> a<punto> <br> <br> Defn<dos_puntos> Conferring absolution<punto_coma> absolutory<punto>",
"ABSOLVE":"Ab<asterisco>solve<comillas_dobles> <abre_parent><gato><punto_coma> 277<cierra_parent><coma> v<punto> t<punto> <abre_corchetes>imp<punto> <ampersand> p<punto> p<punto> Absolved<punto_coma> p<punto> pr<punto> <ampersand> vb<punto> n<punto> <br> Absolving<punto><cierra_corchetes> Etym<dos_puntos> <abre_corchetes>L<punto> absolvere to set free<coma> to absolve<punto_coma> ab  solvere <br> to loose<punto> See Assoil<coma> Solve<punto><cierra_corchetes> <br> <br> 1<punto> To set free<coma> or release<coma> as from some obligation<coma> debt<coma> or <br> responsibility<coma> or from the consequences of guilt or such ties as it <br> would be sin or guilt to violate<punto_coma> to pronounce free<punto_coma> as<coma> to absolve a <br> subject from his allegiance<punto_coma> to absolve an offender<coma> which amounts to <br> an acquittal and remission of his punishment<punto> <br> Halifax was absolved by a majority of fourteen<punto> Macaulay<punto> <br> <br> 2<punto> To free from a penalty<punto_coma> to pardon<punto_coma> to remit <abre_parent>a sin<cierra_parent><punto_coma> <guion><guion> said of <br> the sin or guilt<punto> <br> In his name I absolve your perjury<punto> Gibbon<punto> <br> <br> 3<punto> To finish<punto_coma> to accomplish<punto> <abre_corchetes>Obs<punto><cierra_corchetes> <br> The work begun<coma> how soon absolved<punto> Milton<punto> <br> <br> 4<punto> To resolve or explain<punto> <abre_corchetes>Obs<punto><cierra_corchetes> <comillas_dobles>We shall not absolve the doubt<punto><comillas_dobles> <br> Sir T<punto> Browne<punto> <br> <br> Syn<punto> <br>  <guion><guion> To Absolve<coma> Exonerate<coma> Acquit<punto> We speak of a man as absolved from <br> something that binds his conscience<coma> or involves the charge of <br> wrongdoing<punto_coma> as<coma> to absolve from allegiance or from the obligation of <br> an oath<coma> or a promise<punto> We speak of a person as exonerated<coma> when he is <br> released from some burden which had rested upon him<punto_coma> as<coma> to exonerate <br> from suspicion<coma> to exonerate from blame or odium<punto> It implies a purely <br> moral acquittal<punto> We speak of a person as acquitted<coma> when a decision <br> has been made in his favor with reference to a specific charge<coma> <br> either by a jury or by disinterested persons<punto_coma> as<coma> he was acquitted of <br> all participation in the crime<punto>",
...
}

### 3. JSON estructurado
{
    ...,
    "absolvable": {
	"1": {
	    "Field": null,
	    "Def": "That may be absolved."
	},
	"Raw": "Ab*solv\"a*ble, a. <br> <br> Defn: That may be absolved.",
	"Metadata": {
	    "Other": "",
	    "Type": "a.",
	    "Pronun": "Ab*solv\"a*ble"
	}
    },
    "absolvatory": {
	"1": {
	    "Field": null,
	    "Def": "Conferring absolution; absolutory."
	},
	"Raw": "Ab*solv\"a*to*ry, a. <br> <br> Defn: Conferring absolution; absolutory.",
	"Metadata": {
	    "Other": "",
	    "Type": "a.",
	    "Pronun": "Ab*solv\"a*to*ry"
	}
    },
    "absolve": {
	"1": {
	    "Field": null,
	    "Def": "To set free, or release, as from some obligation, debt, or <br> responsibility, or from the consequences of guilt or such ties as it <br> would be sin or guilt to violate; to pronounce free; as, to absolve a <br> subject from his allegiance; to absolve an offender, which amounts to <br> an acquittal and remission of his punishment. <br> Halifax was absolved by a majority of fourteen. Macaulay."
	},
	"Raw": "Ab*solve\" (#; 277), v. t. [imp. & p. p. Absolved; p. pr. & vb. n. <br> Absolving.] Etym: [L. absolvere to set free, to absolve; ab  solvere <br> to loose. See Assoil, Solve.] <br> <br> 1. To set free, or release, as from some obligation, debt, or <br> responsibility, or from the consequences of guilt or such ties as it <br> would be sin or guilt to violate; to pronounce free; as, to absolve a <br> subject from his allegiance; to absolve an offender, which amounts to <br> an acquittal and remission of his punishment. <br> Halifax was absolved by a majority of fourteen. Macaulay. <br> <br> 2. To free from a penalty; to pardon; to remit (a sin); -- said of <br> the sin or guilt. <br> In his name I absolve your perjury. Gibbon. <br> <br> 3. To finish; to accomplish. [Obs.] <br> The work begun, how soon absolved. Milton. <br> <br> 4. To resolve or explain. [Obs.] \"We shall not absolve the doubt.\" <br> Sir T. Browne. <br> <br> Syn. <br>  -- To Absolve, Exonerate, Acquit. We speak of a man as absolved from <br> something that binds his conscience, or involves the charge of <br> wrongdoing; as, to absolve from allegiance or from the obligation of <br> an oath, or a promise. We speak of a person as exonerated, when he is <br> released from some burden which had rested upon him; as, to exonerate <br> from suspicion, to exonerate from blame or odium. It implies a purely <br> moral acquittal. We speak of a person as acquitted, when a decision <br> has been made in his favor with reference to a specific charge, <br> either by a jury or by disinterested persons; as, he was acquitted of <br> all participation in the crime.",
	"3": {
	    "Field": null,
	    "Def": "To finish; to accomplish. [Obs.] <br> The work begun, how soon absolved. Milton."
	},
	"2": {
	    "Field": null,
	    "Def": "To free from a penalty; to pardon; to remit (a sin); -- said of <br> the sin or guilt. <br> In his name I absolve your perjury. Gibbon."
	},
	"4": {
	    "Field": null,
	    "Def": "To resolve or explain. [Obs.] \"We shall not absolve the doubt.\" <br> Sir T. Browne."
	},
	"Metadata": {
	    "Other": "277), v. t. [imp. & p. p. Absolved; p. pr. & vb. n. <br> Absolving.] Etym: [L. absolvere to set free, to absolve; ab  solvere <br> to loose. See Assoil, Solve.]",
	    "Type": "(#;",
	    "Pronun": "Ab*solve\" (#; 277)"
	}
    },
    ...
}


### 4. `data.frame`
  |  Word	    Field	Type	Pronun	    id		    Def
  |-----------------------------------------------------------------------
1 |  absolve	    <NA>	<NA>	<NA>		1	    ...
2 |  absolve	    <NA>	<NA>	<NA>		3	    ...
3 |  absolve	    <NA>	<NA>	<NA>		2	    ...
4 |  absolve	    <NA>	<NA>	<NA>		4	    ...
5 |  absolve	    <NA>	(#;	Ab*solve"	Metadata    ...
6 |  absolvatory    <NA>	<NA>	<NA>		1	    ...
7 |  absolvatory    <NA>	a.	Ab*solv"a*to*ry	Metadata    ...
8 |  absolvable	    <NA>	<NA>	<NA>		1	    ...
9 |  absolvable	    <NA>	a.	Ab*solv"a*ble	Metadata    ...
