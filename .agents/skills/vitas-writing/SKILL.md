---
name: vitas-writing
description: MANDATORY whenever you write or revise prose — a document, a README, an ADR, a PR description, a commit body, a comment reply, an email, a report, or a long chat answer. Covers the tics that make text read as machine-written (colons used as conjunctions, em-dash overuse, inflated vocabulary, uniform rhythm, ceremonial openings, hedged non-positions) and the rules that make writing worth reading (say it once, lead with the conclusion, cut filler, take a position, table vs prose). Trigger on "escribe", "redacta", "documenta esto", "revisa el estilo", "esto suena a IA", "quítale los tics", "humaniza esto", "hazlo más corto", "resume", and whenever you are about to produce more than a few paragraphs of prose. Do not write prose without reading this first.
---

# Vitas Writing

**Escribe para que se entienda, no para que suene bien.** Si hay que elegir entre elegancia y claridad, gana claridad siempre.

Esta skill cubre dos cosas distintas que se refuerzan.

La primera son los tics de escritura automática. Un modelo elige, en cada palabra, la continuación más probable, y eso produce prosa fluida y sin fricción que dice menos de lo que ocupa. Queda más densa de leer y más pobre en postura que el equivalente escrito por una persona.

La segunda es redactar bien, que es un problema anterior y más grande. Un texto sin tics pero con relleno, con la conclusión enterrada y con la misma idea dicha tres veces sigue siendo un mal texto.

Dos reglas que mandan sobre el resto:

1. **Un tic no se compensa, se borra.** Cambiar todas las rayas largas por dos puntos no arregla nada. Sustituye una muletilla por otra.
2. **La regla se verifica sobre el texto.** Si no se puede señalar la frase que la incumple, no pertenece acá.

## Alcance

**Aplica a:** documentos, README, ADR, descripciones de PR, cuerpos de commit, respuestas a comentarios, correos, informes, y respuestas de chat de más de unos párrafos.

**No aplica a:** código, comentarios de código, citas literales, texto de terceros que se reproduce, salida de herramientas, ni metadata de disparo. El `description` de una skill se escribe denso en palabras clave a propósito, porque su trabajo es que la skill se active, no que alguien la lea.

**No puede:** cambiar lo que el texto afirma, inventar datos, ni meter erratas o anécdotas falsas para "sonar humano". Un error plantado es una mentira sobre el origen del texto, y además se nota.

---

## 1. Puntuación de adorno

Es el tic más visible, porque se ve antes de leer. Un lector reconoce la silueta de un párrafo lleno de dos puntos y rayas largas sin haber procesado una sola palabra.

| ID | Regla | Mal | Bien |
|---|---|---|---|
| **WRI-PUN-001** | **Los dos puntos anuncian algo que viene después, no explican lo que vino antes.** Usarlos para encajar una causa, una consecuencia o un matiz es reemplazar una conjunción por un signo | "No conviene hacerlo: no va a ser efectivo" | "No conviene hacerlo porque no va a ser efectivo" |
| **WRI-PUN-002** | Si al reemplazar los dos puntos por *porque*, *así que*, una coma o un punto la frase sigue funcionando, sobraban | "El resultado fue claro: nadie lo usó" | "El resultado fue claro. Nadie lo usó" |
| **WRI-PUN-003** | Nunca dos frases seguidas con la misma estructura de dos puntos. Es el patrón que más delata | "El equipo creció: pasó a doce. El costo subió: casi el doble" | "El equipo creció a doce personas y el costo casi se duplicó" |
| **WRI-PUN-004** | Raya larga como signo comodín: máximo una por párrafo. Casi siempre es punto, coma o paréntesis. Se salva cuando la frase ya usa comas para una enumeración y la raya es lo que evita la ambigüedad | "El plan —que nadie revisó— falló" | "El plan falló. Nadie lo había revisado" |
| **WRI-PUN-005** | No se sustituye un signo de adorno por otro. Al quitar una raya larga, la reescritura no puede terminar en dos puntos, y al revés | "El motivo era otro: el presupuesto" | "El motivo era el presupuesto" |
| **WRI-PUN-006** | El paréntesis tampoco es refugio. Si el inciso importa, va en su propia frase; si no importa, se borra | "La migración (que tomó tres meses) terminó" | "La migración terminó. Tomó tres meses" |

### Los tres usos válidos de los dos puntos

1. **Anunciar una enumeración.** *"Faltan tres cosas: el presupuesto, el plazo y el dueño."*
2. **Introducir una cita literal.** *"El informe lo dice así: «no hay línea base»."*
3. **Separar una etiqueta de su valor.** *"Estado: vigente."* Es el uso de tablas y fichas, no el de la prosa.

Fuera de esos tres, la pregunta es qué conjunción se esconde detrás del signo. Casi siempre es *porque*.

---

## 2. Léxico

| ID | Regla | Cómo se verifica |
|---|---|---|
| **WRI-LEX-001** | Cero palabras grandilocuentes que no cambian el significado: *profundizar, intrincado, meticuloso, robusto, integral, impecable, exhaustivo, riguroso, invaluable, crucial, fundamental, clave, potenciar, aprovechar, desbloquear, navegar (un problema), panorama, ecosistema, sinergia, holístico, granular* | Tachar la palabra y releer. Si la frase dice lo mismo, sobraba |
| **WRI-LEX-002** | La palabra común gana. *Utilizar* es *usar*; *realizar* es *hacer*; *implementar* es *hacer* o *poner*; *aproximadamente* es *como*; *previo a* es *antes de* | Sustituir por la corta y ver si se pierde precisión |
| **WRI-LEX-003** | Cero intensificadores de relleno: *sumamente, extremadamente, altamente, verdaderamente, realmente, absolutamente, sin duda* | Borrarlos y comprobar que la frase no cambió |
| **WRI-LEX-004** | El adjetivo de calidad se reemplaza por el dato que lo sostiene, o se borra | "Un proceso eficiente" → "Un proceso con 15% de tiempo de gestión" |
| **WRI-LEX-005** | Estilo nominal a voz activa. El verbo al centro | "Se realizó la optimización del proceso" → "Optimizamos el proceso" |
| **WRI-LEX-006** | **El impersonal no puede esconder a quien decide o ejecuta.** Un *se + verbo* con verbo real no es estilo nominal, y se cuela igual. En una decisión o un compromiso, el sujeto va explícito | "Se implementará la mejora el próximo trimestre" → "El equipo de plataforma implementa la mejora el próximo trimestre" |
| **WRI-LEX-007** | Una palabra por concepto en todo el texto. Alternar sinónimos para "no repetir" es un reflejo escolar que obliga al lector a comprobar si son lo mismo | Listar los términos propios y contar sus variantes |

> El uso de *delve* (*profundizar*), *intricate* y *meticulous* en artículos de PubMed se disparó en el mes exacto del lanzamiento de ChatGPT. No son palabras malas. Son palabras que un modelo elige mucho más que una persona, y su presencia repetida sin que el tema las pida es lo que se nota.

---

## 3. Ritmo

Un texto automático tiene frases de largo parecido y párrafos de tamaño parecido. Esa uniformidad es la señal más difícil de imitar a mano y la más fácil de romper.

Cada regla va con las dos formas de aplicarla. La columna del medio se usa con las manos en el teclado. La de la derecha, releyendo el párrafo terminado. Las reglas de ritmo se saltan cuando solo se enuncian como diagnóstico, porque contar palabras exige un párrafo que todavía no existe.

| ID | Regla | Al escribir | Al revisar |
|---|---|---|---|
| **WRI-RIT-001** | Los largos de frase varían dentro de cada párrafo | Después de una frase larga con subordinadas, la siguiente sale corta. A propósito, no cuando salga | Contar palabras por frase. Si todas caen en un rango de cinco, hay que romperlo |
| **WRI-RIT-002** | Los párrafos no miden todos lo mismo. Uno de una línea es legítimo | Al cerrar un párrafo, mirar el anterior. Si van dos del mismo porte, el próximo cambia | Mirar el bloque de lejos. Si forman ladrillos iguales, está mal |
| **WRI-RIT-003** | Máximo 30 palabras por frase | Si la frase pasó la segunda coma y no cerró, cerrarla ahí. Lo que falta es otra frase | Contar las que pasen de 30 y partirlas |
| **WRI-RIT-004** | Nada de enumerar de a tres por inercia. Si los elementos reales son dos, van dos | Al escribir el tercer elemento, preguntarse si existe o si lo pide la cadencia | Buscar tríadas con el mismo peso: "rápido, eficiente y seguro" |
| **WRI-RIT-005** | Las listas no tienen todas la misma cantidad de ítems ni ítems del mismo largo, salvo que el contenido lo pida | | Comparar las listas entre sí |

---

## 4. Estructura del párrafo

| ID | Regla | Mal | Bien |
|---|---|---|---|
| **WRI-EST-001** | Se empieza por el hecho. Nada de apertura ceremoniosa | "En el dinámico panorama actual, las organizaciones enfrentan…" | "Tres de los cinco equipos no entregaron a tiempo" |
| **WRI-EST-002** | Cero conectores de plantilla al inicio de párrafo: *Además, Adicionalmente, Por otra parte, Asimismo, En resumen, En conclusión, Cabe destacar, Es importante notar, Vale la pena mencionar* | "Además, el costo subió" | "El costo subió" |
| **WRI-EST-003** | Los párrafos se enlazan por contenido. Si uno necesita un conector para pegarse al anterior, el orden está mal | | |
| **WRI-EST-004** | Nada de frase final que reformula el párrafo recién escrito | | Borrarla. Si el párrafo no se entendió, se reescribe el párrafo |
| **WRI-EST-005** | La construcción "no es X, es Y" solo se justifica cuando el lector de verdad esperaba X. Si nadie iba a pensar en X, es una fórmula que infla sin corregir nada, y va directo a la afirmación | "La herramienta no es mala, es limitada" | "La herramienta no cubre el caso de reposición automática" |
| **WRI-EST-006** | Nada de cierre que anuncia lo ya dicho: *En síntesis, Como hemos visto, En definitiva* | | |

---

## 5. Postura

El tic que menos se ve y más cuesta. Un texto automático explica mucho y no se moja. Ofrece el balance en vez del juicio.

| ID | Regla | Mal | Bien |
|---|---|---|---|
| **WRI-POS-001** | Cuando hay evidencia para tomar posición, se toma | "Es importante sopesar las ventajas y desventajas de cada opción" | "La opción B, aunque cuesta 20% más, es la única que no nos deja atados al proveedor" |
| **WRI-POS-002** | La incertidumbre se declara, no se disuelve en matices. Decir *no lo sabemos y esto falta para saberlo* es una postura; enumerar consideraciones no lo es | | |
| **WRI-POS-003** | Cero escapatorias: *si es posible, según corresponda, cuando aplique, idealmente, en la medida de lo posible* | "Se documentará si es posible" | "Se documenta en cada orden. Si no se puede, se registra por qué" |
| **WRI-POS-004** | Cero términos abiertos que no se pueden comprobar: *dar soporte, gestionar, optimizar, entre otros, como mínimo, diversos, varios* | "El sistema gestiona el inventario" | "El sistema registra entradas, salidas y stock actual de cada repuesto" |
| **WRI-POS-005** | Si el texto lo firma una persona, no se le inventa experiencia. Se cita el dato y su fuente | | |
| **WRI-POS-006** | Cero referencias incompletas. Un pronombre o un colectivo que el lector no puede resolver sin releer es un hueco, no un estilo | "Todos coinciden en que el proceso es crítico" | "Los seis operarios de bodega coinciden en que el proceso es crítico" |
| **WRI-POS-007** | Un dato lleva su fuente, aunque sea informal. Un texto entero sin ninguna atribución no se puede discutir, solo creer o no creer | "La rotación subió 20% este año" | "La rotación subió 20% este año, según nómina" |

---

## 6. Densidad: qué se dice y qué se corta

Acá está la mitad que no son tics. Un texto limpio de muletillas pero relleno sigue siendo malo.

| ID | Regla | Cómo se verifica |
|---|---|---|
| **WRI-DEN-001** | **La conclusión va primero.** Después el desarrollo. Cuando no hay una sola conclusión sino varios hallazgos sin jerarquía, la primera línea dice cuántos son y de qué tratan, no los desarrolla | Si hay que leer tres párrafos para saber de qué se trata, el orden está invertido |
| **WRI-DEN-002** | El título dice el hallazgo, no el tema. Un título que solo nombra el asunto obliga a leer el texto para saber si interesa | "Informe sobre el proceso de despacho" → "El despacho tiene tres problemas abiertos" |
| **WRI-DEN-003** | **Una idea por párrafo** | Contar los "además", "también", "por otro lado" dentro del mismo párrafo |
| **WRI-DEN-004** | **Se dice una vez.** Nada de resumen arriba y detalle abajo en el mismo texto. Si el resumen basta, sobra el detalle; si el detalle hace falta, sobra el resumen | ¿Hay dos secciones que dicen lo mismo con distinto zoom? |
| **WRI-DEN-005** | Cero referencias hacia adelante: *esto se explica más abajo*, *lo veremos después*. Si hace falta esa frase, el orden está invertido | Buscar "más abajo", "más adelante", "ver sección", "lo veremos" |
| **WRI-DEN-006** | Un término se define en su primera aparición, ni antes ni después | Leer buscando la primera vez que aparece cada palabra propia |
| **WRI-DEN-007** | El énfasis se usa poco. Máximo dos negritas por párrafo | Si todo está en negrita, nada resalta |
| **WRI-DEN-008** | Tablas para datos comparables, prosa para razonamiento. Una tabla cuya última columna son párrafos debería ser prosa | Mirar la última columna de cada tabla |
| **WRI-DEN-009** | El largo lo fija el propósito, no la sensación de completitud. Un texto que crece se parte o se corta | |
| **WRI-DEN-010** | Cero preámbulo sobre lo que se va a hacer. Se hace | "Voy a explicar tres cosas. Primero…" → empezar por la primera |
| **WRI-DEN-011** | Cero disculpas ni relleno de cortesía que no aporta: *espero que esto ayude*, *no dudes en consultar*, *como se puede apreciar* | Borrarlos y comprobar que no falta nada |

### La prueba del lector escéptico

A cada afirmación central, tres preguntas. Si alguna no tiene respuesta en el mismo párrafo, la frase está incompleta.

1. **¿Comparado con qué?**
2. **¿Cuánto, en qué unidad?**
3. **¿Quién lo mide y con qué dato?**

Una comparación sin las tres se escribe como hipótesis pendiente, no como hecho.

---

## 7. Cómo se revisa

Escribir aplicando las reglas y revisar con ellas son dos pasadas distintas, y las dos hacen falta. Al escribir se evitan los tics locales, que son una decisión palabra por palabra: no pongas ese signo, no uses esa palabra. Al revisar se ven las propiedades del conjunto —ritmo, repetición, orden— que no existen hasta que el párrafo está terminado.

Saltarse la segunda pasada deja un texto sin muletillas y con la conclusión enterrada. Medido: un agente que aplicó la norma mientras escribía dejó cero rayas largas y las mismas cinco frases de más de treinta palabras que tenía sin la norma.

En este orden. Los dos primeros pasos se hacen sin leer el contenido.

1. **Mirar la forma.** Contar dos puntos, rayas largas y paréntesis. Ver si los párrafos son ladrillos del mismo tamaño. Se detecta de lejos y no requiere entender el texto.
2. **Leer en voz alta.** Las aperturas ceremoniosas, los conectores de plantilla y el ritmo uniforme se oyen antes de verse. Si al leer se entra en cadencia de locutor, hay que romperla.
3. **Tachar palabras.** Recorrer buscando las de WRI-LEX-001 y WRI-LEX-003. Tachar cada una y releer. La que no cambia nada, se borra.
4. **Buscar la idea repetida.** Cada afirmación central, ¿aparece en otro lugar del texto? Si sí, uno de los dos sobra.
5. **Buscar la postura.** Por cada afirmación central, preguntar qué decide. Una que no decide nada, o sobra, o le falta el juicio.

---

## 8. Autochequeo antes de entregar

Cada respuesta va con la línea concreta que la sostiene. Responder "sí" sin señalar dónde no cuenta.

1. ¿Cuántos dos puntos hay, y cada uno cae en alguno de los tres usos válidos?
2. ¿Algún párrafo tiene más de una raya larga?
3. ¿Se sustituyó algún signo de adorno por otro en vez de reescribir la frase?
4. ¿Qué párrafo empieza con un conector de plantilla?
5. ¿Cuántas palabras de WRI-LEX-001 quedaron, y qué aporta cada una?
6. ¿Los largos de frase varían dentro de cada párrafo?
7. ¿Hay alguna tríada que en realidad eran dos elementos?
8. ¿La primera línea dice de qué se trata?
9. ¿Alguna idea aparece dos veces?
10. ¿Dónde toma postura el texto? Señalar la frase.
11. **¿Qué párrafo sobra?** Hay que nombrar uno.

> La pregunta 11 está formulada así a propósito. "¿Sobra algo?" se responde que no por defecto. "¿Qué sobra?" obliga a buscar.

---

## 9. Idioma

Español neutro, sin voseo ni modismos de ninguna región. *Refresca*, no *refrescá*. *Puedes*, no *podés*. El texto debe leerse igual para cualquier hispanohablante.

Los identificadores de código, los nombres de archivo y los mensajes de commit van en inglés. Esta skill trata de la prosa, no de eso.

---

## Fuera de alcance

**No cubre evadir detectores de IA.** Esos sistemas funcionan sobre estadística. Miden qué tan predecible es cada palabra y cuánto varía el ritmo, y se equivocan seguido, sobre todo con texto técnico y con autores que no escriben en su lengua materna.

Escribir bien reduce el parecido con la salida de un modelo. Eso es todo lo que esta skill promete. Perseguir un puntaje es perseguir la métrica en vez del resultado.

Tampoco cubre qué decide un documento ni cómo se estructura un conjunto de documentos. Cuando el repositorio tenga su propia guía de documentación, esa manda y esta se aplica después.

---

## Por qué existe

Dos motivos, y el segundo pesa más.

Los tics hacen el texto peor, no solo reconocible. Los dos puntos usados como conjunción obligan al lector a reconstruir la relación lógica que el signo escondió. El léxico inflado alarga sin agregar. El ritmo uniforme cansa. Son costos reales para quien lee, y el parecido con la salida de un modelo es una consecuencia.

El relleno cuesta más que los tics. Un texto puede no tener un solo dos puntos de más y aun así desperdiciar el tiempo de quien lo lee. Basta con enterrar la conclusión en el cuarto párrafo, decir la misma idea de tres formas y cerrar reformulando lo anterior.

Por eso existe la familia WRI-DEN, y por eso el autochequeo termina obligando a nombrar un párrafo que sobra.
