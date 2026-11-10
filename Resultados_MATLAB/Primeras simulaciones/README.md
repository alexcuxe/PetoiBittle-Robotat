# Contenido de la carpeta y funcionalidades

#### *Importante*

En esta carpeta se encuentran los archivos previos al entregable final. Son archivos transitorios, cada archivo contiene comentarios que aluden a su edición para la ampliación. Estos archivos se entregan como evidencia del trabajo realizado, pero pueden servir de base para trabajos futuros.


## Archivos

1. **bittleSimulationHeaded.m:** Este código de MATLAB contiene el archivo desarrollado inicialmente con la cinemática directa, mediante parámetros de Denavit-Hartenber, con el propósito de construir la primera simulación para poder validar el empaquetado, envío y recepción de comandos.
2. **control_bittle.m:** Este archivo procede del trabajo con el código `bittleSimulationHeaded.m`. Este archivo corresponde a la misma simulaciónd de su predecesor, con la diferencia que integra el envío de comandos inalámbricos mediante el puente TCP.
3. **ui.m:** Este código presenta la primera iteración de la aplicación final entregada en el proyecto (`BittleApp.m`). Contempla el uso de la simulación inicial desarrollada mediante parámetros DH.
4. **skills_ObtencionOffset:** Contiene un set preliminar de las rutinas predeterminadas del robot, contenidas en su firmware. Al final del archivo se adjunta el proceso para la obtención del offset del robot, con el objetivo de poder replicar esto en los futuros agentes. Los comandos utilizados (con previa conexión al Robotat, se usa el marker #63 como) son los siguientes:

    - Se recomienda la visualización del marker y verificar funcionalidad.
        ```
        >> robotat_trvisualize(robotat, 63)
        >> xi = robotat_get_pose(robotat, 63, 'eulzyx')
        ```

    - Colocar el agente con el marker o puntos de referencia colocados sobre la plataforma del Robotat, tratando de alinearlo con el eje X positivo de la misma.

    - Calculo del offset, guardar el valor una vez obtenido el resultado.
        ```
        >> offset = atan2d(sind(xi(4)), cosd(xi(4)))
        ```
    - Verificación y validación del offset.
        ```
        >> theta = atan2d(sind(xi(4) - offset), cosd(xi(4) - offset))

        theta =

             0
        ```
    
    - Verificación de funcionalidad (recomendable), estos valores deben cambiar con respecto de los iniciales y deben cambiar según la pose del robot.
        ```
        >> robotat_trvisualize(robotat, 63)
        >> xi = robotat_get_pose(robotat, 63, 'eulzyx')
        ```

