# Requerimientos iniciales
## Identificación Hardware
### Verificar Versión de la placa
![VersionPlaca](Imagenes/VersionPlaca.png)

### Módulo de conexión USB
![USBadapter](Imagenes/USBadapter.png)

### Módulo de conexión WiFi
![PlacaWiFi](Imagenes/WiFiModule.png)

### Módulo de conexión Bluetooth
![BTplaca](Imagenes/BTModule.png)



## Funcionamiento del entorno (Windows)
### Preparación de la API de Python

1. Instalar Python (versión > 3.6) o Anaconda (versión > 3). Anaconda ya posee una terminal, en caso de instalarse, verificar cómo utilizar una terminal. 

    Si ya se tiene instalado Python verificar versión, ejecutar:
    ```
    python --version
    ```

    Si se tiene instalado Anaconda, buscar Anaconda Prompt en el menú de inicio y ejecutar:

    ```
    conda --version
    ```

2. Instalar librería pyserial, desde el CMD:
    ```
    pip install pyserial
    ```

3. Correr el archivo de python ubicado en:
    ```
    ...\OpenCat-Quadruped-Robot-main\OpenCat-Quadruped-Robot-main\OpenCatPythonAPI\demos\petoiRobotExample.py
    ```




### Prueba de carga y descarga de la batería
- Indicadores
    --
    - Luz roja: Batería baja.
    - Luz azul: Batería con carga.
    
    ![BTplaca](Imagenes/Battery.png)




- Tiempos de carga y descarga
    --
    - Se registran los tiempos de carga del robot luego del primer uso continuo:
    9:30 a. m. - 

    - Se registran los tiempos de descarga del robot luuego del primer uso continuo desde la primera carga completa:



### Archivos necesarios para pruebas básicas
Para las primeras pruebas, haciendo uso de comunicación serial y envío de rutinas predefinidas, se deben utilizar los siguientes archivos de python, incluidos en el repositorio oficial de OpenCat:

#### Archivos necesarios
----
```
C:...\OpenCat-Quadruped-Robot-main\OpenCat-Quadruped-Robot-main\serialMaster> 

ardSerial.py
config.py
SerialCommunication.py
testSkills.py
```

```
C:...\OpenCat-Quadruped-Robot-main\OpenCat-Quadruped-Robot-main\pyUI> 

translate.py
```
