classdef BittleApp < matlab.apps.AppBase
    % BittleApp - Centro de Control y Visualizador Cinematico URDF (App Designer)
    % Integrado con la libreria modular robotat_bittle_...
    % Guardar este archivo como: BittleApp.m

    properties (Access = public)
        UIFigure            matlab.ui.Figure
        MainLayout          matlab.ui.container.GridLayout
        
        % Panel Izquierdo (Controles y Pestanas)
        LeftPanel           matlab.ui.container.Panel
        ConnPanel           matlab.ui.container.Panel
        SpinAgentID         matlab.ui.control.Spinner
        BtnConnect          matlab.ui.control.Button
        LblStatus           matlab.ui.control.Label
        SwLiveSend          matlab.ui.control.Switch
        
        TabGroup            matlab.ui.container.TabGroup
        TabManual           matlab.ui.container.Tab
        TabCalib            matlab.ui.container.Tab
        TabSkills           matlab.ui.container.Tab
        
        % Controles de Calibracion (Pestana 2)
        DdCalibJoint        matlab.ui.control.DropDown
        SldCalibOffset      matlab.ui.control.Slider
        EdtCalibOffset      matlab.ui.control.NumericEditField
        
        % Panel Derecho (Entorno 3D URDF)
        RightPanel          matlab.ui.container.Panel
        Toolbar3D           matlab.ui.container.Panel
        EdtLimEjes          matlab.ui.control.NumericEditField
        BtnHome             matlab.ui.control.Button
        BtnLoadURDF         matlab.ui.control.Button
        CanvasPanel         matlab.ui.container.Panel
        Ax3D                matlab.graphics.axis.Axes
    end

    properties (Access = private)
        % Propiedades del Robot URDF y Camara
        RobotURDF
        Config
        HomeConfig
        Sliders             matlab.ui.control.Slider
        Edits               matlab.ui.control.NumericEditField
        
        Az                  double = -45
        El                  double = 25
        LimEjes             double = 0.15
        CamViewAngle        double
        CamTarget           double = [0 0 0]
        IsRotating          logical = false
        LastMousePos        double = [0 0]
        
        % Propiedades de Conexion y Estado Fisico (Robotat Bittle)
        AgenteBittle        struct = struct('id', 1, 'ip', '', 'port', 8116, 'type', 'Petoi Bittle', 'tcpsock', [])
        TimerEnvio          uint64
        CalibOffsets        containers.Map
    end

    methods (Access = private)

        function startupFcn(app)
            warning('off', 'all');
            app.TimerEnvio = tic;
            
            % Inicializar memoria local de offsets de calibracion en 0 grados
            nombres_urdf = {'head', 'left_front_hip', 'left_front_knee', ...
                            'right_front_hip', 'right_front_knee', ...
                            'left_back_hip', 'left_back_knee', ...
                            'right_back_hip', 'right_back_knee'};
            app.CalibOffsets = containers.Map(nombres_urdf, zeros(1, 9));
            
            % 1. Buscar ruta por defecto del URDF o abrir selector
            % ejemplo de la ruta específicada
            % carpeta_defecto = 'C:\Users\User\Desktop\Diseño e Innovación\bittle\bittle_x';
            carpeta_defecto = 'C:\Users\...\bittle_x'; % Colocar ruta completa al archivo .urdf
            urdf_defecto = fullfile(carpeta_defecto, 'urdf', 'bittle_x.urdf');
            
            if isfile(urdf_defecto)
                ruta_urdf = urdf_defecto;
                carpeta_paquete = carpeta_defecto;
            else
                [ruta_urdf, carpeta_paquete] = app.seleccionarArchivoURDF();
                if isempty(ruta_urdf)
                    return;
                end
            end
            
            % 2. Cargar URDF y generar controles
            app.cargarModeloURDF(ruta_urdf, carpeta_paquete);
        end

        function [ruta_urdf, carpeta_paquete] = seleccionarArchivoURDF(~)
            [archivo, ruta] = uigetfile({'*.urdf', 'Archivos URDF (*.urdf)'}, 'Selecciona el archivo URDF');
            if isequal(archivo, 0)
                ruta_urdf = ''; carpeta_paquete = '';
                return;
            end
            ruta_urdf = fullfile(ruta, archivo);
            [carpeta_padre, nombre_carpeta] = fileparts(erase(ruta, filesep + textBoundary("end")));
            if strcmpi(nombre_carpeta, 'urdf')
                carpeta_paquete = carpeta_padre;
            else
                carpeta_paquete = ruta;
            end
        end

        function cargarModeloURDF(app, ruta_urdf, carpeta_paquete)
            warning('off', 'all');
            
            % 1. Limpieza universal del URDF
            texto_urdf = fileread(ruta_urdf);
            texto_limpio = regexprep(texto_urdf, 'package://[^/]+/', '');
            texto_limpio = regexprep(texto_limpio, '(?s)<inertial>.*?</inertial>', '');
            texto_limpio = regexprep(texto_limpio, '(?s)<collision>.*?</collision>', '');
            
            ruta_limpia = fullfile(carpeta_paquete, 'robot_cinematico_temp.urdf');
            fid = fopen(ruta_limpia, 'w', 'n', 'utf-8');
            fwrite(fid, texto_limpio, 'char');
            fclose(fid);

            % 2. Importar rigidBodyTree
            app.RobotURDF = importrobot(ruta_limpia, 'MeshPath', carpeta_paquete);
            app.Config = homeConfiguration(app.RobotURDF);
            app.HomeConfig = app.Config;

            % 3. Crear o limpiar el eje 3D tradicional dentro del CanvasPanel
            if isempty(app.Ax3D) || ~isvalid(app.Ax3D)
                app.Ax3D = axes(app.CanvasPanel, 'Units', 'normalized', 'Position', [0.05 0.05 0.9 0.9]);
            else
                cla(app.Ax3D, 'reset');
            end

            show(app.RobotURDF, app.Config, 'Parent', app.Ax3D, 'PreservePlot', false, ...
                'Collisions', 'off', 'Visuals', 'on', 'Frames', 'off');

            try disableDefaultInteractivity(app.Ax3D); catch, end
            axis(app.Ax3D, 'normal');
            xlim(app.Ax3D, [-app.LimEjes, app.LimEjes]);
            ylim(app.Ax3D, [-app.LimEjes, app.LimEjes]);
            zlim(app.Ax3D, [-app.LimEjes, app.LimEjes]);
            daspect(app.Ax3D, [1 1 1]);
            pbaspect(app.Ax3D, [1 1 1]);
            view(app.Ax3D, [app.Az, app.El]);
            axis(app.Ax3D, 'vis3d');

            app.CamViewAngle = app.Ax3D.CameraViewAngle;
            app.CamTarget = [0 0 0];
            app.Ax3D.CameraTarget = app.CamTarget;

            set(app.Ax3D, 'Color', [0.15 0.15 0.15], 'XColor', 'w', 'YColor', 'w', 'ZColor', 'w');
            grid(app.Ax3D, 'on');
            title(app.Ax3D, 'Simulación Interactiva (Arrastra con el ratón para rotar)', 'Color', 'w');

            % 4. Regenerar Sliders dinamicamente en la Pestana 1
            delete(app.TabManual.Children);
            num_juntas = length(app.Config);
            app.Sliders = matlab.ui.control.Slider.empty;
            app.Edits = matlab.ui.control.NumericEditField.empty;

            y_pos = 455;
            paso_y = min(44, floor(440 / max(1, num_juntas)));

            for i = 1:num_juntas
                nombre_junta = app.Config(i).JointName;
                [min_deg, max_deg] = app.obtenerLimitesJunta(nombre_junta);
                val_ini = max(min_deg, min(max_deg, rad2deg(app.Config(i).JointPosition)));

                uilabel(app.TabManual, 'Position', [10, y_pos, 120, 22], ...
                    'Text', strrep(nombre_junta, '_', ' '), 'HorizontalAlignment', 'right', ...
                    'FontWeight', 'bold', 'FontColor', 'w');

                sld = uislider(app.TabManual, 'Position', [140, y_pos+10, 175, 3], ...
                    'Limits', [min_deg, max_deg], 'Value', val_ini, ...
                    'MajorTicks', []);

                edt = uieditfield(app.TabManual, 'numeric', 'Position', [330, y_pos, 65, 22], ...
                    'Limits', [min_deg, max_deg], 'Value', val_ini, ...
                    'ValueDisplayFormat', '%.1f°', ...
                    'Tooltip', sprintf('Límites: [%.1f°, %.1f°]', min_deg, max_deg));

                % Callbacks sincronizados Slider <-> EditField
                sld.ValueChangingFcn = @(~, evt) app.actualizarDesdeSlider(i, evt.Value, false);
                sld.ValueChangedFcn  = @(src, ~) app.actualizarDesdeSlider(i, src.Value, true);
                edt.ValueChangedFcn  = @(src, ~) app.actualizarDesdeTexto(i, src.Value);

                app.Sliders(i) = sld;
                app.Edits(i) = edt;
                y_pos = y_pos - paso_y;
            end
            warning('on', 'all');
        end

        function [min_deg, max_deg] = obtenerLimitesJunta(app, nombre_junta)
            min_deg = -180; max_deg = 180;
            for k = 1:length(app.RobotURDF.Bodies)
                jnt = app.RobotURDF.Bodies{k}.Joint;
                if strcmp(jnt.Name, nombre_junta)
                    lims = rad2deg(jnt.PositionLimits);
                    if all(isfinite(lims)) && lims(2) > lims(1)
                        min_deg = lims(1);
                        max_deg = lims(2);
                    end
                    break;
                end
            end
        end

        function aplicarEstadoCamara(app)
            try disableDefaultInteractivity(app.Ax3D); catch, end
            xlim(app.Ax3D, [-app.LimEjes, app.LimEjes]);
            ylim(app.Ax3D, [-app.LimEjes, app.LimEjes]);
            zlim(app.Ax3D, [-app.LimEjes, app.LimEjes]);
            daspect(app.Ax3D, [1 1 1]);
            pbaspect(app.Ax3D, [1 1 1]);
            app.Ax3D.CameraTarget = app.CamTarget;
            app.Ax3D.CameraViewAngle = app.CamViewAngle;
            view(app.Ax3D, [app.Az, app.El]);
            set(app.Ax3D, 'Color', [0.15 0.15 0.15], 'XColor', 'w', 'YColor', 'w', 'ZColor', 'w');
            grid(app.Ax3D, 'on');
            title(app.Ax3D, 'Simulación Interactiva (Arrastra con el ratón para rotar)', 'Color', 'w');
        end

        % =================================================================
        % CALLBACKS PESTAÑA 1: CONTROL ARTICULAR (robotat_bittle_set_joints)
        % =================================================================
        function actualizarDesdeSlider(app, idx, val_grados, forzar_tcp)
            app.Edits(idx).Value = val_grados;
            app.moverRobot(idx, val_grados, forzar_tcp);
        end

        function actualizarDesdeTexto(app, idx, val_grados)
            app.Sliders(idx).Value = val_grados;
            app.moverRobot(idx, val_grados, true);
        end

        function moverRobot(app, idx, val_grados, forzar_tcp)
            % 1. Actualizar configuracion matematica y visual 3D
            app.Config(idx).JointPosition = deg2rad(val_grados);
            
            show(app.RobotURDF, app.Config, 'Parent', app.Ax3D, 'PreservePlot', false, ...
                'FastUpdate', true, 'Collisions', 'off', 'Visuals', 'on', 'Frames', 'off');
            app.aplicarEstadoCamara();
            drawnow limitrate;

            % 2. Enviar vector q_deg mediante robotat_bittle_set_joints
            if strcmp(app.SwLiveSend.Value, 'On') && ~isempty(app.AgenteBittle.tcpsock)
                if forzar_tcp || toc(app.TimerEnvio) > 0.03
                    app.enviarVectorArticular();
                    app.TimerEnvio = tic;
                end
            end
        end

        function enviarVectorArticular(app)
            % Orden esperado por robotat_bittle_set_joints:
            % q_deg = [LF_hip, LF_knee, RF_hip, RF_knee, LB_hip, LB_knee, RB_hip, RB_knee, head]
            q_deg = zeros(1, 9);
            for i = 1:length(app.Config)
                ang = rad2deg(app.Config(i).JointPosition);
                switch app.Config(i).JointName
                    case 'left_front_hip',   q_deg(1) = ang;
                    case 'left_front_knee',  q_deg(2) = ang;
                    case 'right_front_hip',  q_deg(3) = ang;
                    case 'right_front_knee', q_deg(4) = ang;
                    case 'left_back_hip',    q_deg(5) = ang;
                    case 'left_back_knee',   q_deg(6) = ang;
                    case 'right_back_hip',   q_deg(7) = ang;
                    case 'right_back_knee',  q_deg(8) = ang;
                    case 'head',             q_deg(9) = ang;
                end
            end
            robotat_bittle_set_joints(app.AgenteBittle, q_deg);
        end

        % =================================================================
        % CALLBACKS PESTAÑA 2: CALIBRACIÓN (robotat_bittle_calibrate)
        % =================================================================
        function ejecutarAccionCalibracion(app, accion)
            if strcmp(accion, 'start')
                % Al iniciar calibracion, reiniciamos los offsets de la sesion a 0
                keys = app.CalibOffsets.keys;
                for k = 1:numel(keys)
                    app.CalibOffsets(keys{k}) = 0;
                end
                app.SldCalibOffset.Value = 0;
                app.EdtCalibOffset.Value = 0;
            end
            robotat_bittle_calibrate(app.AgenteBittle, accion);
        end

        function cambiarJuntaCalibracion(app)
            junta_actual = app.DdCalibJoint.Value;
            val_guardado = app.CalibOffsets(junta_actual);
            app.SldCalibOffset.Value = val_guardado;
            app.EdtCalibOffset.Value = val_guardado;
        end

        function actualizarCalibDesdeSlider(app, val_raw, forzar_envio)
            val_entero = round(val_raw);
            app.EdtCalibOffset.Value = val_entero;
            app.CalibOffsets(app.DdCalibJoint.Value) = val_entero;
            
            if forzar_envio || toc(app.TimerEnvio) > 0.04
                robotat_bittle_calibrate(app.AgenteBittle, 'set', app.DdCalibJoint.Value, val_entero);
                app.TimerEnvio = tic;
            end
        end

        function actualizarCalibDesdeTexto(app, val_raw)
            val_entero = round(val_raw);
            app.EdtCalibOffset.Value = val_entero;
            app.SldCalibOffset.Value = val_entero;
            app.CalibOffsets(app.DdCalibJoint.Value) = val_entero;
            
            robotat_bittle_calibrate(app.AgenteBittle, 'set', app.DdCalibJoint.Value, val_entero);
        end

        % =================================================================
        % CALLBACKS PESTAÑA 3: HABILIDADES Y LOCOMOCIÓN (robotat_bittle_skill)
        % =================================================================
        function ejecutarSkill(app, nombre_skill)
            robotat_bittle_skill(app.AgenteBittle, nombre_skill);
        end

        % =================================================================
        % GESTIÓN DE CONEXIÓN (robotat_bittle_connect / force_stop)
        % =================================================================
        function gestionarConexion(app)
            if isempty(app.AgenteBittle.tcpsock)
                id = app.SpinAgentID.Value;
                app.LblStatus.Text = "Buscando...";
                app.LblStatus.FontColor = [1 0.8 0.2];
                drawnow;
                
                app.AgenteBittle = robotat_bittle_connect(id);
                
                if ~isempty(app.AgenteBittle.tcpsock)
                    app.LblStatus.Text = "Conectado (ID " + num2str(id) + ")";
                    app.LblStatus.FontColor = [0.3 0.9 0.4];
                    app.BtnConnect.Text = "Desconectar";
                    app.BtnConnect.BackgroundColor = [0.7 0.2 0.2];
                else
                    app.LblStatus.Text = "Offline (Sim)";
                    app.LblStatus.FontColor = [0.9 0.4 0.4];
                end
            else
                robotat_bittle_force_stop(app.AgenteBittle);
                app.AgenteBittle.tcpsock = [];
                app.LblStatus.Text = "Desconectado";
                app.LblStatus.FontColor = [0.7 0.7 0.7];
                app.BtnConnect.Text = "Conectar";
                app.BtnConnect.BackgroundColor = [0.2 0.5 0.8];
            end
        end

        function resetearHome(app)
            app.Config = app.HomeConfig;
            for i = 1:length(app.Config)
                val_deg = rad2deg(app.Config(i).JointPosition);
                app.Sliders(i).Value = val_deg;
                app.Edits(i).Value = val_deg;
            end
            show(app.RobotURDF, app.Config, 'Parent', app.Ax3D, 'PreservePlot', false, ...
                'FastUpdate', true, 'Collisions', 'off', 'Visuals', 'on', 'Frames', 'off');
            app.aplicarEstadoCamara();
            drawnow;
            
            if strcmp(app.SwLiveSend.Value, 'On') && ~isempty(app.AgenteBittle.tcpsock)
                app.enviarVectorArticular();
            end
        end

        function cambiarEscalaEjes(app, nuevo_lim)
            if nuevo_lim > 0
                app.LimEjes = nuevo_lim;
                app.aplicarEstadoCamara();
            else
                app.EdtLimEjes.Value = app.LimEjes;
            end
        end

        function botonCargarOtroURDF(app)
            [ruta_urdf, carpeta_paquete] = app.seleccionarArchivoURDF();
            if ~isempty(ruta_urdf)
                app.cargarModeloURDF(ruta_urdf, carpeta_paquete);
            end
        end

        % --- ROTACIÓN 3D POR RATÓN ---
        function iniciarRotacion(app)
            pt = app.UIFigure.CurrentPoint;
            if pt(1) > 440 % Solo rotar si el clic ocurre en el panel derecho 3D
                app.IsRotating = true;
                app.LastMousePos = pt;
            end
        end

        function rotarVista(app)
            if app.IsRotating && ~isempty(app.Ax3D) && isvalid(app.Ax3D)
                pt = app.UIFigure.CurrentPoint;
                delta = pt - app.LastMousePos;
                app.Az = app.Az - delta(1) * 0.5;
                app.El = max(-89, min(89, app.El - delta(2) * 0.5));
                app.LastMousePos = pt;
                view(app.Ax3D, [app.Az, app.El]);
                drawnow limitrate;
            end
        end

        function terminarRotacion(app)
            app.IsRotating = false;
        end
    end

    % =====================================================================
    % CONSTRUCCIÓN DE COMPONENTES DE INTERFAZ (ESTILO APP DESIGNER)
    % =====================================================================
    methods (Access = private)

        function createComponents(app)
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [60 60 1160 700];
            app.UIFigure.Name = 'Robotat Bittle - Centro de Control y Simulador URDF';
            app.UIFigure.Color = [0.15 0.15 0.15];
            app.UIFigure.WindowButtonDownFcn   = @(~, ~) app.iniciarRotacion();
            app.UIFigure.WindowButtonMotionFcn = @(~, ~) app.rotarVista();
            app.UIFigure.WindowButtonUpFcn     = @(~, ~) app.terminarRotacion();

            % Layout Principal: Columna izquierda (430 px) y derecha (1x)
            app.MainLayout = uigridlayout(app.UIFigure, [1 2]);
            app.MainLayout.ColumnWidth = {430, '1x'};
            app.MainLayout.Padding = [8 8 8 8];
            app.MainLayout.BackgroundColor = [0.15 0.15 0.15];

            % -------------------------------------------------------------
            % 1. PANEL IZQUIERDO (CONEXIÓN + 3 PESTAÑAS)
            % -------------------------------------------------------------
            app.LeftPanel = uipanel(app.MainLayout, 'BackgroundColor', [0.18 0.18 0.18]);
            
            % Subpanel Superior de Conexion TCP
            app.ConnPanel = uipanel(app.LeftPanel, 'Position', [6 575 416 100], ...
                'Title', 'Conexión Agente Bittle (TCP)', 'BackgroundColor', [0.22 0.22 0.22], ...
                'ForegroundColor', 'w', 'FontWeight', 'bold');
                
            uilabel(app.ConnPanel, 'Position', [10 45 65 22], 'Text', 'Agente ID:', 'FontColor', 'w');
            app.SpinAgentID = uispinner(app.ConnPanel, 'Position', [75 45 55 22], 'Limits', [1 10], 'Value', 1);
            
            app.BtnConnect = uibutton(app.ConnPanel, 'Position', [140 43 110 26], ...
                'Text', 'Conectar', 'FontWeight', 'bold', ...
                'BackgroundColor', [0.2 0.5 0.8], 'FontColor', 'w', ...
                'ButtonPushedFcn', @(~, ~) app.gestionarConexion());
                
            app.LblStatus = uilabel(app.ConnPanel, 'Position', [260 45 145 22], ...
                'Text', 'Offline (Sim)', 'FontWeight', 'bold', 'FontColor', [0.8 0.8 0.8]);

            uilabel(app.ConnPanel, 'Position', [10 12 160 22], 'Text', 'Enviar a Bittle en vivo:', 'FontColor', 'w');
            app.SwLiveSend = uiswitch(app.ConnPanel, 'slider', 'Position', [180 12 45 20], ...
                'Items', {'Off', 'On'}, 'Value', 'On', 'FontColor', 'w');

            % Grupo de Pestanas
            app.TabGroup = uitabgroup(app.LeftPanel, 'Position', [6 6 416 562]);

            % =============================================================
            % PESTAÑA 1: CONTROL MANUAL (URDF)
            % =============================================================
            app.TabManual = uitab(app.TabGroup, 'Title', 'Control URDF', 'BackgroundColor', [0.18 0.18 0.18]);

            % =============================================================
            % PESTAÑA 2: CALIBRACIÓN (SLIDER + CUADRO NUMÉRICO)
            % =============================================================
            app.TabCalib = uitab(app.TabGroup, 'Title', 'Calibración', 'BackgroundColor', [0.18 0.18 0.18]);
            
            uilabel(app.TabCalib, 'Position', [15 490 380 25], 'Text', 'Asistente de Calibración (EEPROM)', ...
                'FontSize', 15, 'FontWeight', 'bold', 'FontColor', 'w');
            
            uilabel(app.TabCalib, 'Position', [15 445 385 38], ...
                'Text', '1. Inicia el modo de calibración. El Bittle se colocará en postura de referencia y reiniciará la vista de ajuste.', ...
                'WordWrap', 'on', 'FontColor', [0.85 0.85 0.85]);
            
            uibutton(app.TabCalib, 'Position', [15 400 260 36], ...
                'Text', 'Iniciar Modo Calibración ("start")', ...
                'BackgroundColor', [0.25 0.45 0.75], 'FontColor', 'w', 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(~, ~) app.ejecutarAccionCalibracion('start'));

            uilabel(app.TabCalib, 'Position', [15 345 380 20], ...
                'Text', '2. Selecciona la articulación a calibrar:', 'FontWeight', 'bold', 'FontColor', 'w');
            
            nombres_amigables = {
                'Cabeza / Cuello (head - ID 0)', ...
                'Frontal Izquierda - Cadera (left_front_hip - ID 8)', ...
                'Frontal Izquierda - Rodilla (left_front_knee - ID 12)', ...
                'Frontal Derecha - Cadera (right_front_hip - ID 9)', ...
                'Frontal Derecha - Rodilla (right_front_knee - ID 13)', ...
                'Trasera Izquierda - Cadera (left_back_hip - ID 11)', ...
                'Trasera Izquierda - Rodilla (left_back_knee - ID 15)', ...
                'Trasera Derecha - Cadera (right_back_hip - ID 10)', ...
                'Trasera Derecha - Rodilla (right_back_knee - ID 14)'
            };
            nombres_urdf = {
                'head', 'left_front_hip', 'left_front_knee', ...
                'right_front_hip', 'right_front_knee', ...
                'left_back_hip', 'left_back_knee', ...
                'right_back_hip', 'right_back_knee'
            };
            
            app.DdCalibJoint = uidropdown(app.TabCalib, 'Position', [15 312 380 28], ...
                'Items', nombres_amigables, 'ItemsData', nombres_urdf, ...
                'ValueChangedFcn', @(~, ~) app.cambiarJuntaCalibracion());

            uilabel(app.TabCalib, 'Position', [15 260 385 20], ...
                'Text', '3. Ajusta el Offset con el slider o escribe el valor exacto:', ...
                'FontWeight', 'bold', 'FontColor', 'w');
            
            % Slider de aproximacion rapida (-25 a 25 grados)
            app.SldCalibOffset = uislider(app.TabCalib, 'Position', [20 225 280 3], ...
                'Limits', [-25 25], 'Value', 0, ...
                'MajorTicks', [-25 -15 -5 0 5 15 25]);
            
            % Cajita numerica para sintonizacion exacta al grado
            app.EdtCalibOffset = uieditfield(app.TabCalib, 'numeric', ...
                'Position', [320 212 75 26], ...
                'Limits', [-25 25], 'RoundFractionalValues', 'on', ...
                'Value', 0, 'ValueDisplayFormat', '%d°', ...
                'FontWeight', 'bold', 'HorizontalAlignment', 'center', ...
                'Tooltip', 'Ingresa un ángulo entero entre -25° y 25°');

            app.SldCalibOffset.ValueChangingFcn = @(~, evt) app.actualizarCalibDesdeSlider(evt.Value, false);
            app.SldCalibOffset.ValueChangedFcn  = @(src, ~) app.actualizarCalibDesdeSlider(src.Value, true);
            app.EdtCalibOffset.ValueChangedFcn  = @(src, ~) app.actualizarCalibDesdeTexto(src.Value);

            uilabel(app.TabCalib, 'Position', [15 125 385 38], ...
                'Text', '4. Una vez alineadas todas las patas físicamente, guarda los offsets de forma permanente en la EEPROM.', ...
                'WordWrap', 'on', 'FontColor', [0.85 0.85 0.85]);
            
            uibutton(app.TabCalib, 'Position', [15 75 260 40], ...
                'Text', 'GUARDAR EN EEPROM ("save")', ...
                'BackgroundColor', [0.8 0.2 0.2], 'FontColor', 'w', 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(~, ~) app.ejecutarAccionCalibracion('save'));

            % =============================================================
            % PESTAÑA 3: LOCOMOCIÓN Y HABILIDADES DE DEMOSTRACIÓN
            % =============================================================
            app.TabSkills = uitab(app.TabGroup, 'Title', 'Locomoción y Skills', 'BackgroundColor', [0.18 0.18 0.18]);
            
            tab3Layout = uigridlayout(app.TabSkills, [2 1]);
            tab3Layout.RowHeight = {215, '1x'};
            tab3Layout.Padding = [6 6 6 6];
            tab3Layout.RowSpacing = 8;
            tab3Layout.BackgroundColor = [0.18 0.18 0.18];

            % --- SUBPANEL 1: LOCOMOCIÓN Y MARCHAS ---
            pnlLoco = uipanel(tab3Layout, 'Title', 'Control de Locomoción y Marchas', ...
                'BackgroundColor', [0.22 0.22 0.22], 'ForegroundColor', 'w', 'FontWeight', 'bold');
            
            glLoco = uigridlayout(pnlLoco, [4 3]);
            glLoco.RowHeight = {'1x', '1x', '1x', '1x'};
            glLoco.ColumnWidth = {'1x', '1x', '1x'};
            glLoco.Padding = [6 6 6 6];
            glLoco.RowSpacing = 5; glLoco.ColumnSpacing = 5;
            glLoco.BackgroundColor = [0.22 0.22 0.22];

            % Matriz de botones de locomocion: {Texto, comando_skill, color_fondo}
            botones_loco = {
                '↖ Frente Izq', 'forwardLeft',  [0.28 0.35 0.45];
                '⬆ Caminar Frente', 'forward',  [0.20 0.45 0.70];
                '↗ Frente Der', 'forwardRight', [0.28 0.35 0.45];
                
                '↙ Atrás Izq',  'backLeft',     [0.28 0.35 0.45];
                '⬇ Caminar Atrás', 'back',      [0.25 0.40 0.60];
                '↘ Atrás Der',  'backRight',    [0.28 0.35 0.45];
                
                '🐎 Trote (Trot)', 'trot',      [0.25 0.50 0.40];
                '⚡ Correr (Run)', 'run',       [0.20 0.60 0.45];
                '🐢 Gatear (Crawl)', 'crawl',   [0.25 0.50 0.40];
                
                '👣 Paso en Sitio', 'stepping', [0.35 0.35 0.40];
                '🧭 Giroscopio', 'gyro',        [0.45 0.40 0.25];
                '🛑 PARO (Stop)', 'stop',       [0.80 0.20 0.20]
            };

            for k = 1:size(botones_loco, 1)
                cmd = botones_loco{k, 2};
                uibutton(glLoco, 'Text', botones_loco{k, 1}, ...
                    'FontSize', 11, 'FontWeight', 'bold', ...
                    'BackgroundColor', botones_loco{k, 3}, 'FontColor', 'w', ...
                    'ButtonPushedFcn', @(~, ~) app.ejecutarSkill(cmd));
            end

            % --- SUBPANEL 2: POSES Y ACROBACIAS VISTOSAS ---
            pnlDemo = uipanel(tab3Layout, 'Title', 'Poses y Acrobacias para Demostración', ...
                'BackgroundColor', [0.22 0.22 0.22], 'ForegroundColor', 'w', 'FontWeight', 'bold');
            
            glDemo = uigridlayout(pnlDemo, [6 3]);
            glDemo.RowHeight = repmat({'1x'}, 1, 6);
            glDemo.ColumnWidth = {'1x', '1x', '1x'};
            glDemo.Padding = [6 6 6 6];
            glDemo.RowSpacing = 5; glDemo.ColumnSpacing = 5;
            glDemo.BackgroundColor = [0.22 0.22 0.22];

            botones_demo = {
                '⚖️ Balance',       'balance';
                '🐶 Sentarse',      'sit';
                '🍑 Butt Up',       'buttUp';
                
                '🧘 Estirarse',     'stretch';
                '👋 Saludar (Hi)',  'hi';
                '🐾 Check / Pata',  'check';
                
                '🤸 Front Flip',    'frontFlip';
                '🤸 Back Flip',     'backFlip';
                '🕺 Moonwalk',      'moonWalk';
                
                '💪 Push Ups',      'pushUp';
                '💪 PushUp 1 Brazo','pushUpSingleArm';
                '🥊 Boxeo',         'boxing';
                
                '🤸 Pino (Handstand)','handStand';
                '🦘 Saltar (Jump)', 'jump';
                '🙌 Cheers!',       'cheers';
                
                '🐕 Good Boy',      'goodboy';
                '💀 Play Dead',     'playDead';
                '🚽 Hacer del baño',   'pee'
            };

            for k = 1:size(botones_demo, 1)
                cmd = botones_demo{k, 2};
                uibutton(glDemo, 'Text', botones_demo{k, 1}, ...
                    'FontSize', 11, 'FontWeight', 'bold', ...
                    'BackgroundColor', [0.30 0.30 0.34], 'FontColor', 'w', ...
                    'ButtonPushedFcn', @(~, ~) app.ejecutarSkill(cmd));
            end

            % -------------------------------------------------------------
            % 2. PANEL DERECHO (BARRA SUPERIOR + LIENZO 3D URDF)
            % -------------------------------------------------------------
            app.RightPanel = uipanel(app.MainLayout, 'BackgroundColor', [0.15 0.15 0.15]);
            rightLayout = uigridlayout(app.RightPanel, [2 1]);
            rightLayout.RowHeight = {45, '1x'};
            rightLayout.Padding = [0 0 0 0];
            rightLayout.BackgroundColor = [0.15 0.15 0.15];

            % Barra de herramientas 3D (Limite de Ejes, Home y Otro URDF)
            app.Toolbar3D = uipanel(rightLayout, 'BackgroundColor', [0.2 0.2 0.2]);
            uilabel(app.Toolbar3D, 'Position', [15 12 100 22], ...
                'Text', 'Límite Ejes (m):', 'FontWeight', 'bold', 'FontColor', 'w');
            app.EdtLimEjes = uieditfield(app.Toolbar3D, 'numeric', 'Position', [115 12 60 22], ...
                'Value', app.LimEjes, 'ValueChangedFcn', @(src, ~) app.cambiarEscalaEjes(src.Value));

            app.BtnHome = uibutton(app.Toolbar3D, 'Position', [195 10 100 26], ...
                'Text', 'Home (0°)', 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(~, ~) app.resetearHome());

            app.BtnLoadURDF = uibutton(app.Toolbar3D, 'Position', [310 10 110 26], ...
                'Text', 'Otro URDF...', ...
                'ButtonPushedFcn', @(~, ~) app.botonCargarOtroURDF());

            % Panel contenedor para el eje 3D
            app.CanvasPanel = uipanel(rightLayout, 'BackgroundColor', [0.15 0.15 0.15], 'BorderType', 'none');

            app.UIFigure.Visible = 'on';
        end
    end

    % =====================================================================
    % CICLO DE VIDA DE LA APP
    % =====================================================================
    methods (Access = public)

        function app = BittleApp
            createComponents(app);
            registerApp(app, app.UIFigure);
            runStartupFcn(app, @startupFcn);

            if nargout == 0
                clear app
            end
        end

        function delete(app)
            % Paro seguro al cerrar la ventana de la App usando tu libreria
            if ~isempty(app.AgenteBittle.tcpsock)
                try
                    robotat_bittle_force_stop(app.AgenteBittle);
                catch
                end
            end
            delete(app.UIFigure);
        end
    end
end