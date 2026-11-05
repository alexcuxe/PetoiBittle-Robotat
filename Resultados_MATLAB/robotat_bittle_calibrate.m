function robotat_bittle_calibrate(robot, action, joint_target, offset_deg)
    % robotat_bittle_calibrate - Gestiona el modo de calibracion y ajuste de
    % offsets en la memoria EEPROM del Petoi Bittle.
    %
    % Ejemplos de uso:
    %   robotat_bittle_calibrate(bittle, 'start');
    %   robotat_bittle_calibrate(bittle, 'set', 'left_front_hip', -4);
    %   robotat_bittle_calibrate(bittle, 'set', '8', -4); % Tambien acepta ID
    %   robotat_bittle_calibrate(bittle, 'save');

    arguments
        robot struct
        action (1,:) char {mustBeMember(action, {'start', 'set', 'save'})}
        joint_target (1,:) char {mustBeMember(joint_target, { ...
            'head', ...
            'left_front_hip', 'left_front_knee', ...
            'right_front_hip', 'right_front_knee', ...
            'left_back_hip', 'left_back_knee', ...
            'right_back_hip', 'right_back_knee', ...
            '0', '8', '9', '10', '11', '12', '13', '14', '15', 'none' ...
        })} = 'none'
        offset_deg (1,1) double = 0
    end

    switch action
        case 'start'
            cmd_str = "c" + newline;

        case 'save'
            cmd_str = "s" + newline;

        case 'set'
            if strcmp(joint_target, 'none')
                error('Debe especificar el nombre o ID de la articulacion para ajustar su offset.');
            end

            % Mapeo de nombres amigables (estandar URDF) a IDs de OpenCat
            % Para expandir a Bittle X V2 con brazo, agregar canales '1' y '2'.
            switch joint_target
                case {'head', '0'},             id_motor = 0;
                case {'left_front_hip', '8'},   id_motor = 8;
                case {'right_front_hip', '9'},  id_motor = 9;
                case {'right_back_hip', '10'},  id_motor = 10;
                case {'left_back_hip', '11'},   id_motor = 11;
                case {'left_front_knee', '12'}, id_motor = 12;
                case {'right_front_knee', '13'},id_motor = 13;
                case {'right_back_knee', '14'}, id_motor = 14;
                case {'left_back_knee', '15'},  id_motor = 15;
            end

            % Saturacion preventiva de offset (-25 a 25 grados)
            offset_deg = round(max(-25, min(25, offset_deg)));
            cmd_str = sprintf("c %d %d\n", id_motor, offset_deg);
    end

    if isfield(robot, 'tcpsock') && ~isempty(robot.tcpsock)
        try
            write(robot.tcpsock, uint8(char(cmd_str)));
            if robot.tcpsock.NumBytesAvailable > 0
                read(robot.tcpsock, robot.tcpsock.NumBytesAvailable, "uint8");
            end
        catch
            warning('Error al enviar comando de calibracion al Bittle.');
        end
    end
end