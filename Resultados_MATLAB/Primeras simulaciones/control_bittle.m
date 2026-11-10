% Guardar como: control_bittle.m
% Visualizador Cinemático Universal para URDF (Estilo .teach)

% 0. Limpiar todo el entorno
clear; clc; close all; 
warning('off', 'all');

% 1. Ruta por defecto (si no existe en la PC, abre ventana para buscar el URDF)
carpeta_defecto = 'C:\Users\Cris\Desktop\Proyectos Alex\Diseño e Innovación\bittle\bittle-x (1)\bittle_x';
urdf_defecto = fullfile(carpeta_defecto, 'urdf', 'bittle_x.urdf');

if isfile(urdf_defecto)
    ruta_urdf = urdf_defecto;
    carpeta_paquete = carpeta_defecto;
else
    [archivo, ruta] = uigetfile({'*.urdf', 'Archivos URDF (*.urdf)'}, 'Selecciona el archivo URDF');
    if isequal(archivo, 0), return; end
    ruta_urdf = fullfile(ruta, archivo);
    % Subir un nivel si el URDF está dentro de una subcarpeta '/urdf'
    [carpeta_padre, nombre_carpeta] = fileparts(erase(ruta, filesep + textBoundary("end")));
    if strcmpi(nombre_carpeta, 'urdf')
        carpeta_paquete = carpeta_padre;
    else
        carpeta_paquete = ruta;
    end
end

% Lanzar la interfaz con el archivo seleccionado
iniciarInterfaz(ruta_urdf, carpeta_paquete);


% =========================================================================
% FUNCIÓN PRINCIPAL DE CREACIÓN DE INTERFAZ
% =========================================================================
function iniciarInterfaz(ruta_urdf, carpeta_paquete)
    warning('off', 'all');
    
    % 1. Limpieza universal del URDF (elimina cualquier 'package://nombre/' e inercias)
    texto_urdf = fileread(ruta_urdf);
    texto_limpio = regexprep(texto_urdf, 'package://[^/]+/', '');
    texto_limpio = regexprep(texto_limpio, '(?s)<inertial>.*?</inertial>', '');
    texto_limpio = regexprep(texto_limpio, '(?s)<collision>.*?</collision>', '');
    
    ruta_limpia = fullfile(carpeta_paquete, 'robot_cinematico_temp.urdf');
    fid = fopen(ruta_limpia, 'w', 'n', 'utf-8');
    fwrite(fid, texto_limpio, 'char');
    fclose(fid);

    % 2. Cargar el robot y configuración inicial
    robot = importrobot(ruta_limpia, 'MeshPath', carpeta_paquete);
    config = homeConfiguration(robot);
    num_juntas = length(config);

    % 3. Crear la figura principal (Modo oscuro)
    fig = figure('Name', 'Control Cinemático Universal URDF', 'Position', [100 80 1050 680], ...
                 'MenuBar', 'none', 'NumberTitle', 'off', 'Color', [0.15 0.15 0.15]);

    % Estructura de datos global
    guiData.robot = robot;
    guiData.config = config;
    guiData.homeConfig = config;
    guiData.az = -45;          % Vista predeterminada (Acimut)
    guiData.el = 25;           % Vista predeterminada (Elevación)
    guiData.limEjes = 0.15;    % Límite de los ejes en metros (+/- 0.15 m)
    guiData.isRotating = false;
    guiData.lastMousePos = [0 0];

    % 4. Crear el eje 3D y dibujar estado inicial
    ax = axes(fig, 'Position', [0.36 0.1 0.6 0.82]);
    show(robot, config, 'Parent', ax, 'PreservePlot', false, ...
        'Collisions', 'off', 'Visuals', 'on', 'Frames', 'off');

    % Configurar cámara inicial y capturar el ángulo exacto de lente (evita saltos)
    try disableDefaultInteractivity(ax); catch, end
    axis(ax, 'normal');
    xlim(ax, [-guiData.limEjes, guiData.limEjes]);
    ylim(ax, [-guiData.limEjes, guiData.limEjes]);
    zlim(ax, [-guiData.limEjes, guiData.limEjes]);
    daspect(ax, [1 1 1]);
    pbaspect(ax, [1 1 1]);
    view(ax, [guiData.az, guiData.el]);
    axis(ax, 'vis3d');
    
    % Guardamos las constantes ópticas para que NUNCA salte la vista al usar sliders
    guiData.camViewAngle = ax.CameraViewAngle;
    guiData.camTarget = [0 0 0];
    ax.CameraTarget = guiData.camTarget;
    
    set(ax, 'Color', [0.15 0.15 0.15], 'XColor', 'w', 'YColor', 'w', 'ZColor', 'w');
    grid(ax, 'on');
    title(ax, 'Simulación Interactiva (Arrastra con el ratón para rotar)', 'Color', 'w');

    % 5. Controles superiores (Escala de ejes, Botón Home y Cargar otro URDF)
    uicontrol(fig, 'Style', 'text', 'Position', [15, 640, 95, 20], ...
        'String', 'Límite Ejes (m):', 'HorizontalAlignment', 'left', ...
        'FontWeight', 'bold', 'BackgroundColor', [0.15 0.15 0.15], 'ForegroundColor', [0.8 0.8 0.8]);
    
    uicontrol(fig, 'Style', 'edit', 'Position', [110, 642, 45, 20], ...
        'String', num2str(guiData.limEjes), ...
        'Callback', @(src, ~) cambiarEscalaEjes(src, fig, ax));

    uicontrol(fig, 'Style', 'pushbutton', 'Position', [165, 640, 80, 24], ...
        'String', 'Home (0°)', 'FontWeight', 'bold', ...
        'Callback', @(~, ~) resetearHome(fig, ax));

    uicontrol(fig, 'Style', 'pushbutton', 'Position', [255, 640, 90, 24], ...
        'String', 'Otro URDF...', ...
        'Callback', @(~, ~) cargarNuevoURDF(fig));

    % 6. Crear Sliders dinámicos leyendo los límites reales de cada articulación
    y_pos = 595;
    paso_y = min(35, floor(550 / max(1, num_juntas))); % Se adapta si hay muchas juntas

    for i = 1:num_juntas
        nombre_junta = config(i).JointName;
        
        % Buscar los límites configurados en el URDF para esta junta
        [min_deg, max_deg] = obtenerLimitesJunta(robot, nombre_junta);
        
        valor_inicial_grados = rad2deg(config(i).JointPosition);
        valor_inicial_grados = max(min_deg, min(max_deg, valor_inicial_grados));
        rango = max_deg - min_deg;
        
        % Etiqueta
        uicontrol(fig, 'Style', 'text', 'Position', [10, y_pos, 130, 20], ...
            'String', strrep(nombre_junta, '_', ' '), 'HorizontalAlignment', 'right', ...
            'FontWeight', 'bold', 'BackgroundColor', [0.15 0.15 0.15], 'ForegroundColor', 'w');
        
        % Slider con los límites de la articulación y paso de 0.5°
        sld = uicontrol(fig, 'Style', 'slider', 'Position', [150, y_pos, 130, 20], ...
            'Min', min_deg, 'Max', max_deg, 'Value', valor_inicial_grados, ...
            'SliderStep', [0.5/rango, 5/rango]);
            
        % Cuadro de texto editable
        edt = uicontrol(fig, 'Style', 'edit', 'Position', [290, y_pos, 55, 20], ...
            'String', num2str(valor_inicial_grados, '%.1f'), ...
            'TooltipString', sprintf('Límites: [%.1f°, %.1f°]', min_deg, max_deg));
            
        guiData.sliders(i) = sld;
        guiData.edits(i) = edt;
        
        % Vínculos
        addlistener(sld, 'ContinuousValueChange', @(src, ~) actualizarDesdeSlider(src, edt, fig, ax, i));
        sld.Callback = @(src, ~) actualizarDesdeSlider(src, edt, fig, ax, i);
        edt.Callback = @(src, ~) actualizarDesdeTexto(edt, sld, fig, ax, i);
        
        y_pos = y_pos - paso_y; 
    end

    fig.UserData = guiData;

    % 7. Eventos de ratón para rotación 3D fluida
    fig.WindowButtonDownFcn = @(src, ~) iniciarRotacion(src);
    fig.WindowButtonMotionFcn = @(src, ~) rotarVista(src, ax);
    fig.WindowButtonUpFcn = @(src, ~) terminarRotacion(src);

    warning('on', 'all');
end

% =========================================================================
% FUNCIONES AUXILIARES Y CALLBACKS
% =========================================================================
function [min_deg, max_deg] = obtenerLimitesJunta(robot, nombre_junta)
    min_deg = -180; 
    max_deg = 180;
    for k = 1:length(robot.Bodies)
        jnt = robot.Bodies{k}.Joint;
        if strcmp(jnt.Name, nombre_junta)
            lims = rad2deg(jnt.PositionLimits);
            % Validar que los límites sean finitos y válidos
            if all(isfinite(lims)) && lims(2) > lims(1)
                min_deg = lims(1);
                max_deg = lims(2);
            end
            break;
        end
    end
end

function aplicarEstadoCamara(ax, guiData)
    % Mantiene exactamente la misma lente (camViewAngle) sin reajustes automáticos
    try disableDefaultInteractivity(ax); catch, end
    xlim(ax, [-guiData.limEjes, guiData.limEjes]);
    ylim(ax, [-guiData.limEjes, guiData.limEjes]);
    zlim(ax, [-guiData.limEjes, guiData.limEjes]);
    daspect(ax, [1 1 1]);
    pbaspect(ax, [1 1 1]);
    ax.CameraTarget = guiData.camTarget;
    ax.CameraViewAngle = guiData.camViewAngle;
    view(ax, [guiData.az, guiData.el]);
    set(ax, 'Color', [0.15 0.15 0.15], 'XColor', 'w', 'YColor', 'w', 'ZColor', 'w');
    grid(ax, 'on');
    title(ax, 'Simulación Interactiva (Arrastra con el ratón para rotar)', 'Color', 'w');
end

function iniciarRotacion(fig)
    pt = fig.CurrentPoint;
    if pt(1) > 355 % Solo rotar si el clic ocurre en la zona derecha del gráfico
        guiData = fig.UserData;
        guiData.isRotating = true;
        guiData.lastMousePos = pt;
        fig.UserData = guiData;
    end
end

function rotarVista(fig, ax)
    guiData = fig.UserData;
    if isfield(guiData, 'isRotating') && guiData.isRotating
        pt = fig.CurrentPoint;
        delta = pt - guiData.lastMousePos;
        
        guiData.az = guiData.az - delta(1) * 0.5;
        guiData.el = max(-89, min(89, guiData.el - delta(2) * 0.5));
        guiData.lastMousePos = pt;
        fig.UserData = guiData;
        
        view(ax, [guiData.az, guiData.el]);
        drawnow limitrate;
    end
end

function terminarRotacion(fig)
    guiData = fig.UserData;
    guiData.isRotating = false;
    fig.UserData = guiData;
end

function actualizarDesdeSlider(sld, edt, fig, ax, idx)
    val_grados = sld.Value;
    edt.String = num2str(val_grados, '%.1f'); 
    moverRobot(fig, ax, idx, val_grados);
end

function actualizarDesdeTexto(edt, sld, fig, ax, idx)
    val_grados = str2double(edt.String);
    if isnan(val_grados) || val_grados < sld.Min
        val_grados = sld.Min;
    elseif val_grados > sld.Max
        val_grados = sld.Max;
    end
    edt.String = num2str(val_grados, '%.1f'); 
    sld.Value = val_grados; 
    moverRobot(fig, ax, idx, val_grados);
end

function moverRobot(fig, ax, idx, val_grados)
    guiData = fig.UserData;
    guiData.config(idx).JointPosition = deg2rad(val_grados);
    fig.UserData = guiData;
    
    show(guiData.robot, guiData.config, 'Parent', ax, 'PreservePlot', false, ...
        'FastUpdate', true, 'Collisions', 'off', 'Visuals', 'on', 'Frames', 'off');
        
    aplicarEstadoCamara(ax, guiData);
    drawnow limitrate;
end

function cambiarEscalaEjes(edt, fig, ax)
    nuevo_lim = str2double(edt.String);
    guiData = fig.UserData;
    if ~isnan(nuevo_lim) && nuevo_lim > 0
        guiData.limEjes = nuevo_lim;
        fig.UserData = guiData;
        aplicarEstadoCamara(ax, guiData);
    else
        edt.String = num2str(guiData.limEjes);
    end
end

function resetearHome(fig, ax)
    guiData = fig.UserData;
    guiData.config = guiData.homeConfig;
    for i = 1:length(guiData.config)
        val_deg = rad2deg(guiData.config(i).JointPosition);
        guiData.sliders(i).Value = val_deg;
        guiData.edits(i).String = num2str(val_deg, '%.1f');
    end
    fig.UserData = guiData;
    
    show(guiData.robot, guiData.config, 'Parent', ax, 'PreservePlot', false, ...
        'FastUpdate', true, 'Collisions', 'off', 'Visuals', 'on', 'Frames', 'off');
    aplicarEstadoCamara(ax, guiData);
    drawnow;
end

function cargarNuevoURDF(fig_actual)
    [archivo, ruta] = uigetfile({'*.urdf', 'Archivos URDF (*.urdf)'}, 'Selecciona el nuevo archivo URDF');
    if isequal(archivo, 0), return; end
    ruta_urdf = fullfile(ruta, archivo);
    [carpeta_padre, nombre_carpeta] = fileparts(erase(ruta, filesep + textBoundary("end")));
    if strcmpi(nombre_carpeta, 'urdf')
        carpeta_paquete = carpeta_padre;
    else
        carpeta_paquete = ruta;
    end
    close(fig_actual);
    iniciarInterfaz(ruta_urdf, carpeta_paquete);
end