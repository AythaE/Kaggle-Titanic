<!--Portada-->

<div class="portada">


# Práctica 1
# Competición en Kaggle sobre Clasificación Binaria
*****

<img src="imgs/ugr.png" alt="Logo UGR" style="width: 200px; height: auto;"/>

<div class="portada-middle">

## Nombre del equipo: **AythaE**
## Ranking: **452** Puntuación: **0.8134**
</br>

### Sistemas Inteligentes para la Gestión en la Empresa
### Máster en Ingeniería Informática
### Curso 2016/17
### Universidad de Granada

</div>

> Nombre: Aythami Estévez Olivas
> Email: <aythae@correo.ugr.es>

</div>

<!-- Salto de página -->
<div style="page-break-before: always;"></div>

## Índice

<!--
Ejemplo de Indice final eliminando el enlace y añadiendo el número de página
- Apartado 1 <span style='float:right'>2</span>
-->

<!-- toc -->

- [1. Exploración de datos](#1-exploracion-de-datos)
  * [1.1. Edad y Sexo](#11-edad-y-sexo)
  * [1.2. Clase social](#12-clase-social)
- [2. Preprocesamiento de datos](#2-preprocesamiento-de-datos)
- [3. Técnicas de clasificación](#3-tecnicas-de-clasificacion)
- [4. Presentación y discusión de resultados](#4-presentacion-y-discusion-de-resultados)
- [5. Conclusiones y trabajos futuros](#5-conclusiones-y-trabajos-futuros)
- [6. Listado de soluciones](#6-listado-de-soluciones)
- [Bibliografía](#bibliografia)

<!-- tocstop -->

<!-- Salto de página -->
<div style="page-break-before: always;"></div>

## 1. Exploración de datos
Una vez cargados los dataset en R lo primero es comprobar que variables contienen, para ello se puede utilizar la función `str(dataset)` que nos da una descripción de la estructura interna de este
```
> str(train)
'data.frame':	891 obs. of  12 variables:
 $ PassengerId: int  1 2 3 4 5 6 7 8 9 10 ...
 $ Survived   : int  0 1 1 1 0 0 0 0 1 1 ...
 $ Pclass     : int  3 1 3 1 3 3 1 3 3 2 ...
 $ Name       : Factor w/ 891 levels "Abbing, Mr. Anthony",..: 109 191 358 277 16 559 520 629 416 581 ...
 $ Sex        : Factor w/ 2 levels "female","male": 2 1 1 1 2 2 2 2 1 1 ...
 $ Age        : num  22 38 26 35 35 NA 54 2 27 14 ...
 $ SibSp      : int  1 1 0 1 0 0 0 3 0 1 ...
 $ Parch      : int  0 0 0 0 0 0 0 1 2 0 ...
 $ Ticket     : Factor w/ 681 levels "110152","110413",..: 525 596 662 50 473 276 86 396 345 133 ...
 $ Fare       : num  7.25 71.28 7.92 53.1 8.05 ...
 $ Cabin      : Factor w/ 148 levels "","A10","A14",..: 1 83 1 57 1 1 131 1 1 1 ...
 $ Embarked   : Factor w/ 4 levels "","C","Q","S": 4 2 4 4 4 3 4 4 4 2 ...
```

Si buscamos la información proporcionada por Kaggle [1] de lo que significa cada variable nos encontramos ante la siguiente tabla

Variable    | Descripción
------------|-------------------------------------
PassengerID | Identificador del pasajero
Survived    | Sobrevivió (1) o murió (0)
Pclass      | Clase del pasaje
Name        | Nombre del pasajero y título
Sex         | Sexo del pasajero
Age         | Edad del pasajero
SibSp       | Número de esposas o hermanos a bordo
Parch       | Número de padres o hijos a bordo
Ticket      | Número del pasaje
Fare        | Tarifa del pasaje
Cabin       | Cabina
Embarked    | Puerto de embarque

El problema a resolver es predecir el valor de la variable "Survived", en un primer análisis de la distribución de valores de esta variable se observa que solo se salvaron el 38,38% de los pasajeros.

```
> prop.table(table(train$Survived))

        0         1
0.6161616 0.3838384
```
Por ello siguiendo [2] como modelo inicial se puede predecir que todos mueren con lo que se consigue un porcentaje de acierto sobre test de 62,679% lo que cuadra con las observaciones realizadas sobre el conjunto de entrenamiento.

### 1.1. Las mujeres y los niños primero
En la sabiduría popular es famosa la frase "Las mujeres y los niños primero" así que resulta lógico buscar como se relacionan la edad y el sexo con las tasas de supervivencia. Si vemos la supervivencia entre hombres y mujeres vemos que es muy diferente salvándose muchas más mujeres:
```
> prop.table(table(train$Sex, train$Survived),1)

                 0         1
  female 0.2579618 0.7420382
  male   0.8110919 0.1889081
```

Esto hace que podamos refinar el modelo inicial prediciendo que todas las mujeres sobrevivirán y que todos los hombres perecerán con lo que se consigue una tasa de acierto del 76,55% sobre test.

Si consideramos como niños a los menores de 18 años, podemos comprobar al cotejar esta variable "Child" con el sexo y la tasa de supervivencia se observa que en el caso de los hombres tienen unas tasas de supervivencia mucho más altas.
```
> aggregate(Survived ~ Child + Sex, data=train, FUN=function(x) {sum(x)/length(x)})
  Child    Sex  Survived
1     0 female 0.7528958
2     1 female 0.6909091
3     0   male 0.1657033
4     1   male 0.3965517
```

A modo de resumen de esto veáse la siguiente gráfica
<img src="imgs/SupervivientesPorEdadYSexo.png" alt="Superviventes por edad y sexo" style="width: 400px; height: auto; display: block; margin: auto;"/>

Por todo ello se deduce que la edad y el sexo tendrán un papel determinante en la supervivencia, habrá que tratar la edad ya que contiene 177 valores perdidos (cerca del 20%).

### 1.2. Clase social
Otro factor que en principio podría ser determinante es la clase social ya que existían profundas diferencias en el pasaje del Titanic. Esto puede venir representado en la clase del billete (variable `Pclass`) o en el precio de este (`Fare`). Si comenzamos analizando la clase del pasaje se observa que obviamente existen muchos menos billetes de 1ª y 2ª clase que de 3ª. Analizando el porcentaje de supervivencia se puede apreciar en la siguiente gráfica como los pasajeros de las clases elevadas tenían más del doble del porcentaje de supervivencia que los de clase 3.

<img src="imgs/PorcentajeSupervivenciaPclass.png" alt="Porcentaje de supervivencia por clase" style="width: 300px; height: auto; display: block; margin: auto;"/>

Si pasamos a analizar el precio del pasaje se observan profundas diferencias con precios por debajo de 10 hasta los 500. Al ser un atributo continuo con una gran cantidad de valores lo discretizo en 4 valores: <10, 10-20, 20-30, 30+. Una vez hecho esto analizamos los porcentajes de supervivencia observando como se incrementan las posibilidades de sobrevivir cuando más se haya pagado por el pasaje, lo que cuadra con las observaciones realizadas sobre la variable `Pclass`.
```
> prop.table(table(train$FareDiscrete, train$Survived),1)

                0         1
  <10   0.8005952 0.1994048
  10-20 0.5754190 0.4245810
  20-30 0.5735294 0.4264706
  30+   0.4125000 0.5875000
```

### 1.3. Uniendo ambos criterios
Si representamos las tasas de supervivencia respecto al sexo, la clase del pasaje y el dinero pagado por este obtenemos la siguiente tabla de la que cabe destacar las filas 8 y 9 (destacadas con ##) las cuales rompen la tendencia en las mujeres que establece que todas sobreviven, si son de 3ª clase y han pagado más de 20 por su pasaje tienen unas altas probabilidades de morir.

```
> aggregate(Survived ~ FareDiscrete + Pclass + Sex, data=train, FUN=function(x) {sum(x)/length(x)})
   FareDiscrete Pclass    Sex  Survived
1         20-30      1 female 0.8333333
2           30+      1 female 0.9772727
3         10-20      2 female 0.9142857
4         20-30      2 female 0.9000000
5           30+      2 female 1.0000000
6           <10      3 female 0.5937500
7         10-20      3 female 0.5813953
8         20-30      3 female 0.3333333 ##
9           30+      3 female 0.1250000 ##
10          <10      1   male 0.0000000
11        20-30      1   male 0.4000000
12          30+      1   male 0.3837209
13          <10      2   male 0.0000000
14        10-20      2   male 0.1587302
15        20-30      2   male 0.1600000
16          30+      2   male 0.2142857
17          <10      3   male 0.1115385
18        10-20      3   male 0.2368421
19        20-30      3   male 0.1250000
20          30+      3   male 0.2400000
```
Si asumimos que este comportamiento se dará también en el conjunto de test llegamos a crear un modelo con un 77,99% de acierto.

Si además de esto añadimos la variable `Child`, que recordemos es una variable binaria con valor 1 para los menores de 18 años, llegamos a la siguiente tabla. A las conclusiones previas podemos añadir que los niños masculinos se salvan en su mayoría con la excepción de los de clase 3 que han pagado menos de 10 o más de 20
```
> aggregate(Survived ~ FareDiscrete + Pclass + Child+ Sex, data=train, FUN=function(x) {sum(x)/length(x)})
   FareDiscrete Pclass Child    Sex   Survived
1         20-30      1     0 female 0.83333333
2           30+      1     0 female 0.98750000
3         10-20      2     0 female 0.90625000
4         20-30      2     0 female 0.88000000
5           30+      2     0 female 1.00000000
6           <10      3     0 female 0.56140351
7         10-20      3     0 female 0.50000000
8         20-30      3     0 female 0.40000000
9           30+      3     0 female 0.11111111
10          30+      1     1 female 0.87500000
11        10-20      2     1 female 1.00000000
12        20-30      2     1 female 1.00000000
13          30+      2     1 female 1.00000000
14          <10      3     1 female 0.85714286
15        10-20      3     1 female 0.73333333
16        20-30      3     1 female 0.16666667
17          30+      3     1 female 0.14285714
18          <10      1     0   male 0.00000000
19        20-30      1     0   male 0.40000000
20          30+      1     0   male 0.35365854
21          <10      2     0   male 0.00000000
22        10-20      2     0   male 0.11864407
23        20-30      2     0   male 0.04761905
24          30+      2     0   male 0.00000000
25          <10      3     0   male 0.10931174
26        10-20      3     0   male 0.12903226
27        20-30      3     0   male 0.07142857
28          30+      3     0   male 0.41666667
29          30+      1     1   male 1.00000000
30        10-20      2     1   male 0.75000000
31        20-30      2     1   male 0.75000000
32          30+      2     1   male 1.00000000
33          <10      3     1   male 0.15384615 ##
34        10-20      3     1   male 0.71428571
35        20-30      3     1   male 0.20000000 ##
36          30+      3     1   male 0.07692308 ##
```
Con esto podemos construir otro modelo que obtiene la misma puntuación que el previo por lo que probablemente las conclusiones extraídas sobre el conjunto de entrenamiento no sean directamente aplicables por ser demasiado adaptadas a este, encontrándonoos ante un problema de "sobreentrenamiento".

<!-- Salto de página -->
<div style="page-break-before: always;"></div>

### 1.4. Otras variables
La variable `PassengerID` corresponde a un identificador único del pasajero por lo que no aportaría nada a predecir su supervivencia o no. Respecto al atributo `Name` en principio podría parecer que nos encontramos ante un caso similar, pero este no solo contiene el nombre del pasajero si no su titulo social (Mr para hombre casado, Master para soltero,...) y esta demuestra ser una información muy importante como comentaré en el siguiente apartado. Por acabar con los atributos de identificación el atributo `Ticket` corresponde a un identificador del billete por lo que no lo usaré por idénticos motivos.

Los atributos `SibSp` y `Parch` dan una idea del tamaño de la familia que se encuentra a bordo del barco lo cual puede ser útil para determinan la supervivencia o no de las diferentes familias como se explicará en el siguiente apartado.

El atributo `Cabin` podría ser interesante conociendo la posición de los camarotes del barco pero tiene un total de 687 valores perdidos de 891 lo que imposibilita usarlo en la práctica.

El atributo `Embarked` podría ser interesante a priori si observamos los porcentajes de supervivencia donde Cherbourg destaca por encima de todos, mencionar que la primer fila corresponde a 2 valores perdidos de este atributo.
```
> prop.table(table(train$Embarked, train$Survived),1)

            0         1
    0.0000000 1.0000000
  C 0.4464286 0.5535714
  Q 0.6103896 0.3896104
  S 0.6630435 0.3369565
```
Que los pasajeros que han embarcado en una localización tengan más probabilidades de sobrevivir no parece tener sentido, sin embargo si analizamos la distribución de clases de los pasajeros embarcados en un lugar u otro nos encontramos que algo más de la mitad de los pasajeros que embarcaron en Cherbourg pertenecen a la 1ª clase lo que podría explicar su mayor tasa de supervivencia [3].

<img src="imgs/PorcentajePclassEmbarked.png" alt="Distribución de clases por puerto de embarque" style="width: 300px; height: auto; display: block; margin: auto;"/>


## 2. Preprocesamiento de datos
### 2.1. Integración y detección de conflictos e inconsistencias en los datos: valores perdidos, valores fuera de rango, ruido, etc.
### 2.2. Transformaciones: normalizacion, agregacion, generacion de caracterısticas adicionales, etc.
### 2.3. Reduccion de datos: tecnicas utilizadas para seleccion de caracterısticas, seleccion de ejemplos, discretizacion, agrupacion de valores, etc.

## 3. Técnicas de clasificación
### 3.1. Árbol de decisión simple
### 3.2. Random Forest
### 3.3. CForest

## 4. Presentación y discusión de resultados
Grafica arbol inicial.
Grafica importancia.

Comentar prueba final toqueteando parametros que no lleva a ningun lado, habria que profundizar
## 5. Conclusiones y trabajos futuros
Falta de tiempo

Xgboost pero tal cual parece dar problemas, probar tecnicas que le vayan bien como Smote

Seguir preprocesamiento de [3] y toquetear los parámetros de clasificador
<!-- Salto de página -->
<div style="page-break-before: always;"></div>

## 6. Listado de soluciones
La siguiente tabla recoge las distintas soluciones presentadas en Kaggle, tengo que mencionar inicialmente que son 11 filas en lugar de 12 a pesar de ser estos mis intentos en Kaggle. Esto se debe a que he subido la solución 3 dos veces debido a que se produjo un error durante la subida y lo volví a subir, por esto no la menciono en la tabla. Respecto a las posiciones del ranking son algo aproximadas ya que seleccionando una entrega como solución final no varia el ranking de Kaggle, por lo que he aproximado a las posiciones ocupadas por puntuaciones idénticas. Como software utilizado para todos los intentos se ha utilizado RStudio y los paquetes y funciones indicadas en la lista de abreviaturas.
La siguiente lista de abreviaturas por orden alfabético recoge los preprocesamientos y algoritmos utilizados para las distintas soluciones:
- AD1: Árbol de decisión usando el paquete y función `rpart` con el método "class" prediciendo la variable Survived usando Pclass, Sex, Age, SibSp, Parch, Fare y Embarked.
- AD2: Árbol de decisión usando el paquete y función `rpart` con el método "class" prediciendo la variable Survived usando Pclass, Sex, Age, SibSp, Parch, Fare, Embarked, Title, FamilySize y FamilyID.
- CRF: Random Forest usando como unidad elemental conditional inference trees con la función `cforest` del paquete `party`, 2000 árboles y 3 variables aleatorias a elegir en cada nodo. Predice en función de Pclass, Sex, Age, SibSp, Parch, Fare, Embarked, Title, FamilySize y FamilyID.
- CRFDS: Igual algoritmo que el previo pero creando dos modelos separados para hombres y mujeres, prediciendo hombres y mujeres por separado y luego uniendo los resultados.
- HM: Todos los hombres mueren.
- MSP3: Todas las mujeres se salvan menos las de la clase P3 que pagaron más de 20 por su billete.
- MSP3 + NHP3: Todas las mujeres se salvan menos las de la clase P3 que pagaron más de 20 por su billete y además todos los niños (menores de 18 años) hombres se salvan a expción de los de clase P3 que pagaron menos de 10 o más de 20.
- NA: Nada de preprocesamiento.
- RF: Random Forest del paquete homónimo con 2000 árboles prediciendo a partir de Pclass, Sex, Age, SibSp, Parch, Fare, Embarked, Title, FamilySize y FamilyID2 (como Family ID pero considerando familia grande las de más de 3 miembros).
- TFSFID: Extracción del título social a partir del nombre, cálculo del tamaño de la familia en función de SibSp y Parch, además de generación de un ID de familias grandes (+ de 2 miembros).
- TFSFID + IEEF: Mismo preprocesamiento que el previo pero añadiendo imputación de la edad usando un árbol de regresión Anova a partir de Pclass, Sex, SibSp, Parch, Fare, Embarked, Title y FamilySize; imputación de los datos perdidos de embarque por el puerto más numeroso ("S") y de los datos perdidos del precio del pasaje por la mediana de su distribución.
- TFSFID2 + IEEF: Igual que lo anterior pero discretizando el tamaño de familia en "single" si < 2, "small" si > 1 y < 5 y "large" si > 4.
- TFSFID3 + IEEF: Igual preprocesamiento pero agrupando los títulos de manera distinta, considerando familia grande la que tiene 2 o más miembros y realizando la imputación de la edad usando el paquete `mice` y el método `rf`.
- TM: Como "algoritmo" se asume que todos mueren.


Nº de solución | Descripción Preprocesamiento | Algoritmos y Software | % Acierto en entrenamiento | % Acierto en test | Posición del Ranking
---------------|------------------------------|-----------------------|----------------------------|-------------------|---------------------
1              | NA                           | TM                    | 61,61616                   | 62,679            | 13022 17/04
2              | NA                           | HM                    | 78,675                     | 76,555            | 7742 18/04
3              | NA                           | MSP3                  | 80,8                       | 77,99             | 4928 19/04
4              | NA                           | MSP3 + NHP3           | 82,379                     | 77,99             | 4928 19/04
5              | NA                           | AD1                   | 83,951                     | 78,469            | 3525 21/04
6              | TFSFID                       | AD2                   | 85,522                     | 79,426            | 1945 21/04
7              | TFSFID + IEEF                | RF                    | 92,817                     | 77,512            | 5997 22/04
**8**          | **TFSFID + IEEF**            | **CRF**               | **85,634**                 | **81,34**         | **452 22/04**
9              | TFSFID2 + IEEF               | CRF                   | 85,634                     | 80,383            | 819 22/04
10             | TFSFID3 + IEEF               | CRF                   | 87,205                     | 80,383            | 819 22/04
11             | TFSFID + IEEF                | CRFDS                 | 85,185                     | 81,34             | 452 22/04

<!-- Salto de página -->
<div style="page-break-before: always;"></div>

## Bibliografía

<p id="1">

[1]: Kaggle (n.d). Titanic: Machine Learning from Disaster. Recuperado el 25 de Abril de 2017, desde <https://www.kaggle.com/c/titanic/>

</p>

<p id="2">

[2]: T. Stephens (n.d). Titanic: Getting Started with R. Recuperado el 25 de Abril de 2017, desde <http://trevorstephens.com/kaggle-titanic-tutorial/getting-started-with-r/>

</p>

<p id="3">

[3]: Z. Kremonic (n.d). Titanic Random Forest: 82.78%. Recuperado el 25 de Abril de 2017, desde <https://www.kaggle.com/zlatankr/titanic/titanic-random-forest-82-78/run/806902>

</p>

<p id="4">

[4]: M.L. Risdal (2016). Exploring the Titanic Dataset. Recuperado el 25 de Abril de 2017, desde <https://www.kaggle.io/svf/924638/c05c7b2409e224c760cdfb527a8dcfc4/__results__.html>

</p>
