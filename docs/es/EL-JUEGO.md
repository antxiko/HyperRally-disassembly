# El juego

Hyper Rally es una carrera de rally vista por detrás del coche, por una
carretera dibujada en falso 3D. Conduces un coche a lo largo de **doce etapas**,
cada una con su decorado: día, túnel, nieve, un desierto donde suben tres
pirámides según te acercas al final, una tormenta que echa rayos y **dos que se
corren de noche** bajo un campo de estrellas en marcha.

## El salpicadero

Bajo la carretera hay un salpicadero que el código refresca cada cuadro:

- un **cuentakilómetros** en km/h (lo pinta 0x69E7 desde la velocidad de 0xE085),
- una **aguja de gasolina** que baja según avanzas (0x6A49) y parpadea un aviso
  cuando queda poca (0x6AA9),
- un **indicador de marcha** que cambia con la velocidad (0x6ACF),
- un **reloj** que sube en BCD (0x6B0E), y
- un **RANK**, tu puesto en la carrera, que empieza en 680 (0x435A) y se mueve
  un puesto cada vez que un rival te cruza a tu altura (0x6B7D).

## Conducir

El volante sale de 0x6643, el acelerador y el freno de 0x6940. El coche son seis
sprites (plantilla en 0x66E2) que 0x65FA desliza en horizontal según giras. Los
coches rivales suben por la carretera; chocar con uno parte tu velocidad por la
mitad (0x7F89, que recorre esas mismas tres fichas de rival).

## El rally

El número de etapa vive en 0xE060 y va de 1 a doce. Llegar al final del trazado
de una etapa la avanza; en la trece se acaba el rally. Cada etapa carga además
su parámetro en 0xE061, y es él quien decide si el coche derrapa, si el cielo
lleva estrellas y si caen rayos.
