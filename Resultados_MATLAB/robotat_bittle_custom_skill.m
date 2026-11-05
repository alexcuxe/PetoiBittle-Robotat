function robotat_bittle_custom_skill(robot, skill_name, raw_vector)
    % robotat_bittle_custom_skill - Envia una habilidad personalizada en tiempo
    % real al Petoi Bittle utilizando el comando binario 'K'.
    %
    % Presione la tecla TAB al abrir comillas en 'skill_name' para ver las
    % rutinas disponibles en el catalogo.
    %
    % Ejemplos de uso:
    %   robotat_bittle_custom_skill(bittle, 'gait_high_step_forward');
    %   robotat_bittle_custom_skill(bittle, 'gait_stable_crawl');
    %   robotat_bittle_custom_skill(bittle, 'gait_pivot_left');

    arguments
        robot struct
        skill_name (1,:) char {mustBeMember(skill_name, { ...
            'posture_low_guard', ...
            'posture_side_lean', ...
            'behavior_horizon_scan', ...
            'behavior_lateral_sway', ...
            'gait_high_step_forward', ...
            'gait_stable_crawl', ...
            'gait_pivot_left', ...
            'gait_test_vt', ...
            'custom_vector' ...
        })}
        raw_vector double = []
    end

    % 1. Obtener el vector desde el catalogo o desde el tercer argumento
    if strcmp(skill_name, 'custom_vector')
        if isempty(raw_vector)
            error('Si selecciona "custom_vector", debe proporcionar el vector numerico como tercer argumento.');
        end
        var = reshape(double(raw_vector), 1, []);
    else
        var = bittle_custom_skills_data(skill_name);
    end

    % 2. Identificar tipo de skill (Posture, Gait o Behavior) segun var(1)
    period = var(1);
    maxJoints = 16;

    if period > 0
        skillHeader = 4;
    else
        skillHeader = 7;
    end

    if period > 1
        frameSize = 8;          % Gait (8 articulaciones de patas por fila)
    elseif period == 1
        frameSize = maxJoints;  % Posture (16 articulaciones en 1 fila)
    else
        frameSize = 20;         % Behavior (16 articulaciones + 4 parametros por fila)
    end

    % Validar longitud exacta del arreglo antes de enviarlo al robot
    expectedLength = skillHeader + abs(period) * frameSize;
    if numel(var) ~= expectedLength
        error(['Longitud de matriz invalida para el token K. Se esperaban ', ...
               num2str(expectedLength), ' elementos (Header=', num2str(skillHeader), ...
               ' + ', num2str(abs(period)), ' frames x ', num2str(frameSize), ...
               '), pero se recibieron ', num2str(numel(var)), '.']);
    end

    % 3. Auto-escalado de angulos fuera de [-125, 125] (replica de ardSerial.py)
    angleRatio = 1;
    numAngleCols = min(maxJoints, frameSize);

    for row = 0:(abs(period) - 1)
        idx_start = skillHeader + row * frameSize + 1;
        idx_end   = idx_start + numAngleCols - 1;
        angles = var(idx_start:idx_end);

        if any(angles > 125) || any(angles < -125)
            angleRatio = 2;
            break;
        end
    end

    if angleRatio == 2
        var(4) = 2; % El 4to elemento del encabezado indica el angleRatio
        for row = 0:(abs(period) - 1)
            idx_start = skillHeader + row * frameSize + 1;
            idx_end   = idx_start + numAngleCols - 1;
            var(idx_start:idx_end) = fix(var(idx_start:idx_end) / 2);
        end
    end

    % 4. Empaquetado binario: ['K', int8(datos), '~']
    var_int8 = int8(round(var));
    in_bytes = [uint8('K'), typecast(var_int8, 'uint8'), uint8('~')];

    % 5. Envio segmentado (slices de 20 bytes) para no saturar el buffer UART
    if isfield(robot, 'tcpsock') && ~isempty(robot.tcpsock)
        try
            total_bytes = numel(in_bytes);
            slice_idx = 1;
            while slice_idx <= total_bytes
                end_idx = min(slice_idx + 19, total_bytes);
                write(robot.tcpsock, in_bytes(slice_idx:end_idx), "uint8");
                slice_idx = slice_idx + 20;
                pause(0.002);
            end

            % Limpiar confirmacion 'K' del buffer de recepcion
            pause(0.05);
            if robot.tcpsock.NumBytesAvailable > 0
                read(robot.tcpsock, robot.tcpsock.NumBytesAvailable, "uint8");
            end
        catch
            warning('Error al transmitir la rutina personalizada (token K) al Bittle.');
        end
    else
        disp(['[Simulacion] Trama K (', skill_name, ') preparada correctamente (', num2str(numel(in_bytes)), ' bytes).']);
    end
end