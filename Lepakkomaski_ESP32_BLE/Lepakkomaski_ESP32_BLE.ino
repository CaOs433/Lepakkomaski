#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>

// See the following for generating UUIDs:
// https://www.uuidgenerator.net/

// The UUID's for BLE
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

#define ht 5 // define the heart rate sensor Pin 
#define shock 4 // define the shock sensor Pin 
#define echoPin 25 // define the HC-SR04 echo Pin
#define trigPin 26 // define the HC-SR04 trig Pin

// Counter for test value
int counter;

// Distance value
int distance = -1;

// BLE variables
BLEServer *pServer;
BLEService *pService;
BLECharacteristic *pCharacteristic;
BLEAdvertising *pAdvertising;

int measure();
bool getShock();
// Reset function
void(* resetFunc) (void) = 0;

// Callbacks to handle the received data
class MyCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      std::string value = pCharacteristic->getValue();
      // Print received value on Serial Monitor (if value length is bigger than zero)
      if (value.length() > 0) {
        Serial.print("\nReceived new value: ");
        for (int i = 0; i < value.length(); i++) {
          Serial.print(value[i]);
          // ...
        }

        Serial.println();

        // Switch cases for different values
        switch (value[0]) {
          case '0': Serial.println("RESET"); resetFunc(); // Call reset function if first char is '0'
          case '1': break; // ...
          case '2': break; // ...
          // ...

          default: break;
        }
      }
    }
};

void setup() {
  counter = 0;
  // Set baud rate for serial
  Serial.begin(115200);

  // Set BLE device name
  BLEDevice::init("Lepakkomaski");
  // Create BLE server
  pServer = BLEDevice::createServer();
  // Create service for BLE server
  pService = pServer->createService(SERVICE_UUID);
  // Create charasteristic for the BLE service (this will include the distance value)
  pCharacteristic = pService->createCharacteristic(
                                         CHARACTERISTIC_UUID,
                                         BLECharacteristic::PROPERTY_READ |
                                         BLECharacteristic::PROPERTY_WRITE
                                       );
  // Set callbacks to handle received data
  pCharacteristic->setCallbacks(new MyCallbacks());
  // Set value to charasteristic to be sent in it
  pCharacteristic->setValue("Hello World");
  // Start the service
  pService->start();
  // Set and start adversiting of the BLE
  pAdvertising = pServer->getAdvertising();
  pAdvertising->start();

  // HC-SR04 Ultrasonic sensor setup
  pinMode(trigPin, OUTPUT); // Sets the trigPin as an OUTPUT
  pinMode(echoPin, INPUT); // Sets the echoPin as an INPUT
  Serial.println("Ultrasonic Sensor HC-SR04 with ESP32 - BLE");
}

void loop() {
  //counter++;
  
  // Get shock sensor result
  bool gotShock = getShock();
  // Did a shock happened?
  if (!gotShock) {
    // If so send 1 as a String value instead of the ditance by BLE
    String shockStr = String(1);
    pCharacteristic->setValue(std::string(shockStr.c_str()));
    // Wait till the shock has ended
    while (!gotShock) {
      Serial.println("SHOCK!!!");
      delay(10);
      gotShock = getShock();
    }
  }

  // Get distance
  int dVal = measure();
  // Update BLE distance charasteristic value if the distance has new value and is in the right range
  if (dVal != distance && dVal >= 2 && dVal <= 400) {
    //delay(10);
    String distanceStr = String(dVal);//counter); //measure()); //+" - Counter:\t "+String(counter);
    //delay(10);
    pCharacteristic->setValue(std::string(distanceStr.c_str()));
  }
  
}

// Measures the distance and returns it as int value in centimeters
int measure() {
  // Clears the trigPin condition
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  // Sets the trigPin HIGH (ACTIVE) for 10 microseconds
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);
  // Reads the echoPin, returns the sound wave travel time in microseconds
  long duration = pulseIn(echoPin, HIGH); // The duration of sound wave travel
  // Calculating the distance
  int distanceVal = duration * 0.034 / 2; // Speed of sound wave divided by 2 (go and back) (distance measurement)

  // Prints the distance on terminal if value is in the right range
  if(distanceVal >= 2 && distanceVal <= 400 ) {
    // Displays the distance on the Serial Monitor
    Serial.print("Distance: ");
    Serial.print(distanceVal);
    Serial.println(" cm");
  }

  //counter++;

  return distanceVal;
}

// Reads shock sensors value and returns true if a shock happened
bool getShock() {
  int sVal = digitalRead(shock); // read the value from KY-002
  if (sVal == HIGH ) { 
    return true;
  } else {
    return false;
  }
}
