//
//  BLEManager.swift
//  Lepakkomaski-v1
//
//  Created by Oskari Saarinen on 12.12.2020.
//

/*import Foundation
import CoreBluetooth

struct Peripheral: Identifiable {
    let id: Int
    let name: String
    let rssi: Int
}

/* Services & Characteristics UUIDs */
let BLEServiceUUID = CBUUID(string: "4fafc201-1fb5-459e-8fcc-c5c9c331914b") // "025A7775-49AA-42BD-BBDB-E2AE77782966"
let valCharUUID = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26a8") // "F38A2C23-BC54-40FC-BED0-60EDDA139F47"
let BLEServiceChangedStatusNotification = "kBLEServiceChangedStatusNotification"
 
class BLEPeripheral: NSObject, CBPeripheralDelegate {
 
    var myCentral: CBCentralManager!
    var peripheral: CBPeripheral?
    var valCharacteristic: CBCharacteristic?
    
    var data = Data()
 
    @Published var isSwitchedOn = false
    
    @Published var peripherals = [Peripheral]()
 
    init(initWithPeripheral peripheral: CBPeripheral) {
      super.init()
      
      self.peripheral = peripheral
      self.peripheral?.delegate = self
    }
    
    deinit { self.reset() }
    
    func startDiscoveringServices() {
      self.peripheral?.discoverServices([BLEServiceUUID])
    }
    
    func reset() {
      if peripheral != nil {
        peripheral = nil
      }
      // Deallocating therefore send notification
      self.sendBTServiceNotificationWithIsBluetoothConnected(false)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
      let uuidsForBTService: [CBUUID] = [valCharUUID]
      
      if (peripheral != self.peripheral) {
        // Wrong Peripheral
        return
      }
      
      if (error != nil) { return }
      
      if ((peripheral.services == nil) || (peripheral.services!.count == 0)) {
        // No Services
        return
      }
      
      for service in peripheral.services! {
        if service.uuid == BLEServiceUUID {
          peripheral.discoverCharacteristics(uuidsForBTService, for: service)
        }
      }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
      if (peripheral != self.peripheral) {
        // Wrong Peripheral
        return
      }
      
      if (error != nil) {
        return
      }
      
      if let characteristics = service.characteristics {
        for characteristic in characteristics {
          if characteristic.uuid == valCharUUID {
            self.valCharacteristic = (characteristic)
            peripheral.setNotifyValue(true, for: characteristic)
            
            // Send notification that Bluetooth is connected and all required characteristics are discovered
            self.sendBTServiceNotificationWithIsBluetoothConnected(true)
          }
        }
      }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        // Deal with errors (if any)
        if let error = error {
            print("Error discovering characteristics: %s", error.localizedDescription)
            //cleanup()
            return
        }
        
        guard let characteristicData = characteristic.value,
            let stringFromData = String(data: characteristicData, encoding: .utf8) else { return }
        
        print("Received %d bytes: %s", characteristicData.count, stringFromData)
        
        // Have we received the end-of-message token?
        if stringFromData == "EOM" {
            // End-of-message case: show the data.
            // Dispatch the text view update to the main queue for updating the UI, because
            // we don't know which thread this method will be called back on.
            DispatchQueue.main.async() {
                //self.textView.text = String(data: self.data, encoding: .utf8)
            }
            
            // Write test data
            //writeData()
        } else {
            // Otherwise, just append the data to what we have previously received.
            data.append(characteristicData)
            print(data.base64EncodedString())
        }
    }
    
    func write(_ val: UInt8) {
      // See if characteristic has been discovered before writing to it
      if let positionCharacteristic = self.valCharacteristic {
        let data = Data([val])
        self.peripheral?.writeValue(data, for: positionCharacteristic, type: CBCharacteristicWriteType.withResponse)
      }
    }
    
    func sendBTServiceNotificationWithIsBluetoothConnected(_ isBluetoothConnected: Bool) {
      let connectionDetails = ["isConnected": isBluetoothConnected]
      NotificationCenter.default.post(name: Notification.Name(rawValue: BLEServiceChangedStatusNotification), object: self, userInfo: connectionDetails)
    }
    
    
    
 
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            isSwitchedOn = true
        } else {
            isSwitchedOn = false
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        var peripheralName: String!
       
        if let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            peripheralName = name
        } else {
            peripheralName = "Unknown"
        }
       
        let newPeripheral = Peripheral(id: peripherals.count, name: peripheralName, rssi: RSSI.intValue)
        print(newPeripheral)
        peripherals.append(newPeripheral)
    }
    
    func startScanning() {
        print("startScanning")
        myCentral.scanForPeripherals(withServices: nil, options: nil)
    }
    
    func stopScanning() {
        print("stopScanning")
        myCentral.stopScan()
    }
    
    
 
}*/












// Vanha
/*struct Peripheral: Identifiable {
    let id: Int
    let name: String
    let rssi: Int
}
 
class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate {
 
    var myCentral: CBCentralManager!
 
    @Published var isSwitchedOn = false
    
    @Published var peripherals = [Peripheral]()
 
    override init() {
        super.init()
 
        myCentral = CBCentralManager(delegate: self, queue: nil)
        myCentral.delegate = self
    }
 
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            isSwitchedOn = true
        } else {
            isSwitchedOn = false
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        var peripheralName: String!
       
        if let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            peripheralName = name
        } else {
            peripheralName = "Unknown"
        }
       
        let newPeripheral = Peripheral(id: peripherals.count, name: peripheralName, rssi: RSSI.intValue)
        print(newPeripheral)
        peripherals.append(newPeripheral)
    }
    
    func startScanning() {
        print("startScanning")
        myCentral.scanForPeripherals(withServices: nil, options: nil)
    }
    
    func stopScanning() {
        print("stopScanning")
        myCentral.stopScan()
    }
 
}*/
