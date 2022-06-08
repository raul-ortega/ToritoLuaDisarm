# ToritoLuaDisarm

**Lua script** para **desarmar motores** en **tail-sitter** con firmware **Arduplane** 4.2.x y dotado de un sensor de distancia de precisión (**rangefinder**).

Arduplane no desarma motores de forma inmediata al posarse la aeronave en el suelo, lo que puede ocasionar un vuelco no deseado, y que requiere habilidad por parte del piloto para pasar a otro modo de vuelo y/o desarmar de forma manual para evitar el accidente.

## Funcionamiento

El sistema permite desarmar los motores cuando se cumplan todas y cada una de las siguientes condiciones:

- Está activado alguno de los siguietnes **modos de vuelo**: AUTO, RTL, QLAND, QRT, QLOITER, QHOVER, y QSTABILIZE.

- La aeronave está **aterrizando**, y se encuentra por debajo de una **altitud inferior** al valor de **TOR_LANDING_ALT** (en centímetros).

- Valor de **distancia del sensor** (rangefinder) es **menor** que el valor del parámetro **TOR_DIST_SENS** (en centímetros). Es la altitud efectiva a la que desarmará los motores, y su valor dependerá de la distanza del eje Z a la que esté colocado el sensor, y de si queremos que se detengan los motores justo al tocar el suelo o unos centímetro antes.

- La condición del valor del sensor de distancia se debe cumplir un **número de veces** seguidas igual o mayor al del parámetro **TOR_DIST_CONT**. Esto podría evitar que insectos pululando, o pequeños objetos despedidos por el flujo del aire de las hélices, provoquen un desarmado no deseado. 

- Si el valor del parámetro **TOR_ALT_DIFF** es **mayor que 0**, y menor o igual a la diferencia en valor absoluto entre la altidud estimada (ahrs) por el autopiloto y la indicada por el sensor de distancia, no permitirá desarmar, entendiendo que hay algún error en las mediciones entre la distancia del rangefinder y la altiud que Arduplane estima a la que se encuentra la aeronave.

## Instalación 

Para instalar el script lua, seguiremos estos pasos:

1. Habilitar SRC_ENABLE y reiniciar el autopiloto.

2. Desde Configuracíon >> MAVFtp, **subir** el archivo **torito_disarm.lua** a la **carpeta Script**.

3. Reiniciar el autopiloto.

## Depuración

El parámetro **TOR_DEBUG_ENABLE** admite 3 valores:

- **0:** Deshabilitado, no se envían mensaje a la ground station.

- **1:** Se envía **un mensaje una vez por segundo**, con datos útiles para la **depuración** de posibles **errores**.

- **2:** Se envía **un mensaje en los cambios de estado**: Taking off, Flying, Landing, Landed, Disarmed, Can't disarm. En los dos últimos casos se muestra en centímetros la distancia del rangefinder y la altitud ahrs. Esta es la opción recomendada.

## Demostración

- [https://www.youtube.com/watch?v=iiRz3Vd8aDE](https://www.youtube.com/watch?v=wF-GpaD2VPU)
