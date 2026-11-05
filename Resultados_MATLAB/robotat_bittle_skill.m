function robotat_bittle_skill(robot, skill_name)
    % robotat_bittle_skill - Envia un comando de locomocion, pose, acrobacia 
    % o configuracion al agente Petoi Bittle (Bittle X / Bittle X V2).
    %
    % Uso:
    %   robotat_bittle_skill(bittle, 'forward');
    %   robotat_bittle_skill(bittle, 'sit');
    %   robotat_bittle_skill(bittle, 'stop');

    arguments
        robot struct
        skill_name (1,:) char {mustBeMember(skill_name, { ...
            ... % --- Locomocion y Marchas (Gaits) ---
            'forward', 'forwardLeft', 'forwardRight', ...
            'back', 'backLeft', 'backRight', ...
            'trot', 'crawl', 'run', 'stepping', ...
            ... % --- Control de Sistema ---
            'stop', 'rest', 'gyro', 'calibration', 'zero', ...
            ... % --- Poses Basicas ---
            'balance', 'sit', 'up', 'buttUp', 'stretch', ...
            'lookup', 'dropped', 'lifted', 'landing', 'table', ...
            ... % --- Acrobacias y Rutinas (Skills) ---
            'hi', 'check', 'pushUp', 'pushUpSingleArm', 'pee', ...
            'angry', 'backFlip', 'frontFlip', 'boxing', 'cheers', ...
            'comeHere', 'dig', 'goodboy', 'handShake', 'handStand', ...
            'handsUp', 'highFive', 'hug', 'jump', 'kick', ...
            'moonWalk', 'nod', 'playDead', 'recover', 'roll', ...
            'scratch', 'sniff', 'testServo', 'waveHead', 'zz' ...
        })}
    end

    % Diccionario unificado: Nombre en ingles -> Token nativo de OpenCat
    % Para agregar nuevas skills en el futuro, anadir el par al switch y al
    % bloque 'arguments' superior.
    switch skill_name
        % Locomocion
        case 'forward',         token = 'kwkF';
        case 'forwardLeft',     token = 'kwkL';
        case 'forwardRight',    token = 'kwkR';
        case 'back',            token = 'kbk';
        case 'backLeft',        token = 'kbkL';
        case 'backRight',       token = 'kbkR';
        case 'trot',            token = 'ktrF';
        case 'crawl',           token = 'kcrF';
        case 'run',             token = 'krnF';
        case 'stepping',        token = 'kvtF';

        % Sistema
        case {'stop', 'rest'},  token = 'd';
        case 'gyro',            token = 'g';
        case 'calibration',     token = 'c';
        case 'zero',            token = 'kzero';

        % Poses Basicas
        case 'balance',         token = 'kbalance';
        case 'sit',             token = 'ksit';
        case 'up',              token = 'kup';
        case 'buttUp',          token = 'kbuttUp';
        case 'stretch',         token = 'kstr';
        case 'lookup',          token = 'lu';
        case 'dropped',         token = 'kdropped';
        case 'lifted',          token = 'klifted';
        case 'landing',         token = 'klnd';
        case 'table',           token = 'ktbl';

        % Acrobacias y Rutinas
        case 'hi',              token = 'khi';
        case 'check',           token = 'kck';
        case 'pushUp',          token = 'kpu';
        case 'pushUpSingleArm', token = 'kpu1';
        case 'pee',             token = 'kpee';
        case 'angry',           token = 'kang';
        case 'backFlip',        token = 'kbf';
        case 'frontFlip',       token = 'kff';
        case 'boxing',          token = 'kbx';
        case 'cheers',          token = 'kchr';
        case 'comeHere',        token = 'kcmh';
        case 'dig',             token = 'kdg';
        case 'goodboy',         token = 'kgdb';
        case 'handShake',       token = 'khsk';
        case 'handStand',       token = 'khds';
        case 'handsUp',         token = 'khu';
        case 'highFive',        token = 'kfiv';
        case 'hug',             token = 'khg';
        case 'jump',            token = 'kjmp';
        case 'kick',            token = 'kkc';
        case 'moonWalk',        token = 'kmw';
        case 'nod',             token = 'knd';
        case 'playDead',        token = 'kpd';
        case 'recover',         token = 'krc';
        case 'roll',            token = 'krl';
        case 'scratch',         token = 'kscrh';
        case 'sniff',           token = 'ksnf';
        case 'testServo',       token = 'kts';
        case 'waveHead',        token = 'kwh';
        case 'zz',              token = 'kzz';
    end

    % Envio por socket TCP si el robot esta conectado fisicamente
    if isfield(robot, 'tcpsock') && ~isempty(robot.tcpsock)
        try
            write(robot.tcpsock, uint8(char(string(token) + newline)));
            if robot.tcpsock.NumBytesAvailable > 0
                read(robot.tcpsock, robot.tcpsock.NumBytesAvailable, "uint8");
            end
        catch
            warning('Error al enviar el comando TCP al Bittle.');
        end
    end
end