%% Limpieza
clear; clc; close all;

%% Conexión al Robotat 
robotat = robotat_connect();

%% Conexión con el agente Bittle usando la nueva librería
%ip_bittle = "192.168.50.172"; 
%ittle = robotat_bittle_connect(ip_bittle); % Puerto 8116 es por defecto
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
        
        % Obtener posicion de la meta
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
        comando_anterior = comando_actual; % guardar comando anterior para no saturar puerto
        
        % Asignar comando según eP (posición) y eO (error angular)
        if eP < 180
            comando_actual = "rest";                 
        elseif abs(eO) > deg2rad(5)
            if eO > 0
                comando_actual = "forwardLeft";
                %dt = 0.25;
            else
                comando_actual = "forwardRight";  
                %dt = 0.25;
            end
        else
            comando_actual = "forward"; 
            %dt = 1;
        end
        
        % Envio de comando al Bittle (OJO: Aquí aún usamos write directo temporalmente)
        % En el siguiente paso crearemos "robotat_bittle_send_skill" para ocultar este write.
        if comando_actual ~= comando_anterior
            robotat_bittle_skill(bittle,comando_actual);
        end
        
        pause(dt); 
    end
catch ME
    disp('Bucle interrumpido (Error o Ctrl+C). Cerrando conexiones...');
    % Las nuevas librerías al rescate
    robotat_bittle_disconnect(bittle);
    robotat_disconnect(robotat);
    rethrow(ME);
end

%% Desconexión normal al finalizar
%robotat_bittle_disconnect(bittle);
%robotat_disconnect(robotat);



%% pruebas video
clear;
clc;

robot_no = 1;
bittle = robotat_bittle_connect(1);
robotat_bittle_skill(bittle,"rest");
pause(5);
robotat_bittle_skill(bittle,"hi");
