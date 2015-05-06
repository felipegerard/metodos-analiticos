Hola Omar!


Instrucciones útiles para usar Git:


******************************************************************************************
**para hacer una nueva carpeta desde la terminal**
******************************************************************************************

mkdir nombre 

******************************************************************************************
**una vez forkeado el proyecto tienes que clonarlo en tu compu**
******************************************************************************************

git clone https://github.com/omisimo/metodos-analiticos.git

******************************************************************************************
** esto nos va a crear una carpeta con toda la informacion llamada 
   metodos-analiticos, por eso necesitamos jalar toda esa informacion 
   a nuestra nueva carpeta que acabamos de crear **
******************************************************************************************
cp -R metodos-analiticos/* Final_MA/
cp -R metodos-analiticos/.* Final_MA/ (nos aseguramos que los archivos .git y .gitignore se encuentren en la informacion copiada)


******************************************************************************************
verificamos que en verdad este toda la información copiada en nuestra nueva carpeta
******************************************************************************************

ls -lah Final_MA


******************************************************************************************
quitamos la carpeta que se descargo al clonar el repositorio, este comando es de mucho cuidado por que puede echar a perder tu compu
******************************************************************************************

rm -Rf metodos-analiticos
ls

******************************************************************************************
nos colocamos en la carpeta creada y con la información guardada en ella
******************************************************************************************

cd Final_MA


******************************************************************************************
Chicanos el status del repositorio, aquí podemos ver las cambios y los commits pendientes
******************************************************************************************

git status

******************************************************************************************
Vemos los repositorios que tengo reverenciados
******************************************************************************************

git remote -v

******************************************************************************************
agregamos el repositorio de felipe para poder jalar los cambios que el haga en el proyecto original y lo guardamos con el nombre de repo-felipe, posteriormente revisamos ahora los repositorios referenciados que tenemos
******************************************************************************************

git remote add repo-felipe https://github.com/felipegerard/metodos-analiticos.git
git remote -v

******************************************************************************************
jalamos la ultima version del repo de felipe
******************************************************************************************

git pull repo-felipe master

******************************************************************************************
trabajamos en nuestro repositorio local y revisamos el status, aquí veremos los untracked archives, que son las modificaciones
******************************************************************************************

git status 

******************************************************************************************
le hacemos add a los archivos que queremos subir y después les haremos commit
******************************************************************************************

git add prueba.txt
git status


******************************************************************************************
le damos commit a los archivos nuevos, es importante siempre incluir un comentario que indique la razón de los cambios o creación d los archivos
******************************************************************************************

git commit -m "prueba con felipe"
git status

******************************************************************************************
subimos la información nueva a mi repositorio en linea, pues todo ha sido hasta este momento de manera local
******************************************************************************************

git push origin master 


******************************************************************************************
una vez subidos los archivos nuevos al repositorio en linea, jalamos la ultima version del repositorio de felipe 
******************************************************************************************

git pull repo-felipe master 

******************************************************************************************
una vez que hayas subido todos los archivos nuevos y modificados a internet, desde la plataforma de github se puede pedir pull request para juntar los archivos nuevos
******************************************************************************************










