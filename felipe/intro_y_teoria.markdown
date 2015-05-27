
0. Introducción
--------------------------

Las colecciones grandes de documentos pueden ser difíciles de aprovechar. Por ejemplo, si queremos que una o varias palabras aparezcan en el documento, podemos hacer un filtro simple. Sin embargo, si las palabras son (razonablemente) comunes, el query nos podría regresar un porcentaje importante de la colección de documentos, sobre todo si son muy largos. Algo más refinado que podríamos hacer sería por ejemplo usar el número de veces que aparecen las palabras deseadas, aunque esto favorecería documentos extensos y las palabras comunes.

En el presente trabajo minaremos una [colección de _abstracts_](https://archive.ics.uci.edu/ml/datasets/NSF+Research+Award+Abstracts+1990-2003) de 129,000 artículos  ganadores de premios de la National Science Foundation (NSF) entre 1990 y 2003. El conjunto de datos está interesante porque provee las versiones cortas de los artículos, de modo que podemos leerlos y darnos una idea rápida de lo que trata cada artículo. En la página estaba la información en crudo (.txt) y ya lista para utilizar el método de bolsa de palabras. Preferimos utilizar la información cruda original para hacer el proceso desde la limpieza de los datos. El objetivo es realizar búsquedas temáticas inteligentes dentro de la colección, es decir, dado un conjunto de palabras clave, queremos obtener los artículos más relevantes. En la siguiente sección describiremos la teoría del método que utilizamos para mitigar los problemas descritos anteriormente.


1. Teoría
--------------------------

Como decíamos arriba, no basta con filtrar los artículos según la aparición de las palabras clave, ni tampoco un conteo simple. Lo que haremos será tomar en cuenta los conteos, pero usaremos técnicas para disminuir la importancia de la longitud de los documentos en cuestión y de la frecuencia de aparición de las palabras comunes.

Denotamos la frecuencia del término $w$ (puede ser una palabra o la raíz de una palabra obtenida con _stemming_) en el documento $d$ como $tf_{w,d}$. De manera natural, denotamos por $tf_d$ al vector de todas las frecuencias de los términos conocidos del documento $d$. Supongamos que queremos comparar los documentos $q$ y $d$. Un primer enfoque que podríamos utilizar sería usar la distancia coseno, que toma en cuenta únicamente la frecuencia relativa de las palabras dentro de los documentos:

$$
d_{coseno}(q,d) = \frac{tf_q \cdot tf_d}{\|tf_q\| \|tf_d\|}
$$

El problema con lo anterior es que las palabras comunes podrían tomar un papel protagónico y en nuestro caso compartir por ejemplo artículos o preposiciones no es muy interesante. Para mitigar esto utilizaremos la frecuencia inversa en documentos $idf_w$, definida para una palabra $w$. Si $N$ es el número total de documentos en la colección y $df_w$ es el número de documentos de la colección que contienen a $w$, entonces definimos la frecuencia inversa de documentos como sigue:

$$
idf_w = log(\frac{N}{df_w}) 
$$

Y entonces, en lugar de describir a $d$ por medio de $tf_d$, lo describimos por medio de $c_d$, donde

$$
c_d,w = idf_w \times tf_d,w
$$

Y así, calculamos la distancia entre dos documentos como la distancia coseno entre sus vectores característicos:

$$
d(q,d) = \frac{c_q \cdot c_d}{\|c_q\| \|c_d\|}
$$

La $idf_w$ es el logaritmo del inverso de la probabilidad de que el término $w$ aparezca en un documento elegido al azar. El efecto que esto tiene es que las palabras comunes casi no tendrán ningún efecto en la distancia, puesto que su probabilidad es cercana a 1 y por lo tanto su $idf$ es cercana a cero. Por el contrario, las palabras raras tendrán una probabilidad cercana a 0, por lo que su $idf$ será grande y contribuirán mucho. La razón detrás de hacer esto es que queremos que discriminen las palabras especiales o específicas a un contexto y no las genéricas. El esquema expuesto está escrito con mayor detalle en el libro [Mining of Massive Datasets](http://www.mmds.org), con el detalle de que ahí además normalizan $tf_w$ por la máxima frecuencia obtenida por el término en la colección de documentos.

