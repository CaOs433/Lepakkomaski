//
//  ContentView.swift
//  Lepakkomaski-v1 WatchKit Extension
//
//  Created by Oskari Saarinen on 8.12.2020.
//

import SwiftUI
import Foundation

struct ContentView: View {
    
    @ObservedObject var ble = BLEClass()
    
    @State private var distance: Int = -1
    
    @State private var msg: String = ""
    
    @State private var bgColorShock: Bool = false
    
    @State private var deviceConnected: Bool = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Color(bgColorShock ? CGColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0) : CGColor(gray: 0.5, alpha: 0.1)).edgesIgnoringSafeArea(.vertical) // Ignore just for the color
            .overlay(
                ScrollView {
                    Text("Lepakkomaski")
                        .font(.largeTitle)
                        .frame(maxWidth: .infinity, alignment: .center)
         
                    Text("STATUS").font(.headline)
                    
                    if ble.isSwitchedOn {
                        Text("Bluetooth is switched on").foregroundColor(.green)
                    } else {
                        Text("Bluetooth is NOT switched on").foregroundColor(.red)
                    }
                    
                    if deviceConnected {
                        Text("Device connected").foregroundColor(.green)
                    } else {
                        Text("Device disconnected").foregroundColor(.red)
                    }
                    
                    Text("RSSI: \(ble.rssi) dB")
                    
                    Text((ble.distance >= 0 && ble.distance <= 400) ? "Distance: \(m(ble.distance))" : "Distance: ? (\(ble.distance))").padding()
                    
                    VStack {
                        Text("Write a message to BLE")
                        HStack {
                            TextField("msg", text: $msg)
                            Button(action: {
                                print("Write")
                                ble.writeMsg(msg)
                            }) { Text("Write") }
                        }.background(Color.gray.opacity(0.6))
                    }.background(Color.gray.opacity(0.4)).padding()
                    
                    Button(action: {
                        print("Reset ESP32")
                        ble.writeCMD(0)
                    }) { Text("Reset ESP32") }
                    
                    Button(action: {
                        ble.updateDistance()
                    }) { Text("Read") }
                    
                    Button(action: {
                        ble.reConnect()
                    }) { Text("Re connect") }
                    
                    /*Button(action: { haptic(wkhType: .failure) }) {
                        Text("Haptic")
                    }.padding()*/
                    
                // Timer to execute updates
                }.onReceive(timer) { input in
                    ble.updateDistance()
                    if (ble.deviceConnected) {
                        if (deviceConnected == false) {
                            deviceConnected = true
                        }
                        if (ble.shock) {
                            print("Shock")
                            bgColorShock = true
                        } else if ble.distance >= 2 && ble.distance < 100 {
                            if (bgColorShock == true) {
                                bgColorShock = false
                            }
                            haptic(wkhType: .failure)
                        }
                    } else {
                        if (deviceConnected == true) {
                            deviceConnected = false
                        }
                        if (bgColorShock == true) {
                            bgColorShock = false
                            print("Device is disconnected")
                        }
                    }
                    
                }.padding()
            )
    }
    
    // Get distance String with unit
    private func m(_ val: Int) -> String {
        if val < 100 {
            return "\(val) cm"
        } else {
            return "\(Double(val)/100) m"
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


