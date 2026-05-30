import roboticstoolbox as rtb
import numpy as np

# 1. Cargar el robot
robot = rtb.ERobot.URDF(r"C:\Users\Cris\Documents\GitHub\PetoiBittle-Robotat\bittle_headed.urdf")

# 2. Inicializar la configuración de articulaciones (q) a ceros
# Como tu robot tiene varias articulaciones, creamos un arreglo de ceros
robot.q = np.zeros(robot.n)

# 3. Visualizar
# Ahora, al no estar Swift, detectará automáticamente Matplotlib
print("Visualizando el robot...")
robot.plot(robot.q, block=True)