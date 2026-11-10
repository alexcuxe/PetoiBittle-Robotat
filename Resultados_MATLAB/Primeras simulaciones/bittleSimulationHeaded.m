%% Integración definitiva
% Limpiar variables
clear
clc

% Establecer conexión alámbrica
puertos_activos = serialportfind;
if ~isempty(puertos_activos)
    delete(puertos_activos);
end
puerto = serialport("COM3", 115200);    % Modificar según puerto


% Dimensiones para cada efector (patas y cabeza) en metros
L1_a = 0.046;   % muslo
L2_a = 0.048;   % pata
L_cab = 0.045;  % longitud visual de la cabeza

% Parámetros DH para las patas
L1 = Revolute('d', 0, 'a', L1_a, 'alpha', 0, 'offset', pi);     % muslo
L2 = Revolute('d', 0, 'a', L2_a, 'alpha', 0, 'offset', -pi/2);  % pierna

% Parámetro DH para la cabeza
% 'a' = 0 para ocultar el cilindro gigante
L_head = Revolute('d', 0, 'a', 0, 'alpha', 0, 'offset', pi/2);


% Crear los cuerpos rígidos
LF = SerialLink([L1, L2], 'name', 'LF');
RF = SerialLink([L1, L2], 'name', 'RF');
LB = SerialLink([L1, L2], 'name', 'LB');
RB = SerialLink([L1, L2], 'name', 'RB');
Cabeza = SerialLink(L_head, 'name', 'Cabeza');

% Desplazar las patas a su posición
LF.base = transl(-0.046, 0.0525, 0) * troty(-pi/2);
RF.base = transl(0.046, 0.0525, 0) * troty(-pi/2);
LB.base = transl(-0.046, -0.0525, 0) * troty(-pi/2);
RB.base = transl(0.046, -0.0525, 0) * troty(-pi/2);

% Desplazar el cuello a la parte frontal superior del torso
Cabeza.base = transl(0, 0.0635, 0.015); 

figure('Name', 'Bittle: Torso, Patas y Cabeza');
hold on; 
grid on; axis equal; view(3);

% --- DIBUJO DEL TORSO ---
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

% --- DIBUJO DE LA CABEZA PERSONALIZADA ---
% Dimensiones de la cabeza (un bloque más pequeño)
a_cab = 0.040; % 4 cm de ancho
l_cab = 0.045; % 4.5 cm de largo hacia el frente
h_cab = 0.025; % 2.5 cm de altura

% Vértices locales (el cuello está en el origen [0,0,0] de esta cajita)
% Se extiende hacia adelante en X (que es el frente del robot por el offset pi/2)
vert_cab_local = [
    0      -a_cab/2 -h_cab/2;  l_cab -a_cab/2 -h_cab/2;
    l_cab   a_cab/2 -h_cab/2;  0      a_cab/2 -h_cab/2;
    0      -a_cab/2  h_cab/2;  l_cab -a_cab/2  h_cab/2;
    l_cab   a_cab/2  h_cab/2;  0      a_cab/2  h_cab/2
];

% Obtener la posición inicial de la cabeza usando Cinemática Directa
T_inicial = double(Cabeza.fkine(0)); 

% Multiplicación matricial homogénea (4x4 * 4x8)
vert_globales = (T_inicial * [vert_cab_local, ones(8,1)]')';

% Dibujar la cabeza
h_cabeza = patch('Vertices', vert_globales(:,1:3), 'Faces', caras, ...
                 'FaceColor', [0.85 0.55 0.1], 'FaceAlpha', 0.9, 'EdgeColor', 'k');

% Graficar los cuerpos rígidos
LF.plot([0 0], 'workspace', [-0.2 0.2 -0.2 0.2 -0.2 0.2]);
RF.plot([0 0]); LB.plot([0 0]); RB.plot([0 0]); %Cabeza.plot(0);

% Llamamos a la función pasándole la figura gráfica de la cabeza (h_cabeza) y sus vértices locales
crear_panel_bittle(LF, RF, LB, RB, Cabeza, h_cabeza, vert_cab_local, puerto);


%% --- FUNCIONES DEL PANEL DE CONTROL ---

function crear_panel_bittle(LF, RF, LB, RB, Cabeza, h_cabeza, vert_cab_local, puerto)
    fig = uifigure('Name', 'Control Individual Bittle', 'Position', [100 100 400 530]);
    fig.UserData = zeros(1, 9); 
    
    nombres = {'LF Cadera', 'LF Rodilla', 'RF Cadera', 'RF Rodilla', ...
               'LB Cadera', 'LB Rodilla', 'RB Cadera', 'RB Rodilla', 'Cabeza (Pan)'};
               
    for i = 1:9
        uilabel(fig, 'Position', [20, 530 - i*50, 80, 20], 'Text', nombres{i});
        
        uislider(fig, 'Position', [100, 540 - i*50, 250, 3], ...
            'Limits', [-90 90], 'Value', 0, ...
            'ValueChangedFcn', @(src, event) actualizar_articulacion(i, src.Value, LF, RF, LB, RB, Cabeza, h_cabeza, vert_cab_local, puerto, fig));
    end
end

function actualizar_articulacion(indice, valor, LF, RF, LB, RB, Cabeza, h_cabeza, vert_cab_local, puerto, fig)
    % 1. Recuperar y actualizar memoria
    q_grados = fig.UserData;
    q_grados(indice) = valor; 
    fig.UserData = q_grados;  
    
    % 2. Convertir a radianes
    q_rad = deg2rad(q_grados);
    
    % 3. Animar la gráfica 3D (Cadenas cinemáticas)
    LF.animate([q_rad(1), q_rad(2)]);
    RF.animate([q_rad(3), q_rad(4)]);
    LB.animate([q_rad(5), q_rad(6)]);
    RB.animate([q_rad(7), q_rad(8)]);
    %Cabeza.animate(q_rad(9)); 
    %Animar la caja de la cabeza ---
    % Calculamos la nueva matriz de transformación SE(3) de la cabeza
    T_head = double(Cabeza.fkine(q_rad(9))); 
    
    % Aplicamos la transformación homogénea a los vértices locales
    vert_globales = (T_head * [vert_cab_local, ones(8,1)]')';
    
    % Actualizamos la figura gráfica en pantalla
    h_cabeza.Vertices = vert_globales(:, 1:3);


    % 4. Enviar los datos al Bittle físico
    servos = zeros(1, 16);

    servos(1)  = round(q_grados(9)); % Cabeza
    servos(9)  = round(q_grados(1)); % LF Cadera 
    servos(13) = round(q_grados(2)); % LF Rodilla 
    servos(10) = round(q_grados(3)); % RF Cadera 
    servos(14) = round(q_grados(4)); % RF Rodilla 
    servos(12) = round(q_grados(5)); % LB Cadera 
    servos(16) = round(q_grados(6)); % LB Rodilla 
    servos(11) = round(q_grados(7)); % RB Cadera 
    servos(15) = round(q_grados(8)); % RB Rodilla 

    data_bytes = typecast(int8(servos), 'uint8');
    paquete = [uint8('L'), data_bytes, uint8('~')];

    write(puerto, paquete, "uint8");
end
