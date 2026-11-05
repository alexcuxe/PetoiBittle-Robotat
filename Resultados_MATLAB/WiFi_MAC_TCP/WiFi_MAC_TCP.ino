#include <ESP8266WiFi.h>

#define BUILTIN_LED 2

const char* ssid = "Robotat";       
const char* password = "iemtbmcit116"; 

const int port = 8116;

WiFiServer server(port);
WiFiClient client;

// --- Variables para el parpadeo ---
unsigned long tiempoUltimoMensaje = 0;
const int duracionParpadeo = 30; // 30 milisegundos de parpadeo
// ----------------------------------

void setup() {
  pinMode(BUILTIN_LED, OUTPUT);
  Serial.begin(115200); 
  
  Serial.println("\n--- Iniciando Bittle TCP Bridge ---"); 

  WiFi.begin(ssid, password);
  
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
  }
  
  // LED encendido fijo para indicar que estamos conectados al Wi-Fi
  digitalWrite(BUILTIN_LED, HIGH); 
  
  Serial.println("\n¡Conexión Exitosa!");
  
  Serial.print("DIRECCIÓN MAC: ");
  Serial.println(WiFi.macAddress()); 

  // --- IMPRESIÓN DE DATOS DE RED ---
  Serial.print("DIRECCIÓN IP: ");
  Serial.println(WiFi.localIP()); 
  
  // ----------------------------------
  
  server.begin();
}

void loop() {
  // Comprobar si hay un cliente NUEVO intentando conectarse
  if (server.hasClient()) {
    // Si ya había un cliente viejo conectado ("zombi"), lo desconectamos a la fuerza
    if (client.connected()) {
      Serial.println("\nDesconectando cliente anterior (Zombi)...");
      client.stop();
    }
    // Aceptamos al nuevo cliente
    client = server.available();
    Serial.println("\n¡Nuevo cliente MATLAB conectado!");
    
    // Limpiamos cualquier basura que haya quedado en el cable hacia el Bittle
    while(Serial.available()) Serial.read(); 
  }

  // Manejo del túnel (solo si el cliente está vivo)
  if (client.connected()) {
    // 1. TÚNEL MATLAB -> BITTLE
    if (client.available()) {
      digitalWrite(BUILTIN_LED, LOW); 
      tiempoUltimoMensaje = millis();
      
      while (client.available()) {
        Serial.write(client.read());
      }
    }

    if (millis() - tiempoUltimoMensaje > duracionParpadeo) {
      digitalWrite(BUILTIN_LED, HIGH);
    }

    // 2. TÚNEL BITTLE -> MATLAB
    while (Serial.available()) {
      client.write(Serial.read());
    }
  }
}