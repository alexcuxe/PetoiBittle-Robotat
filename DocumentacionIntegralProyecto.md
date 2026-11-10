# Documentación Integral: Simulación Cinemática, Librerías Modulares e Interfaz de Control para Petoi Bittle en el Ecosistema Robotat

**Proyecto:** Integración del Robot Cuadrúpedo Petoi Bittle (Bittle X / Bittle X V2) al Ecosistema Robotat (Laboratorio CIT-116, Universidad del Valle de Guatemala).  
**Repositorio oficial del proyecto:** <https://github.com/alexcuxe/PetoiBittle-Robotat>  
**Propósito de este documento:** Registrar de forma exhaustiva cada etapa técnica, flujo de trabajo cronológico, decisión de diseño, solución de contingencias de hardware, estructura de paquetes de comunicación, catálogo de funciones (`robotat_bittle_...`), arquitectura de la aplicación unificada (`BittleApp.m`) y scripts de validación en lazo cerrado, sirviendo como memoria técnica completa para dar continuidad al proyecto o transferirlo a futuros investigadores.

---

## 0. Flujo de Trabajo Cronológico y Evolución Metodológica del Proyecto

Para comprender el porqué de cada módulo y carpeta dentro del repositorio, a continuación se describe la secuencia cronológica real que guio el desarrollo ingenieril del proyecto:

1. **Exploración Inicial del Ecosistema OpenCat y Génesis de la Interfaz Unificada:**
   * Al encender por primera vez el robot Petoi Bittle, el trabajo inició explorando el repositorio oficial de **OpenCat** y ejecutando los programas originales en Python provistos por el fabricante.
   * Durante estas pruebas iniciales se observó que las herramientas de Petoi estaban fragmentadas en distintos scripts y ventanas independientes (sin un entorno de simulación cinemática 3D integrado ni compatibilidad directa con el flujo de trabajo en MATLAB del laboratorio Robotat). De esta observación surgió la idea de desarrollar una **Aplicación Unificada en MATLAB (`BittleApp.m`)** capaz de concentrar la simulación, la calibración y el control en una sola ventana.

2. **Pruebas Alámbricas Iniciales (`Pruebas_iniciales_serial_alambrica`) y `ardSerial.py`:**
   * Con el objetivo de lograr la simulación en tiempo real de la manera más simple, rápida y fiel posible antes de escalar a modelos 3D complejos o enlaces inalámbricos, primero se analizó el archivo `ardSerial.py` (disponible tanto en el repositorio oficial de OpenCat como en la carpeta `Pruebas_iniciales_serial_alambrica` del repositorio de este proyecto, la cual cuenta con su propio `README.md` y los códigos de prueba empleados).
   * A partir de `ardSerial.py` se comprendió cómo OpenCat estructura, empaqueta y envía los comandos seriales hacia la placa controladora.
   * Conectando físicamente el robot a la computadora mediante el adaptador USB-Serial, se probaron los comandos uno por uno desde MATLAB para validar la respuesta de los servomotores, y posteriormente se enlazó esta comunicación serial alámbrica con la primera simulación cinemática en `SerialLink`, demostrando exitosamente el control y visualización en tiempo real.

3. **Descalibración Mecánica y Desarrollo Paralelo (Migración Wi-Fi + Base de Calibración):**
   * A raíz de las pruebas constantes de movimiento articular, los eslabones del robot sufrieron una descalibración física. Esto evidenció la necesidad crítica de contar con un sistema físico y de software para recalibrar las articulaciones de forma repetible cada vez que fuera necesario.
   * Para optimizar el tiempo de desarrollo, se trabajó **en paralelo** en dos frentes: mientras se migraba la comunicación en MATLAB del puerto serial alámbrico hacia la conexión inalámbrica por Wi-Fi (lo cual exigió volver a verificar la forma en que se empaquetaban y enviaban los datos a través del puente TCP), se realizó simultáneamente la reedición CAD y el prototipado de la base física de calibración.

4. **Consolidación en URDF/Onshape, Librerías Modulares y Lazo Cerrado en Robotat:**
   * Una vez validada la comunicación inalámbrica y calibrado el robot sobre la nueva plataforma física, se dio el salto visual desde `SerialLink` hacia el visualizador 3D basado en **URDF y mallas STL** depuradas en **Onshape**, empaquetando todas las capacidades en la librería modular `robotat_bittle_...`, la aplicación `BittleApp.m` y el script de seguimiento autónomo con **OptiTrack**.

---

## 1. Fase 1: Modelado Cinemático Inicial con `SerialLink`, Parámetros DH y Pruebas Alámbricas

### 1.1 Validación del Protocolo por Cable Serial (`Pruebas_iniciales_serial_alambrica`)
En la primera etapa experimental se utilizó una conexión física por cable entre la computadora y la placa del Bittle. En la carpeta `Pruebas_iniciales_serial_alambrica` del repositorio (`https://github.com/alexcuxe/PetoiBittle-Robotat`) se aloja la copia de referencia de `ardSerial.py` junto con los primeros scripts en MATLAB y su respectivo archivo `README.md`. Esta fase permitió disecar el protocolo de OpenCat sin la incertidumbre de la red inalámbrica, comprobando la sintaxis exacta de los tokens de control articular, posturas y calibración antes de integrarlos al modelo matemático.

### 1.2 Definición Matemática y Marcos de Referencia
El modelado matemático inició con la validación de la cinemática directa del robot cuadrúpedo empleando la convención de **Denavit-Hartenberg (DH)** y la librería *Robotics Toolbox* de Peter Corke (`Revolute`, `SerialLink`) en MATLAB:

* **Marco inercial inicial (sobre una mesa de trabajo):** Se definió con el eje $Z$ apuntando hacia arriba, el eje $X$ hacia adentro de la pantalla y el eje $Y$ hacia la izquierda.
* **Traslación al muslo ($L_1$):** El sistema de coordenadas quedó orientado con el eje $Z$ hacia arriba, el eje $X$ hacia afuera de la pantalla y el eje $Y$ hacia la derecha.
* **Traslación a la pierna/pata ($L_2$):** El sistema se orientó con el eje $Z$ hacia arriba, el eje $Y$ hacia afuera de la pantalla y el eje $X$ hacia la izquierda.
* **Orientación vertical real:** Dado que los eslabones se modelaron inicialmente sobre un plano horizontal, se aplicó una rotación de $-\frac{\pi}{2}$ alrededor del eje $Y$ (`troty(-pi/2)`) en la base de cada extremidad (`LF`, `RF`, `LB`, `RB`), logrando que las patas apuntaran verticalmente hacia el suelo tal como operan en la realidad:

```matlab
% Dimensiones físicas en metros
L1_a = 0.046;   % Muslo (46 mm)
L2_a = 0.048;   % Pierna/pata (48 mm)
L_cab = 0.045;  % Longitud visual de la cabeza (45 mm)

% Parámetros Denavit-Hartenberg
L1 = Revolute('d', 0, 'a', L1_a, 'alpha', 0, 'offset', pi);     % Cadera / Muslo
L2 = Revolute('d', 0, 'a', L2_a, 'alpha', 0, 'offset', -pi/2);  % Rodilla / Pierna
L_head = Revolute('d', 0, 'a', 0, 'alpha', 0, 'offset', pi/2);  % Cuello / Cabeza

% Cadenas cinemáticas
LF = SerialLink([L1, L2], 'name', 'LF');
RF = SerialLink([L1, L2], 'name', 'RF');
LB = SerialLink([L1, L2], 'name', 'LB');
RB = SerialLink([L1, L2], 'name', 'RB');
Cabeza = SerialLink(L_head, 'name', 'Cabeza');

% Posicionamiento y rotación de bases respecto al centro del torso
LF.base = transl(-0.046,  0.0525, 0) * troty(-pi/2);
RF.base = transl( 0.046,  0.0525, 0) * troty(-pi/2);
LB.base = transl(-0.046, -0.0525, 0) * troty(-pi/2);
RB.base = transl( 0.046, -0.0525, 0) * troty(-pi/2);
Cabeza.base = transl(0, 0.0635, 0.015);
```

Para representar el chasis y la cabeza en esta primera etapa, se dibujaron prismas rectangulares mediante la función `patch` (`vert_torso` y `vert_cab_local`), actualizando los vértices de la cabeza mediante la matriz de transformación homogénea calculada con `Cabeza.fkine(q_rad(9))`.

### 1.3 Limitaciones de `SerialLink` en Interfaces Modernas y Motivo de Migración
Durante la creación del primer panel de control con pestañas (`uitabgroup`), se identificaron dos limitaciones críticas con `SerialLink`:
1. **Incompatibilidad con `uiaxes` (`Error using RTBPlot.plot_options: unknown option: ax`):** El motor gráfico de la *Robotics Toolbox* clásica de Peter Corke no soporta dibujar sobre componentes `UIAxes` modernos de App Designer (`uifigure`), exigiendo abrir una ventana tradicional (`figure`) por separado. Además, la función `.animate()` reajustaba los límites de la cámara automáticamente a menos que se bloquearan manualmente con `ax3d.XLimMode = 'manual'`.
2. **Visualización burda y poco intuitiva:** Aunque el modelo en `SerialLink` era matemáticamente exacto y fiel a las dimensiones, ejes de giro y parámetros DH del robot real, su representación visual a base de cilindros genéricos y cajas simples (`patch`) resultaba tosca y poco atractiva. Por esta razón, se tomó la decisión de migrar hacia una simulación basada en archivos **URDF y mallas STL**, la cual ofrece una visualización 3D realista, agradable y mucho más fácil de interpretar para el ojo humano.

---

## 2. Fase 2: Desarrollo del Visualizador Cinemático Universal con URDF y STL (Onshape)

### 2.1 Origen y Depuración del Modelo CAD en Onshape
A diferencia de la base de calibración física (que se trabajó en Autodesk Inventor), los archivos para la simulación 3D provinieron de un **ensamblaje público del Petoi Bittle en Onshape**. 

Para que este modelo público sirviera como un gemelo digital fiel al robot físico, se realizó una edición profunda directamente en **Onshape** antes de su exportación final:
* **Limpieza de juntas fantasma:** El proyecto público original contenía articulaciones adicionales o mal definidas que no correspondían a los servomotores reales; estas fueron depuradas y fijadas para conservar únicamente los **9 grados de libertad reales** del cuadrúpedo (`head`, `left_front_hip`, `left_front_knee`, `right_front_hip`, `right_front_knee`, `left_back_hip`, `left_back_knee`, `right_back_hip`, `right_back_knee`).
* **Corrección de sentidos de giro:** Se invirtieron y alinearon los ejes de rotación de los *mates* tipo `revolute` en Onshape para que un ángulo positivo o negativo en la simulación produjera exactamente el mismo sentido de giro (horario/antihorario) que tienen los servomotores físicos en OpenCat.
* **Restricciones reales de las juntas:** Se configuraron los límites angulares reales en cada articulación dentro del URDF (`<limit lower="..." upper="...">`).

---

### 2.2 Documentación Original Íntegra del Visualizador Cinemático Universal (Estilo `.teach`)

*(A continuación se preserva íntegramente la documentación técnica generada durante la creación del visualizador URDF en MATLAB).*

#### 2.2.1 Objetivo del Módulo
Desarrollar una interfaz gráfica interactiva en MATLAB que permita cargar, visualizar y manipular de forma fluida el modelo cinemático 3D del robot Petoi Bittle (o cualquier otro robot). La herramienta debe emular el comportamiento de la función `.teach` de la *Robotics Toolbox* (Peter Corke), permitiendo el control individual de las articulaciones en grados, pero utilizando los objetos nativos de MATLAB (`RigidBodyTree`).

#### 2.2.2 Archivos de Origen y Formatos
La simulación se alimenta de un paquete exportado directamente desde un ensamblaje CAD en **Onshape**.

* **Exportación:** Se utiliza la herramienta de exportación a **URDF** con geometrías en formato **Binary STL** y resolución "Fine".
* **Archivo `.urdf` (Unified Robot Description Format):** Es el archivo central (basado en XML). Se utiliza porque es el estándar universal en robótica. Contiene el árbol cinemático (padre-hijo), los límites de las articulaciones, los ejes de rotación y las referencias espaciales.
* **Archivos `.stl` (Stereolithography):** Son las mallas 3D. Se utilizan exclusivamente para la fidelidad visual de cada eslabón en la simulación.
* **Por qué estos archivos:** El URDF permite que MATLAB construya el `RigidBodyTree` automáticamente sin tener que definir manualmente los parámetros de Denavit-Hartenberg (DH) línea por línea, evitando errores humanos de transcripción.

#### 2.2.3 Desafíos Técnicos y Soluciones Implementadas
Durante el desarrollo en MATLAB (probado en versión R2025b), nos enfrentamos a varias limitaciones de las funciones nativas que requirieron soluciones programáticas específicas (Workarounds):

##### Problema 1: Cilindros gigantes que ocultaban el modelo 3D
* **Causa:** El archivo URDF contiene etiquetas `<inertial>` y `<collision>` con valores de masa minúsculos (ej. $1 \times 10^{-7}$). La función `show()` de MATLAB intenta graficar representaciones matemáticas de estas inercias y colisiones, generando cilindros y esferas gigantes por un error de auto-escalado.
* **Solución:** Se implementó una limpieza automática del URDF en tiempo de ejecución utilizando expresiones regulares (`regexprep`). El script lee el URDF como texto plano, elimina por completo los bloques `<inertial>...</inertial>` y `<collision>...</collision>`, y guarda un `robot_cinematico_temp.urdf`. Así, MATLAB se ve obligado a mostrar *solo* las mallas visuales (`.stl`).

##### Problema 2: Rutas de archivos exclusivas de ROS
* **Causa:** El URDF exportado utiliza el prefijo `package://...` para referenciar las mallas, un formato que MATLAB no comprende de forma nativa.
* **Solución:** Se utilizó `strrep` / `regexprep` para eliminar el prefijo `package://nombre_paquete/` y se forzó el uso del parámetro `'MeshPath'` en la función `importrobot` apuntando a la carpeta raíz extraída.

##### Problema 3: Incompatibilidad con UIAxes
* **Causa:** Al intentar construir una interfaz moderna con `uifigure` y `uiaxes`, MATLAB arrojó un error indicando que el método `.show()` del `RigidBodyTree` no soporta paneles `UIAxes`.
* **Solución:** En la versión preliminar (`control_bittle.m`), se retrocedió a una arquitectura de ventana clásica (`figure`, `axes`, `uicontrol`), dándole un estilo de "Modo Oscuro" personalizado mediante código. Posteriormente, al migrar a **App Designer (`BittleApp.m`)**, se descubrió cómo resolver esto dentro de una `uifigure` moderna: insertando un contenedor `uipanel` (`CanvasPanel`) y creando programáticamente dentro de él un eje clásico `axes(app.CanvasPanel)`.

##### Problema 4: "Zoom-out" automático y cámara bloqueada al actualizar la postura
* **Causa:** Cada vez que se actualizaba el valor de una articulación, la función `show()` repintaba la escena, reseteando la cámara a sus límites por defecto (`[-0.5, 0.5]`), alejando al robot y desactivando la herramienta `rotate3d`. Además, si `CameraViewAngleMode` quedaba en `'auto'`, al rotar el cubo de los ejes y mover un *slider* se producía un pequeño salto óptico de reencuadre.
* **Solución Definitiva:**
  1. Se migró la actualización al método `'FastUpdate', true` asegurando que todos los parámetros visuales (`Collisions`, `Frames`, `PreservePlot`) coincidieran exactamente con el dibujo inicial.
  2. En lugar de usar `show` de forma general, se accede al `Parent` gráfico y se inyecta directamente la nueva configuración (`guiData.config`).
  3. Se capturaron las constantes ópticas de la lente (`CameraViewAngle` y `CameraTarget = [0 0 0]`) al inicio de la simulación y se reinyectaron en cada actualización mediante `aplicarEstadoCamara`, eliminando por completo cualquier salto de zoom.
  4. Se implementó un controlador de ratón personalizado (`WindowButtonDownFcn`, `WindowButtonMotionFcn`, `WindowButtonUpFcn`) adherido a la figura, permitiendo rotar la vista 3D modificando directamente el Acimut y la Elevación (`view(az, el)`) sin que el repintado del robot congele la cámara.

#### 2.2.4 Características del Visualizador Cinemático Universal
* **Limpieza Autónoma:** Parsea el URDF, lo limpia de basura inercial y lo carga.
* **Límites Dinámicos:** Escanea el URDF para encontrar los límites de posición (`<limit lower="..." upper="...">`) de cada junta tipo `revolute`. Si no hay límites (`continuous`), asigna un rango de $-180^\circ$ a $180^\circ$.
* **Interfaz de Usuario Híbrida (Grados/Radianes):** Toda la interacción del usuario (Sliders y Edit Boxes) se realiza en **Grados**, pero internamente el código convierte a **Radianes** para el modelo matemático.
* **Controles Adicionales:**
  * Cuadro para escalar los límites de la ventana 3D en vivo (útil para robots más grandes o más pequeños).
  * Botón "Home" para llevar todas las juntas a $0^\circ$.
  * Botón para cargar otros archivos URDF dinámicamente (`uigetfile`).

---

## 3. Fase 3: Arquitectura de Comunicación, Protocolo OpenCat (Puente TCP) y Contingencias de Hardware

### 3.1 Puente Inalámbrico TCP en el Módulo ESP-WROOM-02D
Para independizar al Bittle de los cables sin modificar el firmware base de OpenCat alojado en la placa NyBoard V1_2 (ni perder sus algoritmos internos de control PWM y balance), se programó el módulo Wi-Fi **ESP-WROOM-02D** (mediante Arduino IDE) para operar como un **Puente TCP Transparente (*TCP Bridge*) en el puerto `8116`**.
* Mediante la lectura de la dirección MAC del módulo, el router del servidor del laboratorio Robotat le asigna una **IP estática** a cada agente (ej. `192.168.50.172` para el Agente 1).
* Todo byte enviado desde MATLAB mediante `tcpclient` al puerto `8116` es retransmitido inmediatamente por UART hacia la placa del Bittle con latencia mínima.

### 3.2 Tipos de Tramas y Empaquetado de Datos
Durante la migración del enlace serial alámbrico hacia el puente inalámbrico Wi-Fi fue necesario verificar y adaptar el empaquetado de datos sobre sockets TCP. A partir del análisis de los scripts originales de Petoi en Python (`ardSerial.py`, `test1.py`) y los archivos de cabecera en C++ (`ACTIONS_H_`), se implementaron en MATLAB los formatos de instrucción de OpenCat:

1. **Comandos de Texto ASCII (Tokens `'k'`, `'d'`, `'g'`, `'c'`, `'s'`):**
   * Se envían como cadenas de caracteres seguidas de un salto de línea (`newline`, ASCII 10).
   * Ejemplos: `"ksit\n"` (sentarse), `"kwkF\n"` (caminar hacia adelante), `"d\n"` (reposo / apagar servos), `"g\n"` (activar/desactivar giroscopio), `"c\n"` (iniciar modo calibración), `"c 8 -4\n"` (asignar offset de $-4^\circ$ a la articulación 8), `"s\n"` (guardar offsets en memoria EEPROM).

2. **Trama Binaria `'L'` (Control simultáneo de las 16 articulaciones):**
   * Permite mover todos los servomotores al mismo tiempo con codificación binaria eficiente.
   * **Estructura:** Un carácter `'L'` (ASCII 76) + **16 bytes con signo (`int8`)** correspondientes a los canales `0` al `15` de la placa + carácter terminador `'~'` (ASCII 126):
     ```matlab
     paquete = [uint8('L'), typecast(int8(servos), 'uint8'), uint8('~')];
     write(tcpsock, paquete, "uint8");
     ```
   * **Mapeo de canales en Bittle (índices 1 a 16 en MATLAB $\leftrightarrow$ canales 0 a 15 en OpenCat):**
     * Índice `1` (Canal `0`): `head` (paneo de cabeza). *(Nota: Los índices `2` y `3` corresponden a los canales `1` y `2`, reservados para expansiones como el brazo robótico del Bittle X V2).*
     * Índice `9` (Canal `8`): `left_front_hip` (LF Cadera).
     * Índice `10` (Canal `9`): `right_front_hip` (RF Cadera).
     * Índice `11` (Canal `10`): `right_back_hip` (RB Cadera).
     * Índice `12` (Canal `11`): `left_back_hip` (LB Cadera).
     * Índice `13` (Canal `12`): `left_front_knee` (LF Rodilla).
     * Índice `14` (Canal `13`): `right_front_knee` (RF Rodilla).
     * Índice `15` (Canal `14`): `right_back_knee` (RB Rodilla).
     * Índice `16` (Canal `15`): `left_back_knee` (LB Rodilla).

3. **Trama Binaria `'K'` (Envío de habilidades personalizadas en tiempo real):**
   * Emula la función `serialWriteNumToByte(port, 'K', var)` de `ardSerial.py`. Permite inyectar una habilidad nueva (Posture, Gait o Behavior) en la memoria RAM del robot y ejecutarla al vuelo.
   * **Estructura de la matriz según el primer elemento ($N = \text{var}(1)$):**
     * **Posture ($N = 1$):** Encabezado de **4 bytes** `[1, roll, pitch, angleRatio]` + **1 fila de 16 ángulos** (canales `0` al `15`). Total: $20\text{ bytes}$.
     * **Gait ($N > 1$):** Encabezado de **4 bytes** `[N, roll, pitch, angleRatio]` + **$N$ filas de 8 ángulos** correspondientes únicamente a las patas (canales `8` al `15`: `[LF_hip, RF_hip, RB_hip, LB_hip, LF_knee, RF_knee, RB_knee, LB_knee]`). Se ejecuta en ciclo continuo hasta recibir otro comando.
     * **Behavior ($N < 0$):** El signo negativo indica que es una secuencia acrobática o comportamiento que se ejecuta una sola ronda. Tiene un encabezado de **7 bytes** `[-N, roll, pitch, angleRatio, startFrame, endFrame, loopTimes]` + **$N$ filas de 20 bytes**: `[16 ángulos (0..15), speed, delay_x50ms, triggerAxis, triggerAngle]`.
   * **Reglas críticas del protocolo `'K'` replicadas en MATLAB:**
     * *Auto-escalado (`angleRatio`):* Si algún ángulo articular supera el rango `[-125, 125]`, el cuarto byte del encabezado (`angleRatio`) pasa automáticamente de `1` a `2` y todos los ángulos articulares se dividen entre `2` (división entera `fix(ang/2)`) para caber en un `int8`.
     * *Fragmentación en bloques (*Slicing* de 20 bytes):* Para no desbordar el búfer UART entre el ESP8266 y la NyBoard, el arreglo `[uint8('K'), typecast(int8(var), 'uint8'), uint8('~')]` se transmite en fragmentos de máximo **20 bytes** con una pausa de $2\text{ ms}$ entre cada fragmento.

### 3.3 Incidente de Bloqueo del Puerto Serial en la Placa NyBoard y Procedimiento de Recuperación
Durante la transición experimental entre las pruebas alámbricas y las inalámbricas ocurrió un bloqueo de hardware en la placa **NyBoard** cuyo diagnóstico y solución resulta indispensable documentar para futuros operadores:

* **Causa del bloqueo:** Se conectaron simultáneamente el adaptador de comunicación serial alámbrica (USB uploader) y el módulo inalámbrico Wi-Fi sobre la placa NyBoard mientras ambos estaban energizados/conectados por USB. Debido a que ambos módulos comparten el mismo bus UART ($\text{RX}/\text{TX}$), se generó una colisión que bloqueó el puerto serial de la placa NyBoard, dejándola incapaz de recibir o procesar comandos.
* **Limitación de la placa NyBoard:** A diferencia de otras placas de desarrollo, la NyBoard no cuenta con un botón físico o interruptor de "modo desarrollador" (*bootloader recovery*) que permita desbloquear o reiniciar la interfaz serial directamente por hardware.
* **Procedimiento de solución mediante el *Firmware Uploader* oficial:**
  1. Se retiró por completo el módulo Wi-Fi de la placa NyBoard.
  2. Se conectó el robot a la computadora **exclusivamente de manera alámbrica** mediante el adaptador USB-Serial (la misma configuración física empleada en `Pruebas_iniciales_serial_alambrica`).
  3. Se descargó y ejecutó la herramienta oficial **Firmware Uploader** del repositorio de OpenCat (la cual también quedó referenciada en el repositorio de este proyecto: `https://github.com/alexcuxe/PetoiBittle-Robotat`). El repositorio de esta herramienta es `https://github.com/PetoiCamp/DesktopAppRelease/releases`.
  4. Desde la interfaz del *Firmware Uploader*, se seleccionó el modelo correspondiente de la placa controladora (NyBoard) y se reinstaló (*flasheó*) el firmware estándar de fábrica de OpenCat. Este proceso forzó la reprogramación del microcontrolador, desbloqueando el puerto serial y restaurando la operatividad normal del Bittle.

> **Advertencia Operativa Crítica:** **Nunca** deben conectarse el adaptador USB-Serial y el módulo Wi-Fi de forma simultánea en la placa NyBoard. Siempre debe desconectarse físicamente uno antes de conectar el otro.

---

## 4. Fase 4: Librería Modular de Control (`robotat_bittle_...`)

Siguiendo el estándar de funciones de otros agentes del laboratorio Robotat (como los robots Pololu 3pi+ con `robotat_3pi_connect`, `robotat_3pi_disconnect`, `robotat_3pi_force_stop`), se encapsuló toda la lógica de bajo nivel en **7 archivos `.m` independientes**.

### 4.1 `robotat_bittle_connect.m`
Establece la conexión TCP recibiendo únicamente el número identificador del agente (`agent_id`), ocultando la dirección IP al usuario final y aplicando un `ConnectTimeout` estricto de **5 segundos** para evitar que MATLAB se congele si se intenta conectar a un robot apagado:

```matlab
function robot = robotat_bittle_connect(agent_id)
    % robotat_bittle_connect - Establece conexión TCP con un agente Petoi Bittle.
    % Uso:
    %   bittle1 = robotat_bittle_connect(1);
    
    if(numel(agent_id) ~= 1)
        error('Solo se puede conectar con un agente Bittle a la vez.');
    end
    
    robot.id = round(agent_id);
    robot.port = 8116; % Puerto estandarizado para todos los Bittle
    robot.type = 'Petoi Bittle';
    
    % Asignación de IP estática basada en el ID del agente
    switch robot.id
        case 1
            robot.ip = '192.168.50.172';
        case 2
            robot.ip = '192.168.50.173'; % Futuro Bittle 2
        case 3
            robot.ip = '192.168.50.174'; % Futuro Bittle 3
        otherwise
            error('ID de agente inválido. Asegúrese de que el Bittle esté registrado en la función de conexión.');
    end
    
    try
        % ConnectTimeout limita el intento inicial a 5 s; Timeout limita lecturas/escrituras a 2 s
        tcpsock = tcpclient(robot.ip, robot.port, "ConnectTimeout", 5, "Timeout", 2);
        robot.tcpsock = tcpsock;
        disp(['¡Conectado al Bittle ' num2str(robot.id) '!']);
        
        % Secuencia de despertar y limpieza para la NyBoard/BiBoard
        write(robot.tcpsock, uint8(char(newline + newline + newline + "d" + newline)));
        pause(0.5); 
        
        if robot.tcpsock.NumBytesAvailable > 0
            read(robot.tcpsock, robot.tcpsock.NumBytesAvailable, "char");
        end
    catch ME
        disp('ERROR: No se pudo conectar al robot. Tiempo de espera agotado.');
        robot.tcpsock = []; 
    end
end
```

### 4.2 `robotat_bittle_force_stop.m`
Envía inmediatamente el comando de descanso (`"d\n"`) a través de `robot.tcpsock` para apagar el torque de los servomotores en caso de emergencia o cierre:

```matlab
function robotat_bittle_force_stop(robot)
    if isfield(robot, 'tcpsock') && ~isempty(robot.tcpsock)
        try
            write(robot.tcpsock, uint8(char("d" + newline)));
            disp('Bittle detenido (Torque apagado).');
        catch
            warning('No se pudo enviar el comando de paro al Bittle.');
        end
    end
end
```

### 4.3 `robotat_bittle_disconnect.m`
Llama primero a `robotat_bittle_force_stop(robot)`, espera $0.2\text{ s}$ para asegurar la llegada del paquete y elimina la estructura `robot` del *Workspace* base de MATLAB (`evalin('base', ['clear ', var_name])`) para liberar el socket TCP limpiamente.

### 4.4 `robotat_bittle_skill.m`
Unifica y depura todos los comandos del diccionario `skillFullName` (Python) y `ACTIONS_H_` (C++) del archivo `skills.txt`, eliminando duplicados y exponiéndolos con nombres estandarizados en inglés (`camelCase`). Incorpora un bloque `arguments` con `mustBeMember`, lo que habilita el **autocompletado automático al presionar la tecla `Tab`** en MATLAB:
* **Locomoción y Marchas:** `'forward'` (`kwkF`), `'forwardLeft'` (`kwkL`), `'forwardRight'` (`kwkR`), `'back'` (`kbk`), `'backLeft'` (`kbkL`), `'backRight'` (`kbkR`), `'trot'` (`ktrF`), `'crawl'` (`kcrF`), `'run'` (`krnF`), `'stepping'` (`kvtF`).
* **Sistema:** `'stop'` / `'rest'` (`d`), `'gyro'` (`g`), `'calibration'` (`c`), `'zero'` (`kzero`).
* **Poses Básicas:** `'balance'` (`kbalance`), `'sit'` (`ksit`), `'up'` (`kup`), `'buttUp'` (`kbuttUp`), `'stretch'` (`kstr`), `'lookup'` (`lu`), `'dropped'` (`kdropped`), `'lifted'` (`klifted`), `'landing'` (`klnd`), `'table'` (`ktbl`).
* **Acrobacias y Rutinas:** `'hi'` (`khi`), `'check'` (`kck`), `'pushUp'` (`kpu`), `'pushUpSingleArm'` (`kpu1`), `'pee'` (`kpee`), `'angry'` (`kang`), `'backFlip'` (`kbf`), `'frontFlip'` (`kff`), `'boxing'` (`kbx`), `'cheers'` (`kchr`), `'comeHere'` (`kcmh`), `'dig'` (`kdg`), `'goodboy'` (`kgdb`), `'handShake'` (`khsk`), `'handStand'` (`khds`), `'handsUp'` (`khu`), `'highFive'` (`kfiv`), `'hug'` (`khg`), `'jump'` (`kjmp`), `'kick'` (`kkc`), `'moonWalk'` (`kmw`), `'nod'` (`knd`), `'playDead'` (`kpd`), `'recover'` (`krc`), `'roll'` (`krl`), `'scratch'` (`kscrh`), `'sniff'` (`ksnf`), `'testServo'` (`kts`), `'waveHead'` (`kwh`), `'zz'` (`kzz`).

### 4.5 `robotat_bittle_set_joints.m`
Recibe un vector `q_deg` de **9 elementos** en el orden `[LF_hip, LF_knee, RF_hip, RF_knee, LB_hip, LB_knee, RB_hip, RB_knee, head]` (o de **16 elementos** para soporte completo de Bittle X V2 con brazo robótico), satura por seguridad en el rango `[-125, 125]` grados, construye la trama binaria `'L'` y la envía por TCP.

### 4.6 `robotat_bittle_calibrate.m`
Gestiona la calibración de offsets en la EEPROM aceptando tanto el **nombre de la articulación en formato URDF** (con autocompletado `Tab`) como el número de canal (`0`, `8`..`15`):
* `robotat_bittle_calibrate(bittle, 'start')` $\rightarrow$ envía `"c\n"`.
* `robotat_bittle_calibrate(bittle, 'set', 'left_front_hip', -4)` $\rightarrow$ envía `"c 8 -4\n"`.
* `robotat_bittle_calibrate(bittle, 'save')` $\rightarrow$ envía `"s\n"`.

### 4.7 `robotat_bittle_custom_skill.m` y `bittle_custom_skills_data.m`
Permiten enviar habilidades personalizadas mediante el token `'K'` con autocompletado `Tab`. Para garantizar que el robot no pierda el equilibrio, las rutinas personalizadas se diseñaron cuidando que el **Punto de Momento Cero (ZMP)** permanezca dentro del polígono de soporte y utilizando velocidades suaves (`speed = 3` o `4` en *behaviors*):
* **Postures ($N=1$):** `'posture_low_guard'` (postura agazapada de centro de gravedad bajo) y `'posture_side_lean'` (inclinación lateral sobre 4 apoyos con contrapeso de cabeza).
* **Behaviors ($N<0$):** `'behavior_horizon_scan'` (escaneo de perímetro abajo y arriba sobre 4 apoyos) y `'behavior_lateral_sway'` (transferencia rítmica de peso de izquierda a derecha en bucle).
* **Gaits ($N>1$):** Basados en la línea base `[43, 43, 47, 47, 7, 7, 7, 7]` de `vt`, respetando el emparejamiento diagonal en las 8 columnas (`Cols 1,3` y `5,7` para `LF+RB` vs. `Cols 2,4` y `6,8` para `RF+LB`) y el levantamiento de rodilla hacia ángulos negativos (`-32°` a `-35°`): `'gait_high_step_forward'` (22 fotogramas), `'gait_stable_crawl'` (24 fotogramas moviendo una pata a la vez), `'gait_pivot_left'` (20 fotogramas de giro sobre su eje) y `'gait_test_vt'` (21 fotogramas).

---

## 5. Fase 5: Aplicación Unificada en App Designer (`BittleApp.m`)

La interfaz gráfica final se consolidó en una clase de App Designer (`classdef BittleApp < matlab.apps.AppBase`) que integra el visualizador 3D URDF y las librerías `robotat_bittle_...` en una sola ventana en modo oscuro:

1. **Panel Superior de Conexión TCP (`ConnPanel`):**
   * Permite seleccionar el `Agente ID` (`uispinner`), conectar/desconectar invocando `robotat_bittle_connect` y `robotat_bittle_force_stop`, visualizar el estado (`Conectado` / `Offline (Sim)`) y activar o desactivar el interruptor **`Enviar a Bittle en vivo`** (`SwLiveSend`).
2. **Pestaña 1 – Control URDF (`TabManual`):**
   * Genera dinámicamente los *sliders* y cuadros de texto numéricos (`uieditfield`) sincronizados en grados para cada articulación del URDF cargado.
   * Al mover un *slider*, actualiza la malla 3D con `show(..., 'FastUpdate', true)` y, si el envío en vivo está activo, invoca `robotat_bittle_set_joints` aplicando un limitador de frecuencia no bloqueante (`toc(app.TimerEnvio) > 0.03`) para no saturar el módulo Wi-Fi.
3. **Pestaña 2 – Calibración (`TabCalib`):**
   * Incluye el botón para iniciar el modo de calibración (`robotat_bittle_calibrate(app.AgenteBittle, 'start')`), un menú desplegable (`DdCalibJoint`) con los nombres amigables e IDs de cada articulación, un **slider de aproximación rápida (`-25°` a `25°`) acoplado a una cajita numérica (`EdtCalibOffset`)** para escribir el grado exacto de *offset*, memoria local por sesión (`containers.Map`) y el botón rojo para guardar permanentemente en la EEPROM (`'save'`).
4. **Pestaña 3 – Locomoción y Skills (`TabSkills`):**
   * **Subpanel 1 (Control de Locomoción y Marchas):** Cuadrícula con todas las funciones de desplazamiento (`forwardLeft`, `forward`, `forwardRight`, `backLeft`, `back`, `backRight`), marchas (`trot`, `run`, `crawl`, `stepping`), `gyro` y botón de emergencia `stop`.
   * **Subpanel 2 (Poses y Acrobacias para Demostración):** 18 botones interactivos con las rutinas más vistosas (`balance`, `sit`, `buttUp`, `stretch`, `hi`, `check`, `frontFlip`, `backFlip`, `moonWalk`, `pushUp`, `pushUpSingleArm`, `boxing`, `handStand`, `jump`, `cheers`, `goodboy`, `playDead`, `pee`), todos conectados a `robotat_bittle_skill`.
5. **Panel Derecho – Entorno 3D URDF (`RightPanel`):**
   * Incluye la barra de herramientas superior (`Límite Ejes (m)`, botón `Home (0°)` y botón `Otro URDF...`) y el contenedor `CanvasPanel` donde se aloja el eje `Ax3D` con rotación fluida por ratón.

---

## 6. Fase 6: Plataforma Física de Calibración y Validación en Lazo Cerrado en el Robotat

### 6.1 Diseño y Manufactura de la Base Física de Calibración
Dado que los servomotores del Petoi Bittle no poseen retroalimentación de posición absoluta (encoders de cuadratura o potenciómetros accesibles al usuario para auto-cero), y a raíz de la descalibración mecánica ocurrida durante las primeras pruebas de movimiento, fue necesario implementar una estructura física que inmovilizara el chasis en el aire y proporcionara referencias visuales de ángulos conocidos ($0^\circ$, $\pm 45^\circ$, $+90^\circ$, $+135^\circ$, $+180^\circ$):
1. **Edición CAD en Autodesk Inventor (En paralelo a la migración Wi-Fi):** Se partió de los archivos STL del soporte básico de Petoi, convirtiéndolos a cuerpos sólidos editables en **Autodesk Inventor** para incorporar las marcas angulares de referencia y verificar tolerancias mediante un ensamblaje virtual mientras se desarrollaba en paralelo la migración de los paquetes de comunicación al módulo Wi-Fi.
2. **Prototipado en MDF y Entrega Final en Acrílico:** Se fabricó un primer prototipo mediante corte láser en **MDF** para validar las dimensiones y el encastre con el chasis del robot. Una vez validado el diseño, **la versión definitiva de la plataforma de calibración fue manufacturada y entregada en acrílico**, logrando un acabado duradero y de alta rigidez para el laboratorio CIT-116.

### 6.2 Uso de las Funciones desde la Command Window y Scripts
Cualquier estudiante o investigador puede controlar el Bittle desde la consola de MATLAB en pocas líneas:

```matlab
% 1. Conectar al Bittle ID 1
bittle = robotat_bittle_connect(1);

% 2. Ejecutar habilidades o comandos de locomoción (autocompletado con tecla Tab)
robotat_bittle_skill(bittle, 'balance');
pause(2);
robotat_bittle_skill(bittle, 'hi');
pause(3);

% 3. Enviar ángulos articulares directos [LF_hip, LF_knee, RF_hip, RF_knee, LB_hip, LB_knee, RB_hip, RB_knee, head]
robotat_bittle_set_joints(bittle, [15, -20, 15, -20, -15, 30, -15, 30, 25]);
pause(2);

% 4. Ejecutar una habilidad personalizada mediante el token 'K'
robotat_bittle_custom_skill(bittle, 'behavior_horizon_scan');
pause(6);

% 5. Desconectar de forma segura (envía paro y limpia la variable)
robotat_bittle_disconnect(bittle);
```

### 6.3 Script de Validación en Lazo Cerrado en el Ecosistema Robotat (`robotat_validation.m`)
Para comprobar la integración completa dentro del sistema de captura de movimiento **OptiTrack** del Robotat, se colocaron marcadores reflectivos sobre el Bittle (marker `63`) y un objetivo móvil (marker `72`). El script final utiliza las librerías `robotat_bittle_...` para calcular en tiempo real el error de distancia ($e_P$) y el error de orientación normalizado ($e_O$), comandando autónomamente al robot sin saturar la red gracias a la comparación `comando_actual ~= comando_anterior`:

```matlab
%% Limpieza
clear; clc; close all;

%% Conexión al Robotat 
robotat = robotat_connect();

%% Conexión con el agente Bittle usando la nueva librería
robot_id = 1;
bittle = robotat_bittle_connect(robot_id);

%% Offsets del robot para las pruebas
robot_no = 63;
marker_offsets_Bittle = [86.6559 0 0];
offset = marker_offsets_Bittle(robot_id);

%% Parámetros de Control
marker_goal = 72;
dt = 1;
comando_actual = "ksit"; % Empezamos sentados

try
    while true
        % Obtención de Pose del Bittle
        xi = robotat_get_pose(robotat, robot_no, 'eulzyx');
        posx = xi(1) * 1000; 
        posy = xi(2) * 1000;
        
        theta_deg = atan2d(sind(xi(4) - offset), cosd(xi(4) - offset));
        theta = deg2rad(theta_deg);     
        
        % Obtener posición de la meta
        goal = robotat_get_pose(robotat, marker_goal, 'eulzyx');
        xg = goal(1) * 1000; 
        yg = goal(2) * 1000; 
        
        % Cálculo de Errores
        e = [xg - posx; yg - posy];
        eP = norm(e);                
        thetag = atan2(e(2), e(1));  
        eO = thetag - theta;         
        eO = atan2(sin(eO), cos(eO)); 
        
        % Control por comandos del Bittle
        comando_anterior = comando_actual; % Guardar comando anterior para no saturar puerto
        
        % Asignar comando según eP (posición) y eO (error angular)
        if eP < 180
            comando_actual = "rest";                 
        elseif abs(eO) > deg2rad(5)
            if eO > 0
                comando_actual = "forwardLeft";
            else
                comando_actual = "forwardRight";  
            end
        else
            comando_actual = "forward"; 
        end
        
        % Envío de comando no redundante mediante la librería modular
        if comando_actual ~= comando_anterior
            robotat_bittle_skill(bittle, comando_actual);
        end
        
        pause(dt); 
    end
catch ME
    disp('Bucle interrumpido (Error o Ctrl+C). Cerrando conexiones...');
    robotat_bittle_disconnect(bittle);
    robotat_disconnect(robotat);
    rethrow(ME);
end
```

---

## 7. Resumen de Archivos y Carpetas que Conforman el Proyecto Final

| Archivo / Carpeta | Función dentro de la Arquitectura |
| :--- | :--- |
| `Pruebas_iniciales_serial_alambrica/` | Carpeta con `ardSerial.py`, scripts preliminares de validación por cable USB-Serial, enlace inicial con `SerialLink` y su propio `README.md`. |
| `Firmware Uploader` (OpenCat / Respaldo en Repo) | Herramienta oficial empleada por conexión alámbrica para reinstalar el firmware de la placa NyBoard y desbloquear su puerto serial tras colisiones UART. |
| `bittle_x.urdf` y carpeta `/meshes/*.stl` | Modelo 3D editado y depurado en **Onshape** (sin juntas fantasma, con límites y sentidos de giro reales). |
| `robotat_bittle_connect.m` | Conexión TCP al puerto `8116` por `agent_id`, con `ConnectTimeout` de $5\text{ s}$ y secuencia de despertar. |
| `robotat_bittle_force_stop.m` | Paro inmediato enviando el token `"d\n"` para desenergizar los servomotores. |
| `robotat_bittle_disconnect.m` | Detiene al robot y destruye la variable en el *Workspace* base para liberar el socket TCP. |
| `robotat_bittle_skill.m` | Envía cualquier habilidad, pose o marcha predeterminada con autocompletado `Tab`. |
| `robotat_bittle_set_joints.m` | Empaqueta y envía un vector de 9 (o 16) ángulos articulares mediante la trama binaria `'L'`. |
| `robotat_bittle_calibrate.m` | Inicia calibración (`'start'`), ajusta offsets por nombre URDF o ID (`'set'`) y guarda en EEPROM (`'save'`). |
| `robotat_bittle_custom_skill.m` | Empaqueta, auto-escala (`angleRatio`) y envía en bloques de $20\text{ bytes}$ nuevas rutinas con el token `'K'`. |
| `bittle_custom_skills_data.m` | Catálogo de matrices para nuevas *Postures*, *Behaviors* (con estabilidad ZMP) y *Gaits* diagonales. |
| `BittleApp.m` | Aplicación unificada estilo App Designer con visualizador 3D URDF y las 3 pestañas operativas. |
| `robotat_validation.m` | Script de validación experimental en lazo cerrado con OptiTrack dentro del ecosistema Robotat. |