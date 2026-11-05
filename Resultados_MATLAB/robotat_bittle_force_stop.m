function robotat_bittle_force_stop(robot)
    % robotat_bittle_force_stop - Detiene inmediatamente cualquier movimiento del Bittle.
    % Manda el comando 'd' (Descanso/Shutdown de servos).
    
    if ~isempty(robot.tcpsock)
        try
            % Comando 'd' = Rest / Apagar torque de motores
            comando = "d" + newline;
            write(robot.tcpsock, uint8(char(comando)));
            disp('Bittle detenido');
        catch
            warning('No se pudo enviar el comando de paro al Bittle. (Posible desconexión).');
        end
    else
        warning('El socket del robot no está activo.');
    end
end