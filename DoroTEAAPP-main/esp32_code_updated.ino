#include <Arduino.h>
#include <WiFi.h>           // Biblioteca para conexão Wi-Fi
#include <HTTPClient.h>     // Biblioteca para requisições HTTP (download)
#include <WebServer.h>      // Biblioteca para servidor HTTP
#include <ArduinoJson.h>    // Biblioteca para JSON
#include <SD.h>
#include <SPI.h>

// --- Bibliotecas para Áudio ---
#include "AudioFileSourceSD.h"
#include "AudioGeneratorMP3.h"
#include "AudioOutputI2S.h"

// --- CONFIGURAÇÕES DE HARDWARE ---
#define SD_CS_PIN 5         // Chip Select (CS) do Módulo SD

// Pinos I2S (conforme sua fiação)
#define I2S_BCK_PIN 27      // BCLK (Bit Clock)
#define I2S_WS_PIN 26      // LRC (Left/Right Clock)
#define I2S_DATA_PIN 25     // DIN (Data In do módulo)

// --- CONFIGURAÇÕES DE REDE E ARQUIVO (AJUSTE AQUI) ---
const char* ssid = "DOROTEA";
const char* password = "abacate1";

// URL COMPLETA do arquivo no seu servidor Flask
const char* musicUrl = "http://192.168.40.154:5000/uploads/po_gg.mp3"; 

// NOME DO ARQUIVO NO SD CARD (Será o nome final no cartão)
const char* downloadPath = "/DFM.mp3";

// --- Instâncias de Áudio ---
AudioFileSourceSD *file;
AudioGeneratorMP3 *mp3;
AudioOutputI2S *out;

// --- Servidor Web ---
WebServer server(80);

// --- Variáveis de controle ---
bool isPlaying = false;
String currentMusicId = "";

// --- Mapeamento de IDs para arquivos ---
struct MusicFile {
  String id;
  String filename;
};

MusicFile musicFiles[] = {
  {"bmp", "/bmp.mp3"},
  {"brilha_estrelinha", "/brilha_estrelinha.mp3"},
  {"clair_de_lune", "/clair_de_lune.mp3"},
  {"lullaby", "/lullaby.mp3"},
  {"primavera", "/primavera.mp3"}
};

// ===============================================
// FUNÇÕES DE CONTROLE DE ÁUDIO
// ===============================================

void stopCurrentMusic() {
  if (mp3 && mp3->isRunning()) {
    mp3->stop();
    delete mp3;
    mp3 = nullptr;
    delete file;
    file = nullptr;
    delete out;
    out = nullptr;
    isPlaying = false;
    Serial.println("Música parada.");
  }
}

void playMusicById(String musicId) {
  // Para música atual se estiver tocando
  stopCurrentMusic();
  
  // Encontra o arquivo correspondente ao ID
  String filename = "";
  for (int i = 0; i < sizeof(musicFiles)/sizeof(musicFiles[0]); i++) {
    if (musicFiles[i].id == musicId) {
      filename = musicFiles[i].filename;
      break;
    }
  }
  
  if (filename == "") {
    Serial.println("ID de música não encontrado: " + musicId);
    return;
  }
  
  // Verifica se o arquivo existe no SD
  if (!SD.exists(filename)) {
    Serial.println("Arquivo não encontrado no SD: " + filename);
    return;
  }
  
  // Inicia reprodução
  file = new AudioFileSourceSD(filename.c_str());
  if (!file->isOpen()) {
    Serial.println("Erro ao abrir arquivo: " + filename);
    delete file;
    file = nullptr;
    return;
  }
  
  out = new AudioOutputI2S();
  out->SetPinout(I2S_BCK_PIN, I2S_WS_PIN, I2S_DATA_PIN);
  mp3 = new AudioGeneratorMP3();
  mp3->begin(file, out);
  
  isPlaying = true;
  currentMusicId = musicId;
  Serial.println("Tocando música: " + musicId + " (" + filename + ")");
}

// ===============================================
// HANDLERS DO SERVIDOR WEB
// ===============================================

void handlePlay() {
  if (server.hasArg("plain")) {
    String body = server.arg("plain");
    
    // Parse JSON
    DynamicJsonDocument doc(1024);
    deserializeJson(doc, body);
    
    String musicId = doc["id"];
    
    if (musicId != "") {
      playMusicById(musicId);
      server.send(200, "text/plain", "OK");
      Serial.println("Comando PLAY recebido para: " + musicId);
    } else {
      server.send(400, "text/plain", "ID não fornecido");
    }
  } else {
    server.send(400, "text/plain", "Body vazio");
  }
}

void handleStop() {
  stopCurrentMusic();
  server.send(200, "text/plain", "OK");
  Serial.println("Comando STOP recebido");
}

void handleStatus() {
  DynamicJsonDocument doc(1024);
  doc["playing"] = isPlaying;
  doc["currentMusic"] = currentMusicId;
  
  String response;
  serializeJson(doc, response);
  
  server.send(200, "application/json", response);
}

// ===============================================
// FUNÇÃO 1: DOWNLOAD E SALVAMENTO DO ARQUIVO
// ===============================================

void downloadAndSaveFile() {
    Serial.println("\n-------------------------------------------");
    Serial.println("INICIANDO DOWNLOAD");
    Serial.printf("URL de destino: %s\n", musicUrl);
    
    // Debug Adicional: Imprime o IP do ESP32 imediatamente antes da requisição
    Serial.printf("IP LOCAL DO ESP32: %s\n", WiFi.localIP().toString().c_str()); 
    Serial.printf("IP DE DESTINO (FLASK): 192.168.40.154\n");
    Serial.println("-------------------------------------------");

    // Remove o arquivo antigo (se existir)
    if (SD.exists(downloadPath)) {
        SD.remove(downloadPath);
        Serial.printf("Arquivo antigo '%s' removido.\n", downloadPath);
    }

    HTTPClient http;
    http.begin(musicUrl);

    // Adiciona um timeout para que a função não fique travada indefinidamente
    http.setTimeout(10000); // 10 segundos

    int httpCode = http.GET(); // Inicia a requisição GET

    if (httpCode == HTTP_CODE_OK) {
        // Status 200 OK: Procede com o download
        int fileSize = http.getSize();
        Serial.printf("SUCESSO! Servidor respondeu (200 OK). Tamanho: %d bytes\n", fileSize);

        File downloadedFile = SD.open(downloadPath, FILE_WRITE);
        if (!downloadedFile) {
            Serial.println("ERRO FATAL: Falha ao abrir o arquivo no SD para escrita!");
            http.end();
            return;
        }

        WiFiClient *stream = http.getStreamPtr();
        int bytesWritten = 0;
        byte buffer[512]; 

        // Loop principal de leitura da rede e escrita no SD
        while (http.connected() && (bytesWritten < fileSize || fileSize == -1)) {
            size_t size = stream->available();
            if (size) {
                // Lê o máximo de dados disponíveis até 512 bytes
                int readBytes = stream->readBytes(buffer, ((size > sizeof(buffer)) ? sizeof(buffer) : size));
                downloadedFile.write(buffer, readBytes);
                bytesWritten += readBytes;
            }
        }

        downloadedFile.close();
        Serial.printf("\nDOWNLOAD CONCLUÍDO! Total de bytes salvos: %d\n", bytesWritten);

    } else {
        Serial.printf("\nERRO DE CONEXÃO. Código de resposta: %d\n", httpCode);
        if (httpCode == -1) {
            Serial.println("ERRO -1: Falha na conexão TCP. (Problema de Hotspot/Isolamento de Rede?)");
        } else {
            Serial.printf("Erro HTTP (%d): %s\n", httpCode, http.errorToString(httpCode).c_str());
        }
        Serial.println("Não foi possível baixar o arquivo. Verifique a URL e a API.");
    }

    http.end();
}

// ===============================================
// SETUP
// ===============================================

void setup() {
    Serial.begin(115200);
    delay(1000); 

    // --- 1. Conexão Wi-Fi com Debug ---
    Serial.print("\nConectando ao WiFi (SSID: ");
    Serial.print(ssid);
    Serial.print(")");

    WiFi.begin(ssid, password);
    
    int max_attempts = 20; // 10 segundos
    while (WiFi.status() != WL_CONNECTED && max_attempts > 0) {
        delay(500);
        Serial.print(".");
        max_attempts--;
    }

    if (WiFi.status() == WL_CONNECTED) {
        Serial.println("\n===========================================");
        Serial.println("SUCESSO NA CONEXÃO WI-FI!");
        Serial.printf("IP DO ESP32: %s\n", WiFi.localIP().toString().c_str()); 
        Serial.printf("IP DO SERVIDOR (FLASK): 192.168.40.154\n"); 
        Serial.println("===========================================");
    } else {
        Serial.println("\nFALHA NA CONEXÃO WI-FI. Verifique SSID/Senha.");
        while(1); 
    }

    // --- 2. Inicialização do SD Card ---
    Serial.print("Iniciando o SD... ");
    if (!SD.begin(SD_CS_PIN)) {
        Serial.println("FALHA CRÍTICA ao inicializar SD");
        while (1); 
    }
    Serial.println("OK");

    // --- 3. Configuração do Servidor Web ---
    server.on("/play", HTTP_POST, handlePlay);
    server.on("/stop", HTTP_POST, handleStop);
    server.on("/status", HTTP_GET, handleStatus);
    
    server.begin();
    Serial.println("Servidor HTTP iniciado na porta 80");
    Serial.println("Endpoints disponíveis:");
    Serial.println("  POST /play - Tocar música");
    Serial.println("  POST /stop - Parar música");
    Serial.println("  GET /status - Status atual");

    // --- 4. Execução do Download (opcional) ---
    // Adiciona um pequeno delay para garantir que o Wi-Fi esteja totalmente estabilizado
    delay(2000); 
    downloadAndSaveFile(); 
    
    Serial.println("Setup concluído. ESP32 pronto para receber comandos!");
}

// ===============================================
// LOOP
// ===============================================

void loop() {
    // Processa requisições HTTP
    server.handleClient();
    
    // Mantém a reprodução do áudio em loop
    if (mp3 && mp3->isRunning()) {
        if (!mp3->loop()) {
            Serial.println("Fim do arquivo, parando a reprodução.");
            stopCurrentMusic();
        }
    }
    
    delay(1);
}