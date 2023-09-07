//
//  ContentView.swift
//  GraphMonitor
//
//  Created by shirane kaoru on 2023/07/26.
//

import SwiftUI
import Charts
import CoreMotion
import Foundation
import WatchConnectivity

struct PointsData: Identifiable {
    // 点群データの構造体
    var xValue: Int
    var yValue: Double
    var id = UUID()
}


 
struct ContentView: View {
    
    // データを定義
    @State private var datax: [PointsData] = []
    @State private var datay: [PointsData] = []
    @State private var dataz: [PointsData] = []
    @State private var data_acce: [PointsData] = []
    @State private var peak_idx: [PointsData] = []
    @State private var randArray: [Float] = []
    @State private var x: [Float] = []
    @State private var y: [Float] = []
    @State private var cnt: Int = 0
    @State private var flag: Bool = false
//    @State private var sensor = MotionSensor()
    @ObservedObject private var connector = WatchConnector()
    @State var currentDate = Date.now
    let timer = Timer.publish(every: 1/50, on: .main, in: .common).autoconnect()
    
    
    func wavePoints(dt: Float, length: Float) -> (xArray: [Float], yArray: [Float]){
        // 散布図にプロットするデータを演算する関数
        
        // 時間刻みdtと時間長lengthからx軸を作成
        let xArray = Array(stride(from: 0.0, to: length, by: dt))
        
        // ランダム配列をx軸のデータ数分計算
        randArray = (0..<xArray.count).map {
            _ in Float.random(in: 0..<1)
        }
        
        return (xArray, randArray)
    }
    
    func sinPoints(cnt:Int) -> Float{
        let pi = Double.pi
        
        return Float(sin(pi*Double(cnt)/4))
    }
    
    var body: some View {
        // UI
        
        VStack{
            Chart {
                // データ構造からx, y値を取得して散布図プロット
                
                if !data_acce.isEmpty {
                    ForEach(peak_idx){ shape in
                        PointMark(
                            x: .value("x",shape.xValue),
                            y: .value("y",shape.yValue)
                        )
                    }
                    
                }
//                ForEach(datax) { shape in
//                    // 散布図をプロット
//
//                    LineMark(
//                        x: .value("x", shape.xValue),
//                        y: .value("y", shape.yValue)
//                    )
//                    .foregroundStyle(by: .value("Category","accex"))
//
//
//                }
//
//                ForEach(datay) { shape in
//                    // 散布図をプロット
//
//                    LineMark(
//                        x: .value("x", shape.xValue),
//                        y: .value("y", shape.yValue)
//                    )
//                    .foregroundStyle(by: .value("Category","accey"))
//
//
//                }
//
//                ForEach(dataz) { shape in
//                    // 散布図をプロット
//
//                    LineMark(
//                        x: .value("x", shape.xValue),
//                        y: .value("y", shape.yValue)
//                    )
//                    .foregroundStyle(by: .value("Category","accez"))
//
//
//                }
                
                ForEach(data_acce) { shape in
                    // 散布図をプロット

                    LineMark(
                        x: .value("x", shape.xValue),
                        y: .value("y", shape.yValue)
                    )
                    .foregroundStyle(by: .value("Category","acce"))


                }
                
                



            }
            .chartYScale(domain:-4.0 ... 4.0)
            .chartXScale(domain:0 ... 100)
            .onReceive(timer,perform:{_ in
                    
                let accexs = connector.datax
                let acceys = connector.datay
                let accezs = connector.dataz
//                datax.removeAll()
//                datay.removeAll()
//                dataz.removeAll()
                data_acce.removeAll()
                peak_idx.removeAll()

//                for (index,xdata) in connector.datax.enumerated(){
//                    datax.append(PointsData(xValue: index, yValue: xdata))
//                }
//
//                for (index,ydata) in connector.datay.enumerated(){
//                    datay.append(PointsData(xValue: index, yValue: ydata))
//                }
//
//                for (index,zdata) in connector.dataz.enumerated(){
//                    dataz.append(PointsData(xValue: index, yValue: zdata))
//                }
                for  peak in connector.peak{
                    peak_idx.append(PointsData(xValue: peak, yValue: connector.data[peak]))
                }
                for (index, data) in connector.data.enumerated(){
                    data_acce.append(PointsData(xValue: index, yValue: data))
                    
                }
//                if !accexs.isEmpty{
//
//                    for index in 0...accexs.count-1{
//                        data_acce.append(PointsData(xValue: index, yValue: sqrt(pow(accezs[index],2)+pow(acceys[index],2)+pow(accezs[index],2))))
//                    }
//
//
//                }
                
            })
            
            
            //connector.data_print()
            
            
        }
    }
}
 
//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}




class WatchConnector: NSObject,ObservableObject,WCSessionDelegate{
    
    @Published var acceX = "0.0"
    @Published var acceY = "0.0"
    @Published var acceZ = "0.0"
    
    @Published var rotX = "0.0"
    @Published var rotY = "0.0"
    @Published var rotZ = "0.0"
    @Published var data: [Double] = []
    @Published var datax: [Double] = []
    @Published var datay: [Double] = []
    @Published var dataz: [Double] = []
    @Published var cnt = 0
    @Published var peak: [Int] = []
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        print("activationDidCompleteWith state= \(activationState.rawValue)")
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("sessionDidBecomeInactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("sessionDidDeactivate")
    }
    
    private func argmax(data:[Double],first:Int,last:Int) -> Int{
        var max:Double = 0.0
        var maxi = 0
        for i in first..<last{
            if max < data[i]{
                max = data[i]
                maxi = i
            }
        }
        return maxi
        
    }
    
    private func npsum(data:[Double],first:Int,last:Int) -> Double{
        var sum:Double = 0.0
        
        for i in first..<last{
            sum+=data[i]
        }
        
        return sum
    }
    
    func detect_peak(data: [Double],num_train:Int,num_guard:Int,rate_fate:Double) -> [Int]{
        let num_cells = data.count
        let num_train_half = round(Double(num_train)/2)
        let num_guard_half = round(Double(num_guard)/2)
        let num_side = Int(num_train_half + num_guard_half)
        
        let alpha = Double(num_train) * (pow(rate_fate,Double(-1/Double(num_train)))-1)
        
        var peak_idx:[Int] = []
        
        for i in num_side..<(num_cells - num_side) {
              
            if i != self.argmax(data:data, first:i-num_side,last:i+num_side){
                continue
            }
            
            let sum1 = npsum(data: data, first: i-num_side, last: i+num_side+1)
            let sum2 = npsum(data: data, first: i-Int(num_guard_half), last: i+Int(num_guard_half)+1)
            
            let p_noise = (sum1 - sum2) / Double(num_train)
            
            let threshold = alpha * p_noise
            
            if Double(data[i]) > threshold{
                peak_idx.append(i)
            }
        }
        return peak_idx
    }
    
    func detect_peak_ver2(data: [Double]){
        
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
//        print("didReceiveMessage: \(message)")
        
        
        DispatchQueue.main.async {
            //アプリに表示するために値を取得
            
            self.acceX = message["ACCEX"] as! String
            self.acceY = message["ACCEY"] as! String
            self.acceZ = message["ACCEZ"] as! String
            self.rotX = message["ROTX"] as! String
            self.rotY = message["ROTY"] as! String
            self.rotZ = message["ROTZ"] as! String
            
            
            
            
            if self.cnt==100{
                self.datax.removeFirst()
                self.datay.removeFirst()
                self.dataz.removeFirst()
                self.data.removeFirst()
                self.datax.append(Double(self.acceX)!)
                self.datay.append(Double(self.acceY)!)
                self.dataz.append(Double(self.acceZ)!)
                
                self.data.append(sqrt(pow(Double(self.acceX)!,2)+pow(Double(self.acceY)!,2)+pow(Double(self.acceZ)!,2)))
                
                self.peak = self.detect_peak(data: self.data, num_train: 30, num_guard: 10, rate_fate: 1e-3)
                
            }else{
                self.cnt+=1
                self.datax.append(Double(self.acceX)!)
                self.datay.append(Double(self.acceY)!)
                self.dataz.append(Double(self.acceZ)!)
                self.data.append(sqrt(pow(Double(self.acceX)!,2)+pow(Double(self.acceY)!,2)+pow(Double(self.acceZ)!,2)))
            }
            
            
            
            
//            print(type(of:message["ACCEX"]))
            
        
            
//            self.count = message["WA"] as! Int
            
            
        }
    }
    
    //iPhoneに出力させる関数
    func data_print()->Text{
//        addfile(datas:self.receivedMessage)
        return Text("ACCEX:\(self.acceX)\nACCEY:\(self.acceY)\nACCEZ:\(self.acceZ)\nROTX:\(self.rotX)\nROTY:\(self.rotY)\nROTZ:\(self.rotZ)")
    }
}
