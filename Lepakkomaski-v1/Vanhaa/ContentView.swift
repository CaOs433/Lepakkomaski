//
//  ContentView.swift
//  Lepakkomaski-v1
//
//  Created by Oskari Saarinen on 8.12.2020.
//

/*import SwiftUI
import CoreBluetooth

struct ContentView: View {
    
    //@ObservedObject var bleManager = BLEPeripheral()
    
    var bleCentral = BLECentral()
    
    @State private var msg: String = ""
    
    var body: some View {
        VStack (spacing: 10) {
            Text("Lepakkomaski")
                .font(.largeTitle)
                .frame(maxWidth: .infinity, alignment: .center)
 
            Spacer()
 
            Text("STATUS").font(.headline)
            
            /*if bleManager.isSwitchedOn {
                Text("Bluetooth is switched on").foregroundColor(.green)
            } else {
                Text("Bluetooth is NOT switched on").foregroundColor(.red)
            }*/
 
            Spacer()
            
            TextField("Placeholder", text: $msg).padding()
            
            Button(action: {
                //self.bleManager.startScanning()
                if let bleService = btDiscoverySharedInstance.bleService {
                  bleService.write(13)
                } else { print("False") }
            }) { Text("Write") }
            
            Spacer()
 
            HStack {
                VStack (spacing: 10) {
                    Button(action: {
                        //self.bleManager.startScanning()
                    }) { Text("Start Scanning") }
                    Button(action: {
                        //self.bleManager.stopScanning()
                    }) { Text("Stop Scanning") }
                }.padding()
            }
            Spacer()
        }.onAppear(perform: startBT)
    }
    
    private func startBT() {
        // Start the Bluetooth discovery process
        _ = BLECentral()//btDiscoverySharedInstance
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}*/













// Vanha

/*struct ContentView: View {
    @ObservedObject var bleManager = BLEManager()
    
    var body: some View {
        VStack (spacing: 10) {
            Text("Bluetooth Devices")
                .font(.largeTitle)
                .frame(maxWidth: .infinity, alignment: .center)
            List(bleManager.peripherals) { peripheral in
                HStack {
                    Text(peripheral.name)
                    Spacer()
                    Text(String(peripheral.rssi))
                }
            }.frame(height: 300)
 
            Spacer()
 
            Text("STATUS")
                .font(.headline)
 
            // Status goes here
            if bleManager.isSwitchedOn {
                Text("Bluetooth is switched on")
                    .foregroundColor(.green)
            }
            else {
                Text("Bluetooth is NOT switched on")
                    .foregroundColor(.red)
            }
 
            Spacer()
 
            HStack {
                VStack (spacing: 10) {
                    Button(action: {
                        self.bleManager.startScanning()
                    }) {
                        Text("Start Scanning")
                    }
                    Button(action: {
                        self.bleManager.stopScanning()
                    }) {
                        Text("Stop Scanning")
                    }
                }.padding()
 
                Spacer()
 
                VStack (spacing: 10) {
                    Button(action: {
                        print("Start Advertising")
                    }) {
                        Text("Start Advertising")
                    }
                    Button(action: {
                        print("Stop Advertising")
                    }) {
                        Text("Stop Advertising")
                    }
                }.padding()
            }
            Spacer()
        }
    }
}*/
