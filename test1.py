import sys
sys.path.append("..")
from ardSerial import *

model = 'Bittle'
postureTable = postureDict[model]

E_RGB_ALL = 0
E_RGB_RIGHT = 1
E_RGB_LEFT = 2

E_EFFECT_BREATHING = 0
E_EFFECT_ROTATE = 1
E_EFFECT_FLASH = 2
E_EFFECT_NONE = 3


if __name__ == '__main__':
    try:
        '''
        testSchedule is used to test various serial port commands
        '''
        goodPorts = {}
        connectPort(goodPorts)
        t=threading.Thread(target = keepCheckingPort, args = (goodPorts,))
        t.start()
        parallel = False

        #send(goodPorts, ['kbalance',2]) 
        #send(goodPorts, ['krest',5])
        #send(goodPorts, ['ksit',3]) 
        #send(goodPorts, ['khi',1]) 

        #send(goodPorts,['m', [0, 45, 0, -45, 0, 45, 0, -45], 2])
        #send(goodPorts,['m', [0, 45, 0, -45, 0, 45, 0, -45], 5])
        j = 0

        while 1:
            for i in range(5):
                cmd = int(input("Enter command: "))
                print(i, cmd, j)
                send(goodPorts,['m', [j, cmd], 0.1])
            j = j+1
            #send(goodPorts, ['m', [0, cmd], 0.1])
            #send(goodPorts, ['m', [1, cmd], 0.1])
            #send(goodPorts, ['m', [12, cmd], 1])
            
            # 0 - 7 for leg joints, 8 for tail, 9 for right ear, 10 for left ear, 11 for waist, 12 for neck
            # 0 cabeza
            # 8 pierna izquierda delantera
            # 9 pierna derecha delantera
            # 10 pierna derecha trasera
            # 11 pierna izquierda trasera
            # 12 pata izquierda delantera
            # 13 pata derecha delantera
            # 14 pata derecha trasera
            # 15 pata izquierda trasera


            # # verificar si es texto o numero
            # if isinstance(cmd, str):
            #     break
            # elif isinstance(cmd, int):
            #     cmd = int(cmd),
                


        # send(goodPorts,['kup',1])
        # send(goodPorts,['w',[0,2300],0.1])
        # send(goodPorts,['w',[0,600],0.1])
        # while 1:
        #     send(goodPorts,['W',[100,9,1,100,8,1],0.1]) # digital write. 'd' = 100.
        #     send(goodPorts,['W',[100,9,1,100,8,0],0.1])
        #     send(goodPorts,['W',[100,9,0,100,8,1],0.1])
        #     send(goodPorts,['W',[100,9,0,100,8,0],0.1])
        #     for i in range(8):
        #         send(goodPorts,['W',[97,6,i*30,97,9,255-i*30,97,10,255-i*30],0.1]) # analog write. 'a' = 97.
        #     for i in range(8):
        #         send(goodPorts,['W',[97,6,255-i*30,97,9,i*30,97,10,i*30],0.1])
        #     send(goodPorts,['R',[97,16,97,17],0.1])
        #     time.sleep(1)

    

        closeAllSerial(goodPorts) 
        logger.info("finish!")
        os._exit(0)

    except Exception as e:
        logger.info("Exception")
        closeAllSerial(goodPorts)
        os._exit(0)
        raise e
