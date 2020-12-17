//
//  LepakkomaskiView.swift
//  Lepakkomaski-v1
//
//  Created by Oskari Saarinen on 15.12.2020.
//

import SwiftUI
import CoreBluetooth

struct LepakkomaskiView: View {
    
    @ObservedObject var ble = BLEClass()
    
    @State private var distance = -1
    
    @State private var msg: String = ""
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    let generator = UINotificationFeedbackGenerator()
    
    var body: some View {
        VStack (spacing: 10) {
            Text("Lepakkomaski")
                .font(.largeTitle)
                .frame(maxWidth: .infinity, alignment: .center)
 
            Text("STATUS").font(.headline)
            
            if ble.isSwitchedOn {
                Text("Bluetooth is switched on").foregroundColor(.green)
            } else {
                Text("Bluetooth is NOT switched on").foregroundColor(.red)
            }
            
            Text("RSSI: \(ble.rssi) dB")
            
            Text((ble.distance >= 0 && ble.distance <= 400) ? "Distance: \(m(ble.distance))" : "Distance: ? (\(ble.distance))")/*.onReceive(timer) { input in
                ble.updateDistance()
            }*/.padding()
            
            TextField("msg", text: $msg).padding()
            
            //TextField("distance", text: $distance).padding()
            
            Button(action: {
                //self.bleManager.startScanning()
                print("Write button")
            }) { Text("Write") }
            
            Button(action: {
                ble.updateDistance()
            }) { Text("Read") }
            
            Button(action: {
                ble.reConnect()
            }) { Text("Re connect") }
            
        }.onReceive(timer) { input in
            ble.updateDistance()
            if (ble.shock) {
                print("Shock")
            } else if ble.distance >= 2 && ble.distance < 100 {
                generator.notificationOccurred(.error)
            }
        }.padding()//.onAppear(perform: startBT)
    }
    
    // Get distance String with unit
    private func m(_ val: Int) -> String {
        if val < 100 {
            return "\(val) cm"
        } else {
            return "\(Double(val)/100) m"
        }
    }
    
    /*private func startBT() {
        // Start the Bluetooth discovery process
        _ = BLECentral()//btDiscoverySharedInstance
    }*/
}

struct LepakkomaskiView_Previews: PreviewProvider {
    static var previews: some View {
        LepakkomaskiView()
    }
}
