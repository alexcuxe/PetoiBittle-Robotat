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
            robot.ip = '10.63.16.228'; 
        case 3
            robot.ip = '192.168.50.174'; 
        otherwise
            error('ID de agente inválido. Asegúrese de que el Bittle esté registrado en la función de conexión.');
    end
    
    %disp(['Buscando al Bittle ' num2str(robot.id) ' en ' robot.ip ':' num2str(robot.port) '...']);
    
    try
        % "ConnectTimeout" limita el intento de conexión a 5 segundos exactos.
        % "Timeout" limita las lecturas/escrituras posteriores a 2 segundos.
        tcpsock = tcpclient(robot.ip, robot.port, "ConnectTimeout", 5, "Timeout", 2);
        robot.tcpsock = tcpsock;
        disp(['¡Conectado al Bittle ' num2str(robot.id) '!']);
        
        % Secuencia de limpieza para la Nyboard
        write(robot.tcpsock, uint8(char(newline + newline + newline + "d" + newline)));
        pause(0.5); 
        
        % Limpieza del buffer de entrada
        if robot.tcpsock.NumBytesAvailable > 0
            read(robot.tcpsock, robot.tcpsock.NumBytesAvailable, "char");
        end
        
    catch ME
        % Si pasan los 5 segundos sin éxito, cae inmediatamente aquí
        disp('ERROR: No se pudo conectar al robot.');
        % Devolver el tcpsock vacío para evitar crasheos en otras funciones
        robot.tcpsock = []; 
    end
end