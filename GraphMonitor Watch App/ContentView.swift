//
//  ContentView.swift
//  GraphMonitor Watch App
//
//  Created by shirane kaoru on 2023/07/26.
//

import SwiftUI
import WatchConnectivity
import Foundation
import CoreMotion
import Combine

struct ContentView: View {
    
    @ObservedObject var connector = PhoneConnector()
    
    @ObservedObject var sensor = MotionSensor()
    var body: some View {
        VStack {
            
            
            if sensor.isStarted{
                connector.send(accx:sensor.acceX,accy:sensor.acceY,accz:sensor.acceZ,rotx:sensor.rotX,roty:sensor.rotY,rotz:sensor.rotZ)
            }
            
           
            Button(action: {
                
                if sensor.isStarted{
                    sensor.stop()
                }else{
                    sensor.start()
                }
                
            
                
            }){
                sensor.isStarted ? Text("Sending..."):Text("START")
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

class PhoneConnector: NSObject, ObservableObject, WCSessionDelegate {
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("activationDidCompleteWith state= \(activationState.rawValue)")
    }
    
    
    
    func send(accx :String,accy :String,accz : String,rotx: String, roty: String, rotz: String) -> Text{
        if WCSession.default.isReachable {
            
            
            WCSession.default.sendMessage(["ACCEX": accx,"ACCEY": accy,"ACCEZ": accz,"ROTX": rotx,"ROTY":roty,"ROTZ":rotz], replyHandler: nil) {
                error in
                print(error)
            }
        }
        return Text("")
    }
}

class MotionSensor: NSObject, ObservableObject{
    let motionManager = CMMotionManager()
    
    @Published var isStarted = false
    
    @Published var acceX = "0.0"
    @Published var acceY = "0.0"
    @Published var acceZ = "0.0"
    
    @Published var rotX = "0.0"
    @Published var rotY = "0.0"
    @Published var rotZ = "0.0"
    
    @Published var timestamp = "0.0"
    
    func start(){
        if motionManager.isDeviceMotionAvailable{
            motionManager.deviceMotionUpdateInterval = 1/50
            motionManager.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler: {(motion:CMDeviceMotion?, error:Error?) in self.updateMotionData(deviceMotion: motion!)})
            
        }
        
        isStarted = true
    }
    
    func stop(){
        isStarted = false
        motionManager.stopDeviceMotionUpdates()
    }
    
    private func updateMotionData(deviceMotion:CMDeviceMotion){
        acceX = String(deviceMotion.userAcceleration.x)
        acceY = String(deviceMotion.userAcceleration.y)
        acceZ = String(deviceMotion.userAcceleration.z)
        rotX = String(deviceMotion.rotationRate.x)
        rotY = String(deviceMotion.rotationRate.y)
        rotZ = String(deviceMotion.rotationRate.z)
        timestamp = String(deviceMotion.timestamp)
    }
}

