function robotat_bittle_disconnect(robot)
    % robotat_bittle_disconnect - Detiene el robot y cierra la conexión TCP de forma segura.
    
    % Paro por seguridad antes de cortar el canal
    robotat_bittle_force_stop(robot);
    
    % Pequeña pausa para asegurar que el paquete 'd' llegó
    pause(0.2);
    
    % Borrar la variable del workspace base para cerrar el socket TCP
    % inputname(1) obtiene el nombre de la variable que el usuario pasó a la función
    var_name = inputname(1);
    if ~isempty(var_name)
        evalin('base', ['clear ', var_name]);
    end
    
    disp('Desconectado del Bittle de forma segura.');
end