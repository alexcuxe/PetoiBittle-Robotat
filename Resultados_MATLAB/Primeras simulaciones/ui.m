%% Integración definitiva Bittle: APP CENTRO DE CONTROL
clear; clc; close all;

% --- 1. CONEXIÓN (CON MODO SIMULACIÓN AUTOMÁTICO) ---
%ip_bittle = "192.168.50.172"; % IP estática Robotat
ip_bittle = "10.28.116.228"; % IP de pruebas, en casa no hacer caso
puerto_tcp = 8116;
puerto = []; % Inicializamos vacío por defecto

disp("Buscando al Bittle en " + ip_bittle + ":" + num2str(puerto_tcp) + "...");
try
    puerto = tcpclient(ip_bittle, puerto_tcp, "Timeout", 2);
    disp("✅ ¡Conectado por TCP con éxito!");
    
    write(puerto, uint8(char(newline + newline + newline + "d" + newline)));
    pause(0.5);
    if puerto.NumBytesAvailable > 0
        read(puerto, puerto.NumBytesAvailable, "char");
    end
    disp("Bittle reiniciado y listo.");
catch ME
    disp("⚠️ No se detectó al Bittle en la red.");
    disp("🚀 Iniciando en MODO SIMULACIÓN OFFLINE (Solo visualización de Interfaz).");
end

% --- 2. CONFIGURACIÓN CINEMÁTICA ---
L1_a = 0.046; L2_a = 0.048; L_cab = 0.045;  

L1 = Revolute('d', 0, 'a', L1_a, 'alpha', 0, 'offset', pi);     
L2 = Revolute('d', 0, 'a', L2_a, 'alpha', 0, 'offset', -pi/2);  
L_head = Revolute('d', 0, 'a', 0, 'alpha', 0, 'offset', pi/2);

LF = SerialLink([L1, L2], 'name', 'LF');
RF = SerialLink([L1, L2], 'name', 'RF');
LB = SerialLink([L1, L2], 'name', 'LB');
RB = SerialLink([L1, L2], 'name', 'RB');
Cabeza = SerialLink(L_head, 'name', 'Cabeza');

LF.base = transl(-0.046, 0.0525, 0) * troty(-pi/2);
RF.base = transl(0.046, 0.0525, 0) * troty(-pi/2);
LB.base = transl(-0.046, -0.0525, 0) * troty(-pi/2);
RB.base = transl(0.046, -0.0525, 0) * troty(-pi/2);
Cabeza.base = transl(0, 0.0635, 0.015); 

% --- 3. DIBUJO DEL ENTORNO 3D (Ventana Clásica Separada) ---
figure('Name', 'Bittle: Simulación Cinemática', 'Position', [550 100 600 550]);
hold on; grid on; axis equal; view(3);

ancho = 0.090; largo = 0.127; alto  = 0.035; z_min = -0.015;
vert_torso = [
   -ancho/2 -largo/2 z_min;      ancho/2 -largo/2 z_min;
    ancho/2  largo/2 z_min;     -ancho/2  largo/2 z_min;
   -ancho/2 -largo/2 z_min+alto; ancho/2 -largo/2 z_min+alto;
    ancho/2  largo/2 z_min+alto;-ancho/2  largo/2 z_min+alto
];
caras = [1 2 3 4; 5 6 7 8; 1 2 6 5; 2 3 7 6; 3 4 8 7; 4 1 5 8];
patch('Vertices', vert_torso, 'Faces', caras, ...
      'FaceColor', [0.2 0.2 0.2], 'FaceAlpha', 0.6, 'EdgeColor', 'k', 'LineWidth', 1.2);
      
a_cab = 0.040; l_cab = 0.045; h_cab = 0.025; 
vert_cab_local = [
    0      -a_cab/2 -h_cab/2;  l_cab -a_cab/2 -h_cab/2;
    l_cab   a_cab/2 -h_cab/2;  0      a_cab/2 -h_cab/2;
    0      -a_cab/2  h_cab/2;  l_cab -a_cab/2  h_cab/2;
    l_cab   a_cab/2  h_cab/2;  0      a_cab/2  h_cab/2
];
T_inicial = double(Cabeza.fkine(0)); 
vert_globales = (T_inicial * [vert_cab_local, ones(8,1)]')';
h_cabeza = patch('Vertices', vert_globales(:,1:3), 'Faces', caras, ...
                 'FaceColor', [0.85 0.55 0.1], 'FaceAlpha', 0.9, 'EdgeColor', 'k');

LF.plot([0 0], 'workspace', [-0.2 0.2 -0.2 0.2 -0.2 0.2]);
RF.plot([0 0]); LB.plot([0 0]); RB.plot([0 0]); 

% --- 4. LANZAR EL PANEL DE CONTROL APP ---
construir_app_bittle(LF, RF, LB, RB, Cabeza, h_cabeza, vert_cab_local, puerto);

%% --- FUNCIONES DE LA APLICACIÓN ---

function construir_app_bittle(LF, RF, LB, RB, Cabeza, h_cabeza, vert_cab_local, puerto)
    % Ventana exclusiva para los controles
    appFig = uifigure('Name', 'Robotat Bittle - Centro de Control', 'Position', [80 100 450 650]);
    appFig.UserData = zeros(1, 9); % Memoria global (Q actual en grados)
    
    tgroup = uitabgroup(appFig, 'Position', [0 0 450 650]);
    
    % =========================================================
    % PESTAÑA 1: CONTROL MANUAL
    % =========================================================
    tab1 = uitab(tgroup, 'Title', 'Control Manual');
    
    nombres_sliders = {'LF Cadera', 'LF Rodilla', 'RF Cadera', 'RF Rodilla', ...
                       'LB Cadera', 'LB Rodilla', 'RB Cadera', 'RB Rodilla', 'Cabeza (Pan)'};
    for i = 1:9
        uilabel(tab1, 'Position', [20, 560 - i*60, 100, 20], 'Text', nombres_sliders{i});
        uislider(tab1, 'Position', [130, 570 - i*60, 250, 3], ...
            'Limits', [-90 90], 'Value', 0, ...
            'ValueChangingFcn', @(src, event) actualizar_articulacion(i, event.Value, LF, RF, LB, RB, Cabeza, h_cabeza, vert_cab_local, puerto, appFig));
    end

    % =========================================================
    % PESTAÑA 2: CALIBRACIÓN INTUITIVA
    % =========================================================
    tab2 = uitab(tgroup, 'Title', 'Calibración');
    
    uilabel(tab2, 'Position', [20 570 300 30], 'Text', 'Asistente de Calibración', 'FontSize', 16, 'FontWeight', 'bold');
    uilabel(tab2, 'Position', [20 530 400 40], 'Text', '1. Inicia el modo de calibración. El robot adoptará la postura base de calibración.', 'WordWrap', 'on');
    
    uibutton(tab2, 'Position', [20, 490, 250, 40], 'Text', 'Iniciar Modo Calibración ("c")', ...
             'ButtonPushedFcn', @(~,~) enviar_tcp_seguro(puerto, "c\n"));
             
    uilabel(tab2, 'Position', [20 440 400 20], 'Text', '2. Selecciona la articulación que deseas alinear:');
    
    % Menú desplegable con nombres amigables y sus valores reales de hardware en OpenCat
    nombres_joints = {'Cabeza', 'Frontal Izquierda - Cadera', 'Frontal Izquierda - Rodilla', ...
                      'Frontal Derecha - Cadera', 'Frontal Derecha - Rodilla', ...
                      'Trasera Izquierda - Cadera', 'Trasera Izquierda - Rodilla', ...
                      'Trasera Derecha - Cadera', 'Trasera Derecha - Rodilla'};
    ids_joints = [0, 8, 12, 9, 13, 11, 15, 10, 14];
    
    dd_calib = uidropdown(tab2, 'Position', [20, 410, 250, 30], ...
                          'Items', nombres_joints, 'ItemsData', ids_joints);
                          
    uilabel(tab2, 'Position', [20 370 400 20], 'Text', '3. Ajusta el Offset (El robot se moverá en tiempo real):');
    
    % Slider para calibrar
    sld_offset = uislider(tab2, 'Position', [40, 340, 300, 3], ...
             'Limits', [-20 20], 'Value', 0);
             
    % Indicador numérico del offset
    lbl_offset_val = uilabel(tab2, 'Position', [360, 330, 40, 20], 'Text', '0°', 'FontWeight', 'bold');

    % Acción al mover el slider de calibración
    sld_offset.ValueChangingFcn = @(src, event) aplicar_offset_en_vivo(dd_calib.Value, round(event.Value), puerto, lbl_offset_val);
    
    % Resetear slider a 0 cuando el usuario cambia de articulación en el dropdown
    dd_calib.ValueChangedFcn = @(src, event) resetear_slider_calib(sld_offset, lbl_offset_val);

    uilabel(tab2, 'Position', [20 260 400 40], 'Text', '4. Cuando todas las patas estén perfectamente alineadas, guarda los datos en la memoria EEPROM de la placa.', 'WordWrap', 'on');
    uibutton(tab2, 'Position', [20, 210, 250, 40], 'Text', 'GUARDAR EN EEPROM ("s")', ...
             'BackgroundColor', [0.8 0.2 0.2], 'FontColor', [1 1 1], ...
             'ButtonPushedFcn', @(~,~) enviar_tcp_seguro(puerto, "s\n"));

    % =========================================================
    % PESTAÑA 3: HABILIDADES (SKILLS INTERACTIVOS)
    % =========================================================
    tab3 = uitab(tgroup, 'Title', 'Habilidades');
    
    uilabel(tab3, 'Position', [20 570 300 30], 'Text', 'Panel de Acciones Predefinidas', 'FontSize', 16, 'FontWeight', 'bold');
    
    % Crear un Layout de Cuadrícula para los botones (6 filas x 2 columnas)
    panelGrid = uipanel(tab3, 'Position', [20 50 400 500]);
    gl = uigridlayout(panelGrid, [7 2]); 
    gl.RowHeight = repmat({'1x'}, 1, 7);
    gl.ColumnWidth = {'1x', '1x'};
    
    % Diccionario de Acciones (Basado en tu archivo actions.h)
    acciones = {
        'Reposo / Detener', 'd';
        'Balance', 'kbalance';
        'Sentarse', 'ksit';
        'Levantar Trasero', 'kbuttUp';
        'Saludar', 'khi';
        'Dar la pata / Check', 'kck';
        'Lagartijas', 'kpu';
        'Hacer del Baño', 'kpee';
        'Estirarse', 'kstr';
        'Mirar Arriba', 'lu';
        'Caminar Adelante', 'kwkF';
        'Trote Adelante', 'ktrF';
        'Marcha en Sitio', 'kvtF';
        'Giroscopio On/Off', 'g'
    };

    % Generar botones dinámicamente
    for k = 1:size(acciones, 1)
        btn_nombre = acciones{k, 1};
        btn_comando = acciones{k, 2};
        
        btn = uibutton(gl, 'Text', btn_nombre, 'FontSize', 14);
        % Asignamos la función del botón. sprintf("%s\n") le agrega el Enter clave.
        btn.ButtonPushedFcn = @(~,~) enviar_tcp_seguro(puerto, sprintf("%s\n", btn_comando));
    end
end

% --- FUNCIONES AUXILIARES Y DE COMUNICACIÓN ---

function enviar_tcp_seguro(puerto, comando)
    if ~isempty(puerto)
        try
            write(puerto, uint8(char(comando)));
        catch
            disp("Error de red al enviar comando.");
        end
    else
        % En modo offline, imprime en consola lo que habría enviado
        comando_limpio = strrep(string(comando), newline, '\n');
        disp("Simulación: Comando enviado -> [" + comando_limpio + "]");
    end
end

% Función para la Pestaña 2: Calibración en vivo
function aplicar_offset_en_vivo(id_motor, offset_val, puerto, lbl_ui)
    % Actualizar etiqueta de texto
    lbl_ui.Text = sprintf('%d°', offset_val);
    
    % Enviar comando de offset a la placa (Ej: "c 8 -5\n")
    comando = sprintf("c %d %d\n", id_motor, offset_val);
    enviar_tcp_seguro(puerto, comando);
end

function resetear_slider_calib(sld, lbl_ui)
    % Se llama al cambiar el menú desplegable para no arrastrar un offset a otro motor
    sld.Value = 0;
    lbl_ui.Text = '0°';
end

% Función para la Pestaña 1: Control Manual con Sliders
function actualizar_articulacion(indice, valor, LF, RF, LB, RB, Cabeza, h_cabeza, vert_cab_local, puerto, fig)
    % 1. Actualizar Memoria Visual
    q_grados = fig.UserData;
    q_grados(indice) = valor; 
    fig.UserData = q_grados;  
    
    % 2. Animar 3D
    q_rad = deg2rad(q_grados);
    LF.animate([q_rad(1), q_rad(2)]);
    RF.animate([q_rad(3), q_rad(4)]);
    LB.animate([q_rad(5), q_rad(6)]);
    RB.animate([q_rad(7), q_rad(8)]);
    
    T_head = double(Cabeza.fkine(q_rad(9))); 
    vert_temp = (T_head * [vert_cab_local, ones(8,1)]')';
    h_cabeza.Vertices = vert_temp(:, 1:3);

    % 3. Enviar Comando 'L' (Solo si hay conexión real)
    if ~isempty(puerto)
        servos = zeros(1, 16);
        servos(1)  = round(q_grados(9)); 
        servos(9)  = round(q_grados(1)); servos(13) = round(q_grados(2));  
        servos(10) = round(q_grados(3)); servos(14) = round(q_grados(4));  
        servos(12) = round(q_grados(5)); servos(16) = round(q_grados(6));  
        servos(11) = round(q_grados(7)); servos(15) = round(q_grados(8));  
        
        paquete = [uint8('L'), typecast(int8(servos), 'uint8'), uint8('~')];
        
        try
            write(puerto, paquete, "uint8");
            if puerto.NumBytesAvailable > 0; read(puerto, puerto.NumBytesAvailable, "uint8"); end
            pause(0.02); 
        catch 
        end
    end
end