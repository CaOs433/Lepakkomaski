//
//  ContentView.swift
//  Lepakkomaski-v1 WatchKit Extension
//
//  Created by Oskari Saarinen on 8.12.2020.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject var ble = BLEClass()
    
    @State private var distance = -1
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        /*ScrollView {
            /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Content@*/Text("Placeholder")/*@END_MENU_TOKEN@*/
        }
        VStack (spacing: 10)*/ScrollView {
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
            
            Text((ble.distance >= 0 && ble.distance <= 400) ? "Distance: \(m(ble.distance))" : "Distance: ? (\(ble.distance))").padding()
            
            Button(action: {
                ble.updateDistance()
            }) { Text("Read") }
            
            Button(action: {
                ble.reConnect()
            }) { Text("Re connect") }
            
            Button(action: { haptic(wkhType: .failure) }) {
                Text("Haptic")
            }.padding()
            
        }.onReceive(timer) { input in
            ble.updateDistance()
            if ble.distance < 100 {
                haptic(wkhType: .failure)
            }
        }.padding()//.onAppear(perform: startBT)
        
        /*VStack(alignment: .leading) {
            Text("Hello, World!")//.padding()
            Button(action: { haptic(wkhType: .failure) }) {
                Text("Haptic")
            }.padding()
            
        }.padding().frame(maxWidth: .infinity, maxHeight: .infinity, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/).background(Image("bg1").resizable(resizingMode: .tile)).foregroundColor(.black)
            .disabled(false)//.frame(maxWidth: 280, maxHeight: .infinity)//add ? Color.orange : Color.purple)//.frame(width: 280, height: 360, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
        */
        
    }
    
    private func haptic(wkhType: WKHapticType) {
        WKInterfaceDevice.current().play(wkhType)
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
