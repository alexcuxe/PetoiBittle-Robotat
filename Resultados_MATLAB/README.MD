# Contenido de esta carpeta `Resultados_MATLAB`

Esta carpeta contiene los resultados finales entregados al final del proyecto. Cosnta de 3 carpetas principales:

1. **bittle_x:** Archivos extraídos de la carpeta .zip descargada de Onshape, resultado de la edición de un archivo público y utilizados en los archivos `BittleApp.m` y `control_bittle.m` para la visualización del modelo tridimensional en la aplicación desarrollada. No se han editado archivos dentro de esta carpeta, son archivos en bruto fruto de la descompresión de la descarga directa online, solo contiene archivos temporales creados por MATLAB y reemplazados cada vez se corre el programa (no relevantes: `bittle_cinematico.urdf` y `robot_cinematico_temp.urdf`), el resto de archivos sí son utilizados por la App.

2. **Primeras simulaciones:** Contiene archivos previos utilizados durante las primeras fases del proyecto, no son parte del del entregable final, pero pueden servir de base para trabajos futuros. Cotiene archivos utilizando la primer simulación desarrollada mediante parámetros de Denavit-Harteberg.

3. **WiFi_MAC_TCP:** Contiene el archivo `WiFi_MAC_TCP.ino` desarrollado para habilitar la comunicación inalámbrica en el módulo ESP-WROOM-02D. Archivo único desarrollado para este cometido, contiene comentarios previstos para comprensión y sujeto a futuros cambios. Archivo único para Arduino IDE. Para lograr la conexión con el módulo seguir las instrucciones para la [adecuación del entorno de desarrollo](https://guide.petoi.com/communication-modules/wifi-esp8266) sugeridas por Petoi.

La carpeta también contiene los archivos desarrollados para la entrega final del proyecto, para poder correr estos archivos sin problema todos deben ser parte de la misma carpeta y estar acompañados de la carpeta `bittle_x` para poder habilitar la simulación. El archivo central es `BittleApp.m` que hace uso de las funciones desarrolladas. La validación del proyecto se implementó mediante el código independiente a la interfaz desarrollada `robotat_validation.m`, que también hace uso de las funciones desarrolladas.

Las funciones desarrolladas tiene como identificador estadarizado `robotat_bittle_*funcion*.m`. En esta carpeta se encuentran otras funciones complementarias, desarrolladas previamente en UVG.



---

## Detalle de las funciones desarrolladas


Siguiendo el estándar de funciones de otros agentes del laboratorio Robotat (como los robots Pololu 3pi+ con `robotat_3pi_connect`, `robotat_3pi_disconnect`, `robotat_3pi_force_stop`), se encapsuló toda la lógica de bajo nivel en **7 archivos `.m` independientes**.

### 1. `robotat_bittle_connect.m`
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

### 2. `robotat_bittle_force_stop.m`
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

### 3. `robotat_bittle_disconnect.m`
Llama primero a `robotat_bittle_force_stop(robot)`, espera $0.2\text{ s}$ para asegurar la llegada del paquete y elimina la estructura `robot` del *Workspace* base de MATLAB (`evalin('base', ['clear ', var_name])`) para liberar el socket TCP limpiamente.

### 4. `robotat_bittle_skill.m`
Unifica y depura todos los comandos del diccionario `skillFullName` (Python) y `ACTIONS_H_` (C++) del archivo `skills.txt`, eliminando duplicados y exponiéndolos con nombres estandarizados en inglés (`camelCase`). Incorpora un bloque `arguments` con `mustBeMember`, lo que habilita el **autocompletado automático al presionar la tecla `Tab`** en MATLAB:
* **Locomoción y Marchas:** `'forward'` (`kwkF`), `'forwardLeft'` (`kwkL`), `'forwardRight'` (`kwkR`), `'back'` (`kbk`), `'backLeft'` (`kbkL`), `'backRight'` (`kbkR`), `'trot'` (`ktrF`), `'crawl'` (`kcrF`), `'run'` (`krnF`), `'stepping'` (`kvtF`).
* **Sistema:** `'stop'` / `'rest'` (`d`), `'gyro'` (`g`), `'calibration'` (`c`), `'zero'` (`kzero`).
* **Poses Básicas:** `'balance'` (`kbalance`), `'sit'` (`ksit`), `'up'` (`kup`), `'buttUp'` (`kbuttUp`), `'stretch'` (`kstr`), `'lookup'` (`lu`), `'dropped'` (`kdropped`), `'lifted'` (`klifted`), `'landing'` (`klnd`), `'table'` (`ktbl`).
* **Acrobacias y Rutinas:** `'hi'` (`khi`), `'check'` (`kck`), `'pushUp'` (`kpu`), `'pushUpSingleArm'` (`kpu1`), `'pee'` (`kpee`), `'angry'` (`kang`), `'backFlip'` (`kbf`), `'frontFlip'` (`kff`), `'boxing'` (`kbx`), `'cheers'` (`kchr`), `'comeHere'` (`kcmh`), `'dig'` (`kdg`), `'goodboy'` (`kgdb`), `'handShake'` (`khsk`), `'handStand'` (`khds`), `'handsUp'` (`khu`), `'highFive'` (`kfiv`), `'hug'` (`khg`), `'jump'` (`kjmp`), `'kick'` (`kkc`), `'moonWalk'` (`kmw`), `'nod'` (`knd`), `'playDead'` (`kpd`), `'recover'` (`krc`), `'roll'` (`krl`), `'scratch'` (`kscrh`), `'sniff'` (`ksnf`), `'testServo'` (`kts`), `'waveHead'` (`kwh`), `'zz'` (`kzz`).

### 5. `robotat_bittle_set_joints.m`
Recibe un vector `q_deg` de **9 elementos** en el orden `[LF_hip, LF_knee, RF_hip, RF_knee, LB_hip, LB_knee, RB_hip, RB_knee, head]` (o de **16 elementos** para soporte completo de Bittle X V2 con brazo robótico), satura por seguridad en el rango `[-125, 125]` grados, construye la trama binaria `'L'` y la envía por TCP.

### 6. `robotat_bittle_calibrate.m`
Gestiona la calibración de offsets en la EEPROM aceptando tanto el **nombre de la articulación en formato URDF** (con autocompletado `Tab`) como el número de canal (`0`, `8`..`15`):
* `robotat_bittle_calibrate(bittle, 'start')` $\rightarrow$ envía `"c\n"`.
* `robotat_bittle_calibrate(bittle, 'set', 'left_front_hip', -4)` $\rightarrow$ envía `"c 8 -4\n"`.
* `robotat_bittle_calibrate(bittle, 'save')` $\rightarrow$ envía `"s\n"`.

### 7. `robotat_bittle_custom_skill.m` y `bittle_custom_skills_data.m`
Permiten enviar habilidades personalizadas mediante el token `'K'` con autocompletado `Tab`. Para garantizar que el robot no pierda el equilibrio, las rutinas personalizadas se diseñaron cuidando que el **Punto de Momento Cero (ZMP)** permanezca dentro del polígono de soporte y utilizando velocidades suaves (`speed = 3` o `4` en *behaviors*):
* **Postures ($N=1$):** `'posture_low_guard'` (postura agazapada de centro de gravedad bajo) y `'posture_side_lean'` (inclinación lateral sobre 4 apoyos con contrapeso de cabeza).
* **Behaviors ($N<0$):** `'behavior_horizon_scan'` (escaneo de perímetro abajo y arriba sobre 4 apoyos) y `'behavior_lateral_sway'` (transferencia rítmica de peso de izquierda a derecha en bucle).
* **Gaits ($N>1$):** Basados en la línea base `[43, 43, 47, 47, 7, 7, 7, 7]` de `vt`, respetando el emparejamiento diagonal en las 8 columnas (`Cols 1,3` y `5,7` para `LF+RB` vs. `Cols 2,4` y `6,8` para `RF+LB`) y el levantamiento de rodilla hacia ángulos negativos (`-32°` a `-35°`): `'gait_high_step_forward'` (22 fotogramas), `'gait_stable_crawl'` (24 fotogramas moviendo una pata a la vez), `'gait_pivot_left'` (20 fotogramas de giro sobre su eje) y `'gait_test_vt'` (21 fotogramas).


---


## Aplicación Unificada en App Designer (`BittleApp.m`)

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