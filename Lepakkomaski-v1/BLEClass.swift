//
//  BLEClass.swift
//  Lepakkomaski-v1
//
//  Created by Oskari Saarinen on 15.12.2020.
//

//import UIKit
import CoreBluetooth

struct UUID_BLE {
    let service_esp32 = CBUUID(string: "4fafc201-1fb5-459e-8fcc-c5c9c331914b")
    let characteristic_esp32 = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26a8")
}

class BLEClass: /*UIViewController*/NSObject, ObservableObject, CBCentralManagerDelegate {
    
    var myCentral: CBCentralManager!
    
    var lepakkomaskiPeripheral: CBPeripheral?
    
    var distanceCharacteristic: CBCharacteristic?
 
    @Published var isSwitchedOn = false
    
    @Published var distance = -1
    
    @Published var rssi = -1
    
    @Published var shock = false
    
    //@Published var connectedPeripherals: [CBPeripheral] = []
    
    /*override func viewDidLoad() {
        super.viewDidLoad()
        
        let centralQueue = DispatchQueue(label: "xyz.ssl-saario", attributes: [])
        myCentral = CBCentralManager(delegate: self, queue: centralQueue, options: [CBCentralManagerOptionShowPowerAlertKey: true])
        myCentral.delegate = self
    }*/
    
    override init() {
        super.init()
        
        let centralQueue = DispatchQueue(label: "xyz.ssl-saario", attributes: [])
        myCentral = CBCentralManager(delegate: self, queue: centralQueue, options: [CBCentralManagerOptionShowPowerAlertKey: true])
        myCentral.delegate = self
    }
    
    func updateDistance() {
        guard (distanceCharacteristic != nil) && (lepakkomaskiPeripheral != nil) else { return }
        lepakkomaskiPeripheral!.readValue(for: distanceCharacteristic!)
    }
    
    func reConnect() {
        print("reConnect() called")
        guard let peripheral = lepakkomaskiPeripheral else { print("lepakkomaskiPeripheral is nil"); return }
        
        if case .connected = peripheral.state {
            for service in (peripheral.services ?? [] as [CBService]) {
                for characteristic in (service.characteristics ?? [] as [CBCharacteristic]) {
                    if characteristic.uuid == UUID_BLE().characteristic_esp32 && characteristic.isNotifying {
                        // It is notifying, so unsubscribe
                        self.lepakkomaskiPeripheral?.setNotifyValue(false, for: characteristic)
                    }
                }
            }
        }
        
        // If we've gotten this far, we're connected, but we're not subscribed, so we just disconnect
        myCentral.cancelPeripheralConnection(peripheral)
    }
    
    // MARK: - Helper Methods

    /*
     * We will first check if we are already connected to our counterpart
     * Otherwise, scan for peripherals - specifically for our service's 128bit CBUUID
     */
    private func retrievePeripheral() {
        
        let connectedPeripherals: [CBPeripheral] = (myCentral.retrieveConnectedPeripherals(withServices: [UUID_BLE().service_esp32]))
        //myCentral.retrieveConnectedPeripherals(withServices: <#[CBUUID]#>)
        
        print("Found connected Peripherals with transfer service: \(connectedPeripherals)")
        
        if let connectedPeripheral = connectedPeripherals.last {
            print("Connecting to peripheral \(connectedPeripheral)")
            self.lepakkomaskiPeripheral = connectedPeripheral
            myCentral.connect(connectedPeripheral, options: nil)
        } else {
            print("Start scanning again")
            // We were not connected to our counterpart, so start scanning
            //myCentral.scanForPeripherals(withServices: [UUID_BLE().service_esp32], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
            myCentral.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    /*
     *  Call this when things either go wrong, or you're done with the connection.
     *  This cancels any subscriptions if there are any, or straight disconnects if not.
     *  (didUpdateNotificationStateForCharacteristic will cancel the connection if a subscription is involved)
     */
    private func cleanup() {
        // Don't do anything if we're not connected
        guard let discoveredPeripheral = lepakkomaskiPeripheral,
              case .connected = discoveredPeripheral.state else { print("guard return in cleanup()"); return }
        
        for service in (discoveredPeripheral.services ?? [] as [CBService]) {
            for characteristic in (service.characteristics ?? [] as [CBCharacteristic]) {
                if characteristic.uuid == UUID_BLE().characteristic_esp32 && characteristic.isNotifying {
                    // It is notifying, so unsubscribe
                    self.lepakkomaskiPeripheral?.setNotifyValue(false, for: characteristic)
                }
            }
        }
        
        // If we've gotten this far, we're connected, but we're not subscribed, so we just disconnect
        myCentral.cancelPeripheralConnection(discoveredPeripheral)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown: print("central.state is .unknown")
        case .resetting: print("central.state is .resetting")
        case .unsupported: print("central.state is .unsupported")
        case .unauthorized: print("central.state is .unauthorized")
        case .poweredOff: print("central.state is .poweredOff");
            DispatchQueue.main.async() { self.isSwitchedOn = false }
        case .poweredOn: print("central.state is .poweredOn")
            DispatchQueue.main.async() { self.isSwitchedOn = true }
            myCentral.scanForPeripherals(withServices: nil, options: nil)
            //myCentral.scanForPeripherals(withServices: [UUID_BLE().service_esp32])
            
        @unknown default: print("central.state is .unknown"); break
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Discovered a new peripheral: \(peripheral)")
        // Validate peripheral information
        if ((peripheral.name == nil) || (peripheral.name == "")) {
            return
        }
        
        // If not already connected to a peripheral, then connect to this one
        if ((self.lepakkomaskiPeripheral == nil) || (self.lepakkomaskiPeripheral?.state == CBPeripheralState.disconnected)) {
            print("Connecting to: \(peripheral)")
            // Retain the peripheral before trying to connect
            lepakkomaskiPeripheral = peripheral
            lepakkomaskiPeripheral!.delegate = self
            myCentral.stopScan()
          
            // Reset service
            //self.bleService = nil
          
            // Connect to peripheral
            myCentral.connect(lepakkomaskiPeripheral!, options: nil)
            //central.connect(peripheral, options: nil)
        } else {
            print("Already connected to: \(peripheral)")
        }
        
        DispatchQueue.main.async() { self.rssi = Int(truncating: RSSI) }
        
        /*lepakkomaskiPeripheral = peripheral
        lepakkomaskiPeripheral.delegate = self
        myCentral.stopScan()
        myCentral.connect(lepakkomaskiPeripheral)*/
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral), \(String(describing: error))")
        cleanup()
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard (lepakkomaskiPeripheral != nil) else { return }
        print("Connected!")
        lepakkomaskiPeripheral!.discoverServices([UUID_BLE().service_esp32])
    }
    
    /*
     *  Once the disconnection happens, we need to clean up our local copy of the peripheral
     */
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Perhiperal Disconnected")
        lepakkomaskiPeripheral = nil
        
        // We're disconnected, so start scanning again
        retrievePeripheral()
    }
    

}

extension BLEClass: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            cleanup()
            return
        }
        
        guard let services = peripheral.services else { return }
        for service in services {
            print("service: \(service)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Error discovering characteristics: \(error.localizedDescription)")
            cleanup()
            return
        }
        
        guard let characteristics = service.characteristics else { return }

        for characteristic in characteristics {
            print("characteristic: \(characteristic)")
            
            /*if characteristic.properties.contains(.read) {
                print("\(characteristic.uuid): properties contains .read")
                peripheral.readValue(for: characteristic)
            }
            
            if characteristic.properties.contains(.notify) {
                print("\(characteristic.uuid): properties contains .notify")
                peripheral.setNotifyValue(true, for: characteristic)
            }*/
            
            if characteristic.uuid == UUID_BLE().characteristic_esp32 && characteristic.properties.contains(.read) {
                distanceCharacteristic = characteristic
                peripheral.readValue(for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error discovering characteristics: \(error.localizedDescription)")
            cleanup()
            return
        } else if (lepakkomaskiPeripheral == nil) {
            print("nil")
            return
        }
        
        switch characteristic.uuid {
        case UUID_BLE().characteristic_esp32:
            print("characteristic_esp32CBUUID")
            let val = self.getDistance(from: characteristic)
            if (self.distance == 1) {
                DispatchQueue.main.async() {
                    self.shock = true
                }
            } else if (self.distance != val) {
                DispatchQueue.main.async() {
                    if (self.shock) {
                        self.shock = false
                    }
                    self.distance = val
                }
            } else { print("Value not changed") }
            
        //case anotherCBUUID: break
        default:
          print("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
        
        // Timer function?
        
        lepakkomaskiPeripheral!.readRSSI()
    }
    
    /*
     *  The peripheral letting us know whether our subscribe/unsubscribe happened or not
     */
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        // Deal with errors (if any)
        if let error = error {
            print("Error changing notification state: \(error.localizedDescription)")
            return
        }
        
        // Exit if it's not the transfer characteristic
        guard characteristic.uuid == UUID_BLE().characteristic_esp32 else { return }
        
        if characteristic.isNotifying {
            // Notification has started
            print("Notification began on \(characteristic)")
        } else {
            // Notification has stopped, so disconnect from the peripheral
            print("Notification stopped on \(characteristic) Disconnecting")
            cleanup()
        }
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        // Deal with errors (if any)
        if let error = error {
            print("Error reading RSSI value: \(error.localizedDescription)")
            return
        }
        print("RSSI updated (\(RSSI))")
        DispatchQueue.main.async() { self.rssi = Int(truncating: RSSI) }
    }
    
    private func getDistance(from characteristic: CBCharacteristic) -> Int {
        print("getDistance()")
        guard let characteristicData = characteristic.value else { return -1 }
        
        print(String(data: characteristicData, encoding: .utf8) ?? "No data")
        print(characteristicData.base64EncodedString())
        
        return Int.init(String.init(data: characteristicData, encoding: .utf8) ?? "") ?? -1
        
        /*let byteArray = [UInt8](characteristicData)
        let firstBitValue = byteArray[0] & 0x01
        
        return Int(byteArray[1])*/

        // See: https://www.bluetooth.com/specifications/gatt/viewer?attributeXmlFile=org.bluetooth.characteristic.heart_rate_measurement.xml
        // The heart rate mesurement is in the 2nd, or in the 2nd and 3rd bytes, i.e. one one or in two bytes
        // The first byte of the first bit specifies the length of the heart rate data, 0 == 1 byte, 1 == 2 bytes
        /*let byteArray = [UInt8](characteristicData)
        let firstBitValue = byteArray[0] & 0x01
        if firstBitValue == 0 {
            // Heart Rate Value Format is in the 2nd byte
            return Int(byteArray[1])
        } else {
            // Heart Rate Value Format is in the 2nd and 3rd bytes
            return (Int(byteArray[1]) << 8) + Int(byteArray[2])
        }*/
    }
}
