function robotat_bittle_set_joints(robot, q_deg)
    % robotat_bittle_set_joints - Envia un vector de angulos articulares (en grados)
    % simultaneamente al Petoi Bittle mediante la trama binaria 'L'.
    %
    % Orden del vector q_deg (9 elementos estandar):
    %   q_deg = [LF_hip, LF_knee, RF_hip, RF_knee, LB_hip, LB_knee, RB_hip, RB_knee, head]
    %
    % Uso:
    %   robotat_bittle_set_joints(bittle, [0, 0, 0, 0, -45, 45, -45, 45, 0]);

    arguments
        robot struct
        q_deg (1,:) double {mustBeNumeric, mustBeReal}
    end

    if numel(q_deg) ~= 9 && numel(q_deg) ~= 16
        error('El vector q_deg debe contener 9 elementos (estandar) o 16 elementos (trama completa OpenCat).');
    end

    % Saturacion de seguridad para servomotores de OpenCat (-125 a 125 grados)
    max_angle = 125;
    min_angle = -125;
    if any(q_deg > max_angle) || any(q_deg < min_angle)
        warning('Uno o mas angulos exceden el rango [-125, 125] y fueron saturados.');
        q_deg = max(min_angle, min(max_angle, q_deg));
    end

    q_deg = round(q_deg);

    % Construccion del arreglo de 16 canales de OpenCat
    % Nota para expansion (ej. Brazo Robotico en Bittle X V2):
    % Los indices 1, 2 y 3 de 'servos' corresponden a los canales 0, 1 y 2 de la placa.
    if numel(q_deg) == 9
        servos = zeros(1, 16);
        servos(1)  = q_deg(9); % Canal 0:  head (pan)
        servos(9)  = q_deg(1); % Canal 8:  left_front_hip
        servos(13) = q_deg(2); % Canal 12: left_front_knee
        servos(10) = q_deg(3); % Canal 9:  right_front_hip
        servos(14) = q_deg(4); % Canal 13: right_front_knee
        servos(12) = q_deg(5); % Canal 11: left_back_hip
        servos(16) = q_deg(6); % Canal 15: left_back_knee
        servos(11) = q_deg(7); % Canal 10: right_back_hip
        servos(15) = q_deg(8); % Canal 14: right_back_knee
    else
        servos = q_deg;
    end

    % Empaquetado binario: ['L', 16 bytes int8, '~']
    paquete = [uint8('L'), typecast(int8(servos), 'uint8'), uint8('~')];

    if isfield(robot, 'tcpsock') && ~isempty(robot.tcpsock)
        try
            write(robot.tcpsock, paquete, "uint8");
            if robot.tcpsock.NumBytesAvailable > 0
                read(robot.tcpsock, robot.tcpsock.NumBytesAvailable, "uint8");
            end
        catch
            warning('Error al enviar la trama articular al Bittle.');
        end
    end
end