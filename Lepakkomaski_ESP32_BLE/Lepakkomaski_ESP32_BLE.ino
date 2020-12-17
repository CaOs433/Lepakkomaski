#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>

// See the following for generating UUIDs:
// https://www.uuidgenerator.net/

#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

#define ht 5 // define the heart rate sensor Pin 
#define shock 4 // define the shock sensor Pin 
#define echoPin 25 // define the HC-SR04 echo Pin
#define trigPin 26 // define the HC-SR04 trig Pin

int counter;

int distance = -1;

BLEServer *pServer;
BLEService *pService;
BLECharacteristic *pCharacteristic;
BLEAdvertising *pAdvertising;

int measure();
bool getShock();

// Callbacks to handle received data
class MyCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      std::string value = pCharacteristic->getValue();
      // Print received value on Serial Monitor (if value length is bigger than zero)
      if (value.length() > 0) {
        Serial.print("\nReceived new value: ");
        for (int i = 0; i < value.length(); i++)
          Serial.print(value[i]);

        Serial.println();
      }
    }
};

void setup() {
  counter = 0;
  Serial.begin(115200);
  
  BLEDevice::init("Lepakkomaski");
  pServer = BLEDevice::createServer();

  pService = pServer->createService(SERVICE_UUID);

  pCharacteristic = pService->createCharacteristic(
                                         CHARACTERISTIC_UUID,
                                         BLECharacteristic::PROPERTY_READ |
                                         BLECharacteristic::PROPERTY_WRITE
                                       );

  pCharacteristic->setCallbacks(new MyCallbacks());

  pCharacteristic->setValue("Hello World");
  pService->start();

  pAdvertising = pServer->getAdvertising();
  pAdvertising->start();

  pinMode(trigPin, OUTPUT); // Sets the trigPin as an OUTPUT
  pinMode(echoPin, INPUT); // Sets the echoPin as an INPUT
  Serial.println("Ultrasonic Sensor HC-SR04 with ESP32 - BLE");
}

void loop() {
  // put your main code here, to run repeatedly:
  //counter++;
  bool gotShock = getShock();
  if (!gotShock) {
    String shockStr = String(1);
    pCharacteristic->setValue(std::string(shockStr.c_str()));
    while (!gotShock) {
      Serial.println("SHOCK!!!");
      delay(10);
      gotShock = getShock();
    }
  }
  
  int val = measure();
  if (val != distance && val >= 2 && val <= 400) {
    //delay(10);
    String distanceStr = String(val);//counter); //measure()); //+" - Counter:\t "+String(counter);
    //delay(10);
    pCharacteristic->setValue(std::string(distanceStr.c_str()));
  }
  
}

int measure() {
  // Clears the trigPin condition
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  // Sets the trigPin HIGH (ACTIVE) for 10 microseconds
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);
  // Reads the echoPin, returns the sound wave travel time in microseconds
  long duration = pulseIn(echoPin, HIGH); // duration of sound wave travel
  // Calculating the distance
  int distanceVal = duration * 0.034 / 2; // Speed of sound wave divided by 2 (go and back) (distance measurement)

  if(distanceVal >= 2 && distanceVal <= 400 ) {
    // Displays the distance on the Serial Monitor
    Serial.print("Distance: ");
    Serial.print(distanceVal);
    Serial.println(" cm");
  }

  //counter++;

  return distanceVal;
}

bool getShock() {
  int val = digitalRead(shock); // read the value from KY-002
  if (val == HIGH ) { 
    return true;
  } else {
    return false;
  }
}
