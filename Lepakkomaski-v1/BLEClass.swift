//
//  BLEClass.swift
//  Lepakkomaski-v1
//
//  Created by Oskari Saarinen on 15.12.2020.
//

import CoreBluetooth

/// The UUID's of the target BLE device
fileprivate struct UUID_BLE {
    /// Service UUID
    let service_esp32 = CBUUID(string: "4fafc201-1fb5-459e-8fcc-c5c9c331914b")
    /// Distance characteristic UUID
    let characteristic_esp32 = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26a8")
    /// Shock characteristic UUID
    let characteristic_esp32_shock = CBUUID(string: "0c72cd85-ca45-46d9-a527-b5f92f815640")
}

class BLEClass: NSObject, ObservableObject, CBCentralManagerDelegate {
    
    /// The central manager object
    private var myCentral: CBCentralManager!
    /// The peripheral object
    private var lepakkomaskiPeripheral: CBPeripheral?
    /// The distance characteristic object
    private var distanceCharacteristic: CBCharacteristic?
    /// The shock characteristic object
    private var shockCharacteristic: CBCharacteristic?
 
    /// Is Bluetooth on?
    @Published var isSwitchedOn = false
    /// Distance value from BLE device
    @Published var distance = -1
    /// Signal strength of the connected BLE device
    @Published var rssi = -1
    /// Shock happened in the device?
    @Published var shock = false
    /// Is connected to the device?
    @Published var deviceConnected = false
    
    // Override the default init to add our own setups
    override init() {
        // This is the default init; Add your own init after it
        super.init()
        
        let centralQueue = DispatchQueue(label: "xyz.ssl-saario", attributes: [])
        myCentral = CBCentralManager(delegate: self, queue: centralQueue, options: [CBCentralManagerOptionShowPowerAlertKey: true])
        myCentral.delegate = self
    }
    
    /// Write a Int value into characteristic
    public func writeCMD(_ value: Int) {
      // See if characteristic has been discovered before writing to it
      if let distanceCharacteristic = self.distanceCharacteristic {
        // Convert Int into Data or return if there is an error
        guard let data = String(value).data(using: .utf8) else { return }
        // Write the data into charasteristic and send it
        self.lepakkomaskiPeripheral?.writeValue(data, for: distanceCharacteristic, type: CBCharacteristicWriteType.withResponse)
      }
    }
    
    /// Write a String value into characteristic
    public func writeMsg(_ msg: String) {
      // See if characteristic has been discovered before writing to it
      if let distanceCharacteristic = self.distanceCharacteristic {
        // Convert String into Data or return if there is an error
        guard let data = msg.data(using: .utf8) else { return }
        // Write the data into charasteristic and send it
        self.lepakkomaskiPeripheral?.writeValue(data, for: distanceCharacteristic, type: CBCharacteristicWriteType.withResponse)
      }
    }
    
    /// Get and update the distance value from the BLE
    public func updateDistance() {
        // Are we connected into the peripheral and it's charasteristic?
        guard (distanceCharacteristic != nil) && (lepakkomaskiPeripheral != nil) else { return }
        // Read the distance
        lepakkomaskiPeripheral!.readValue(for: distanceCharacteristic!)
    }
    
    // Close and re-connect to BLE
    public func reConnect() {
        print("reConnect() called")
        // Do we have saved the peripheral object
        guard let peripheral = lepakkomaskiPeripheral else { print("lepakkomaskiPeripheral is nil"); return }
        // Don't do anythingh if we are not connected to peripheral
        if case .connected = peripheral.state {
            for service in (peripheral.services ?? [] as [CBService]) {
                for characteristic in (service.characteristics ?? [] as [CBCharacteristic]) {
                    if ((characteristic.uuid == UUID_BLE().characteristic_esp32 || characteristic.uuid == UUID_BLE().characteristic_esp32_shock) && characteristic.isNotifying) {
                        // It is notifying, so unsubscribe
                        self.lepakkomaskiPeripheral?.setNotifyValue(false, for: characteristic)
                    }
                }
            }
        }
        // Disconnect the peripheral
        myCentral.cancelPeripheralConnection(peripheral)
        // After this the delegate method 'didDisconnectPeripheral' will be called
    }
    
    // MARK: - Helper Methods

    /*
     * We will first check if we are already connected to our counterpart
     * Otherwise, scan for peripherals - specifically for our service's 128bit CBUUID
     */
    private func retrievePeripheral() {
        /// The list of connected peripherals
        let connectedPeripherals: [CBPeripheral] = (myCentral.retrieveConnectedPeripherals(withServices: [UUID_BLE().service_esp32]))
        
        print("Found connected Peripherals with transfer service: \(connectedPeripherals)")
        
        // Is there any connected peripherals?
        if let connectedPeripheral = connectedPeripherals.last {
            print("Connecting to peripheral \(connectedPeripheral)")
            // Save the connected peripheral
            self.lepakkomaskiPeripheral = connectedPeripheral
            // Make the connection
            myCentral.connect(connectedPeripheral, options: nil)
        } else {
            print("Start scanning again")
            // We were not connected to our counterpart, so start scanning
            myCentral.scanForPeripherals(withServices: nil, options: nil)
            //myCentral.scanForPeripherals(withServices: [UUID_BLE().service_esp32], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
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
        // Unsubscribe all charasteristic connections in services
        for service in (discoveredPeripheral.services ?? [] as [CBService]) {
            for characteristic in (service.characteristics ?? [] as [CBCharacteristic]) {
                if ((characteristic.uuid == UUID_BLE().characteristic_esp32 || characteristic.uuid == UUID_BLE().characteristic_esp32_shock) && characteristic.isNotifying) {
                    // It is notifying, so unsubscribe
                    self.lepakkomaskiPeripheral?.setNotifyValue(false, for: characteristic)
                }
            }
        }
        // If we've gotten this far, we're connected, but we're not subscribed, so we just disconnect
        myCentral.cancelPeripheralConnection(discoveredPeripheral)
    }
    
    // When central manager updates it's state
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown: print("central.state is .unknown")
        case .resetting: print("central.state is .resetting")
        case .unsupported: print("central.state is .unsupported")
        case .unauthorized: print("central.state is .unauthorized")
        case .poweredOff: print("central.state is .poweredOff");
            DispatchQueue.main.async() { self.isSwitchedOn = false }
        case .poweredOn: print("central.state is .poweredOn")
            // Update the is bluetooth on -variable in the main thread
            DispatchQueue.main.async() { self.isSwitchedOn = true }
            // Start scanning for peripherals
            myCentral.scanForPeripherals(withServices: nil, options: nil)
            //myCentral.scanForPeripherals(withServices: [UUID_BLE().service_esp32])
            
        // Default for unknown state value (maybe in the newer OS there wil be new ones?)
        @unknown default: print("central.state is .unknown"); break
        }
    }
    
    // a New peripheral discovered
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Discovered a new peripheral: \(peripheral)")
        // Validate peripheral information
        if ((peripheral.name == nil) || (peripheral.name == "")) { return }
        // If not already connected to a peripheral, then connect to this one
        if ((self.lepakkomaskiPeripheral == nil) || (self.lepakkomaskiPeripheral?.state == CBPeripheralState.disconnected)) {
            print("Connecting to: \(peripheral)")
            // Retain the peripheral before trying to connect
            lepakkomaskiPeripheral = peripheral
            // Tell the peripheral object that it's delegate methods are defined in this class
            lepakkomaskiPeripheral!.delegate = self
            // Stop scanning for peripherals
            myCentral.stopScan()
            // Connect to peripheral
            myCentral.connect(lepakkomaskiPeripheral!, options: nil)
        } else {
            print("Already connected to: \(peripheral)")
        }
        // Update the rssi variable in the main thread
        DispatchQueue.main.async() { self.rssi = Int(truncating: RSSI) }
    }
    
    // Error connecting to peripheral
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral), \(String(describing: error))")
        cleanup()
    }
    
    // When connection happened
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard (lepakkomaskiPeripheral != nil) else { return }
        print("Connected!")
        lepakkomaskiPeripheral!.discoverServices([UUID_BLE().service_esp32])
    }
    
    // Once the disconnection happens, we need to clean up our local copy of the peripheral
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Perhiperal Disconnected")
        // Delete the saved peripheral
        lepakkomaskiPeripheral = nil
        // Update the is device connected -variable in the main thread
        DispatchQueue.main.async() { self.deviceConnected = false }
        // We're disconnected, so start scanning again
        retrievePeripheral()
    }
    

}

extension BLEClass: CBPeripheralDelegate {
    // New services discovered
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        // If there is an error, print it and call cleanup() then return
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            cleanup()
            return
        }
        // Get the services or return
        guard let services = peripheral.services else { return }
        // Search for characteristics in all services
        for service in services {
            print("service: \(service)")
            peripheral.discoverCharacteristics([UUID_BLE().characteristic_esp32, UUID_BLE().characteristic_esp32_shock], for: service)
            //peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    // a New characteristic found
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            // If there is an error, print it and call cleanup() then return
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
            } else if characteristic.uuid == UUID_BLE().characteristic_esp32_shock && characteristic.properties.contains(.read) {
                shockCharacteristic = characteristic
                peripheral.readValue(for: characteristic)
            }
        }
    }
    
    // a Characteristic got an update
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        // If there is an error, print it and call cleanup() then return else if the peripheral is nil then return
        if let error = error {
            print("Error discovering characteristics: \(error.localizedDescription)")
            cleanup()
            return
        } else if (lepakkomaskiPeripheral == nil) {
            print("nil")
            return
        }
        // Is the characteristic the one we are looking for?
        switch characteristic.uuid {
        case UUID_BLE().characteristic_esp32:
            print("characteristic_esp32CBUUID")
            // Try to get the distance from characteristic or return
            guard let val = self.getIntFromBLEChar(from: characteristic) else {
                print("getIntFromBLEChar() is nil");
                // Update the is device connected -variable in the main thread
                DispatchQueue.main.async() { self.deviceConnected = false }
                return
            }
            // Update the is device connected -variable in the main thread
            DispatchQueue.main.async() { self.deviceConnected = true }
            // We got a value, now update it in the main thread
            if (self.distance != val) {
                // We received a distance value
                DispatchQueue.main.async() { self.distance = val }
            } else { print("Value not changed") }
            
        case UUID_BLE().characteristic_esp32_shock:
            print("shock_characteristic_esp32CBUUID")
            // Try to get the distance from characteristic or return
            guard let val = self.getIntFromBLEChar(from: characteristic) else {
                print("getIntFromBLEChar() is nil");
                // Update the is device connected -variable in the main thread
                DispatchQueue.main.async() { self.deviceConnected = false }
                return
            }
            // Update the is device connected -variable in the main thread
            DispatchQueue.main.async() { self.deviceConnected = true }
            // We got a value, now update it in the main thread
            if (val == 1) {
                // Shock sensor returned true
                DispatchQueue.main.async() { if (!self.shock) { self.shock = true } }
                print("SHOCK!!!")
            } else {
                // Shock sensor returned false
                DispatchQueue.main.async() { if (self.shock) { self.shock = false } }
            }
            
        //case anotherCBUUID: break
        default: print("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
        // Update the RSSI value (signal strength)
        lepakkomaskiPeripheral!.readRSSI()
    }
    
    // The peripheral letting us know whether our subscribe/unsubscribe happened or not
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        // Deal with errors (if any)
        if let error = error {
            print("Error changing notification state: \(error.localizedDescription)")
            return
        }
        // Exit if it's not the right characteristic
        guard characteristic.uuid == UUID_BLE().characteristic_esp32 else { return }
        // Is it notifying?
        if characteristic.isNotifying {
            // Notification has started
            print("Notification began on \(characteristic)")
        } else {
            // Notification has stopped, so disconnect from the peripheral
            print("Notification stopped on \(characteristic) Disconnecting")
            cleanup()
        }
    }
    
    // RSSI has been read
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        // Deal with errors (if any)
        if let error = error {
            print("Error reading RSSI value: \(error.localizedDescription)")
            return
        }
        print("RSSI updated (\(RSSI))")
        // Update the RSSI in the main thread
        DispatchQueue.main.async() { self.rssi = Int(truncating: RSSI) }
    }
    
    /// Try to read and convert a value from the characteristic as Int
    private func getIntFromBLEChar(from characteristic: CBCharacteristic) -> Int? {
        print("getIntFromBLEChar()")
        // Try to get the data or return
        guard let characteristicData = characteristic.value else { return nil }
        // Print the data as a UTF8 decoded String
        print(String(data: characteristicData, encoding: .utf8) ?? "No data")
        // Print the data as a base 64 encoded string
        print(characteristicData.base64EncodedString())
        // Return the value if it's in a valid format (convertable to Int value)
        return Int.init(String.init(data: characteristicData, encoding: .utf8) ?? "")
    }
    
    

}
