function skill_vector = bittle_custom_skills_data(skill_name)
    % bittle_custom_skills_data - Catalogo de matrices para habilidades
    % personalizadas del Petoi Bittle (Token 'K') disenadas con estabilidad ZMP.
    %
    % Orden de los 16 canales articulares (Posture y Behavior):
    %   [0:head, 1..7:N/A, 8:LF_hip, 9:RF_hip, 10:RB_hip, 11:LB_hip,
    %    12:LF_knee, 13:RF_knee, 14:RB_knee, 15:LB_knee]
    %
    % Orden de los 8 canales de patas (Gait):
    %   [Col1: 8(LF_hip),  Col2: 9(RF_hip),  Col3: 10(RB_hip), Col4: 11(LB_hip),
    %    Col5: 12(LF_knee),Col6: 13(RF_knee),Col7: 14(RB_knee),Col8: 15(LB_knee)]
    %   * Par Diagonal A (LF + RB): Columnas 1 y 3 (caderas), 5 y 7 (rodillas)
    %   * Par Diagonal B (RF + LB): Columnas 2 y 4 (caderas), 6 y 8 (rodillas)

    arguments
        skill_name (1,:) char {mustBeMember(skill_name, { ...
            'posture_low_guard', ...
            'posture_side_lean', ...
            'behavior_horizon_scan', ...
            'behavior_lateral_sway', ...
            'gait_high_step_forward', ...
            'gait_stable_crawl', ...
            'gait_pivot_left', ...
            'gait_test_vt' ...
        })}
    end

    switch skill_name
        
        % =================================================================
        % 1. POSTURES (N = 1): Encabezado (4) + 1 fila de 16 angulos
        % =================================================================
        case 'posture_low_guard'
            header = [1, 0, 0, 1];
            frame = [ ...
                 0,  0,  0,  0,  0,  0,  0,  0, ...
                55, 55, 15, 15, ...
               -10,-10, 50, 50 ...
            ];
            skill_vector = [header, frame];

        case 'posture_side_lean'
            header = [1, 0, 0, 1];
            frame = [ ...
               -35,  0,  0,  0,  0,  0,  0,  0, ...
                45, 20, 20, 45, ...
                45, 15, 15, 45 ...
            ];
            skill_vector = [header, frame];

        % =================================================================
        % 2. BEHAVIORS (N < 0): Encabezado (7) + N filas de 20 elementos
        % =================================================================
        case 'behavior_horizon_scan'
            header = [-6, 0, 0, 1, 0, 0, 1];
            frames = [
                  0, 0,0,0,0,0,0,0,  55, 55, 15, 15, -10,-10, 50, 50,  4, 4, 0, 0;
                 60, 0,0,0,0,0,0,0,  55, 55, 15, 15, -10,-10, 50, 50,  3, 6, 0, 0;
                -60, 0,0,0,0,0,0,0,  55, 55, 15, 15, -10,-10, 50, 50,  3, 6, 0, 0;
                -50, 0,0,0,0,0,0,0,  20, 20, 20, 20,  15, 15, 15, 15,  4, 4, 0, 0;
                 50, 0,0,0,0,0,0,0,  20, 20, 20, 20,  15, 15, 15, 15,  3, 6, 0, 0;
                  0, 0,0,0,0,0,0,0,  30, 30, 30, 30,  30, 30, 30, 30,  4, 2, 0, 0
            ];
            skill_vector = [header, reshape(frames.', 1, [])];

        case 'behavior_lateral_sway'
            header = [-5, 0, 0, 1, 1, 2, 3];
            frames = [
                  0, 0,0,0,0,0,0,0,  30, 30, 30, 30,  30, 30, 30, 30,  4, 2, 0, 0;
                 35, 0,0,0,0,0,0,0,  45, 18, 18, 45,  45, 15, 15, 45,  4, 3, 0, 0;
                -35, 0,0,0,0,0,0,0,  18, 45, 45, 18,  15, 45, 45, 15,  4, 3, 0, 0;
                  0, 0,0,0,0,0,0,0,  50, 50, 20, 20,  45, 45, 15, 15,  4, 4, 0, 0;
                  0, 0,0,0,0,0,0,0,  30, 30, 30, 30,  30, 30, 30, 30,  4, 2, 0, 0
            ];
            skill_vector = [header, reshape(frames.', 1, [])];

        % =================================================================
        % 3. GAITS (N > 1): Encabezado (4) + N filas de 8 angulos (patas)
        % =================================================================
        case 'gait_high_step_forward'
            % Marcha diagonal de paso alto hacia adelante (22 frames).
            % Basada en la linea base de 'vt' [43, 43, 47, 47, 7, 7, 7, 7]
            % agregando barrido longitudinal de cadera para avance recto.
            header = [22, 0, 0, 1];
            frames = [
                % --- Fase 1: Par B (RF, LB) en vuelo hacia adelante (31/35 deg)
                %             Par A (LF, RB) en suelo empujando atras (31->55 deg)
                31, 55, 35, 59,   7,   0,   7,   0;
                34, 52, 38, 56,   7, -14,   7, -14;
                37, 48, 41, 52,   7, -26,   7, -26;
                40, 43, 44, 47,   7, -35,   7, -35;
                43, 38, 47, 42,   7, -30,   7, -30;
                46, 34, 50, 38,   7, -18,   7, -18;
                49, 32, 53, 36,   7,  -5,   7,  -5;
                52, 31, 56, 35,   7,   7,   7,   7;
                % Doble soporte (4 patas en tierra para estabilizar ZMP)
                54, 31, 58, 35,   7,   7,   7,   7;
                55, 31, 59, 35,   7,   7,   7,   7;
                55, 31, 59, 35,   7,   7,   7,   7;
                % --- Fase 2: Par A (LF, RB) en vuelo hacia adelante (31/35 deg)
                %             Par B (RF, LB) en suelo empujando atras (31->55 deg)
                55, 31, 59, 35,   0,   7,   0,   7;
                52, 34, 56, 38, -14,   7, -14,   7;
                48, 37, 52, 41, -26,   7, -26,   7;
                43, 40, 47, 44, -35,   7, -35,   7;
                38, 43, 42, 47, -30,   7, -30,   7;
                34, 46, 38, 50, -18,   7, -18,   7;
                32, 49, 36, 53,  -5,   7,  -5,   7;
                31, 52, 35, 56,   7,   7,   7,   7;
                % Doble soporte (4 patas en tierra)
                31, 54, 35, 58,   7,   7,   7,   7;
                31, 55, 35, 59,   7,   7,   7,   7;
                31, 55, 35, 59,   7,   7,   7,   7
            ];
            skill_vector = [header, reshape(frames.', 1, [])];

        case 'gait_stable_crawl'
            % Gateo estatico de 4 tiempos (24 frames: 6 frames por pata).
            % Secuencia de vuelo: 1) LF -> 2) RB -> 3) RF -> 4) LB.
            % Siempre mantiene 3 patas apoyadas en el suelo (knee = 8).
            header = [24, 0, 0, 1];
            frames = [
                % 1. Vuelo LF (Col 1 avanza 54->30, Col 5 levanta a -32)
                54, 42, 42, 50,   0,   8,   8,   8;
                48, 43, 44, 51, -18,   8,   8,   8;
                40, 44, 46, 52, -32,   8,   8,   8;
                34, 46, 47, 54, -22,   8,   8,   8;
                30, 47, 49, 55,  -6,   8,   8,   8;
                30, 48, 50, 56,   8,   8,   8,   8;
                % 2. Vuelo RB (Col 3 avanza 58->34, Col 7 levanta a -32)
                31, 49, 58, 57,   8,   8,   0,   8;
                33, 50, 52, 58,   8,   8, -18,   8;
                34, 52, 44, 40,   8,   8, -32,   8;
                36, 53, 38, 41,   8,   8, -22,   8;
                37, 54, 34, 42,   8,   8,  -6,   8;
                38, 54, 34, 42,   8,   8,   8,   8;
                % 3. Vuelo RF (Col 2 avanza 54->30, Col 6 levanta a -32)
                39, 54, 35, 44,   8,   0,   8,   8;
                41, 48, 37, 45,   8, -18,   8,   8;
                42, 40, 38, 46,   8, -32,   8,   8;
                44, 34, 40, 48,   8, -22,   8,   8;
                45, 30, 41, 49,   8,  -6,   8,   8;
                46, 30, 42, 50,   8,   8,   8,   8;
                % 4. Vuelo LB (Col 4 avanza 58->34, Col 8 levanta a -32)
                47, 32, 41, 58,   8,   8,   8,   0;
                49, 34, 41, 52,   8,   8,   8, -18;
                50, 36, 41, 44,   8,   8,   8, -32;
                52, 38, 42, 38,   8,   8,   8, -22;
                53, 40, 42, 34,   8,   8,   8,  -6;
                54, 42, 42, 42,   8,   8,   8,   8
            ];
            skill_vector = [header, reshape(frames.', 1, [])];

        case 'gait_pivot_left'
            % Giro diferencial en el sitio hacia la izquierda (20 frames).
            % Alterna los pares diagonales con el perfil de rodilla de 'vt',
            % rotando el chasis sobre su centro geometrico.
            header = [20, 0, 0, 1];
            frames = [
                % --- Par B (RF, LB) en el aire / Par A (LF, RB) rota chasis
                43, 45, 47, 45,   7,   0,   7,   0;
                46, 40, 44, 50,   7, -16,   7, -16;
                49, 35, 41, 55,   7, -32,   7, -32;
                52, 35, 38, 55,   7, -26,   7, -26;
                52, 38, 38, 52,   7, -12,   7, -12;
                50, 41, 40, 49,   7,   0,   7,   0;
                % Doble soporte de transicion (4 patas en el suelo)
                47, 43, 43, 47,   7,   7,   7,   7;
                45, 43, 45, 47,   7,   7,   7,   7;
                43, 43, 47, 47,   7,   7,   7,   7;
                43, 43, 47, 47,   7,   7,   7,   7;
                % --- Par A (LF, RB) en el aire / Par B (RF, LB) rota chasis
                41, 45, 49, 45,   0,   7,   0,   7;
                36, 48, 54, 42, -16,   7, -16,   7;
                32, 51, 58, 39, -32,   7, -32,   7;
                32, 53, 58, 37, -26,   7, -26,   7;
                36, 51, 54, 39, -12,   7, -12,   7;
                40, 48, 50, 42,   0,   7,   0,   7;
                % Doble soporte de transicion
                43, 46, 47, 44,   7,   7,   7,   7;
                43, 44, 47, 46,   7,   7,   7,   7;
                43, 43, 47, 47,   7,   7,   7,   7;
                43, 43, 47, 47,   7,   7,   7,   7
            ];
            skill_vector = [header, reshape(frames.', 1, [])];

        case 'gait_test_vt'
            % Rutina 'vt' de 21 frames validada en test1.py
            header = [21, 0, 0, 1];
            frames = [
                57,  43,  60,  47, -18,   7, -17,   7;
                50,  43,  53,  47,  -5,   7,  -5,   7;
                43,  43,  47,  47,   7,   7,   7,   7;
                43,  43,  47,  47,   7,   7,   7,   7;
                43,  43,  47,  47,   7,   7,   7,   7;
                43,  47,  47,  50,   7,   0,   7,   0;
                43,  54,  47,  58,   7, -13,   7, -13;
                43,  60,  47,  65,   7, -25,   7, -25;
                43,  66,  47,  71,   7, -35,   7, -35;
                43,  63,  47,  67,   7, -30,   7, -29;
                43,  57,  47,  60,   7, -18,   7, -17;
                43,  50,  47,  53,   7,  -5,   7,  -5;
                43,  43,  47,  47,   7,   7,   7,   7;
                43,  43,  47,  47,   7,   7,   7,   7;
                43,  43,  47,  47,   7,   7,   7,   7;
                43,  43,  47,  47,   7,   7,   7,   7;
                47,  43,  50,  47,   0,   7,   0,   7;
                54,  43,  58,  47, -13,   7, -13,   7;
                60,  43,  65,  47, -25,   7, -25,   7;
                66,  43,  71,  47, -35,   7, -35,   7;
                63,  43,  67,  47, -30,   7, -29,   7
            ];
            skill_vector = [header, reshape(frames.', 1, [])];
    end
end