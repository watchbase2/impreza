//
//  ViewController.swift
//  SpeedMeter
//
//  Created by HIdeji Kitamura on 2020/11/15.
//

import UIKit
import CoreBluetooth


class ViewController: UIViewController, CBPeripheralDelegate, CBCentralManagerDelegate  {

    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var responceLabel: UILabel!
    @IBOutlet weak var statusOBD2: UILabel!
    @IBOutlet weak var statusPole: UILabel!
    @IBOutlet weak var unitLabel: UILabel!
    @IBOutlet weak var fuelLabel: UILabel!
    @IBOutlet weak var batteryViewBack: UIView!
    @IBOutlet weak var batteryLabel: UILabel!
    @IBOutlet weak var fuelViewBack: UIView!
    
    
    enum DisplayMode: Int {
        case DISTANCE_MODE = 0
        case SPEED_MODE = 1
    }
    
    var batteryView:UIView!
    var fuelView:UIView!
    var displayMode = DisplayMode.SPEED_MODE    // POLEと接続できたら、DISTANCE_MODEとなり、距離を表示させる。切断された SPEED_MODE になる
    
    var revoBar:[UIImageView] = []
    
    var centralManager: CBCentralManager!
    var isConnected = false
    
    // OBD2 BLE Device
    var serviceUUID_OBD2 : CBUUID!
    var charcteristicUUID_OBD2: CBUUID!
    var peripheral_OBD2: CBPeripheral?
    var charcteristic_OBD2: CBCharacteristic?
    
    // Sernsor Pole server
    var serviceUUID_POLE : CBUUID!
    var charcteristicUUID_POLE: CBUUID!
    var peripheral_POLE: CBPeripheral?
    var charcteristic_POLE: CBCharacteristic?

    var gotFuel = true   // 起動直後で、バッテーリーと燃料残量を測定するモード、その後、エンジン回転とスピードを継続測定する
    var gotBattery = false
    
    var timer: Timer?
    
    let distanceRed:Int = 50    // 近づきすぎ
    let revMax:Int = 6000   //
    let revRed:Int = 5000   // エンジン回転のレッドゾーン
    let revYellow:Int = 4000   // エンジン回転のイエローゾーン
    let divide:Int = 50     // エンジン回転用のバーの分割数
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.flipX()  // 最初から反転させておく
        responceLabel.isHidden = true
        
        speedLabel.text = "0"
        createBar()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        setup()
        
        auto()  // 連続的にデータを取得する
        
        //displayData("41 0D 2")
        //displayData("5\r")
        
        //displayData("12.5V\r")
        //drawBattery(11.8)
        //drawFuel(55.0)  // 実際には冷却水温度
        drawRev(2200)
        
    }
    
    let CMD_Battery = "ATRV\r"      // バッテリー電圧
    let CMD_Speed = "010D\r"        // 車速
    let CMD_Revo = "010C\r"         // エンジン回転
    let CMD_WaterTemp = "0105\r"    // 冷却水温度
    let CMD_Boost = "010B\r"        //　ブースト圧
    let CMD_Throttle = "0111\r"     // スロットルポジション
    let CMD_Fuel = "012F\r"         // 燃料
    
    
    // 連続してコマンドを送信する
    @IBAction func auto() {
        var batteryCounter = 0
        let SUB_FREQUENCY = 60      // バッテリーを読み取る周期
        
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { _ in
            
            if let peripheral = self.peripheral_POLE {
                if let characteristic = self.charcteristic_POLE {
                    
                    peripheral.readValue(for: characteristic)
                    self.statusPole.backgroundColor = .green
                }
            }
            
            if let peripheral = self.peripheral_OBD2 {
                
                if self.gotFuel && self.gotBattery {
                    batteryCounter -= 1
                    self.statusOBD2.backgroundColor = .green     // バッテリー電圧のチェックが済んだら グリーンにする
                }else{
                    
                    self.statusOBD2.backgroundColor = .yellow
                }
                
                if let characteristic = self.charcteristic_OBD2 {
                    
                    if batteryCounter > 0  {
                        
                        let cmdRev = self.CMD_Revo.data(using: String.Encoding.utf8, allowLossyConversion:true)!
                        let cmdSpeed = self.CMD_Speed.data(using: String.Encoding.utf8, allowLossyConversion:true)!
              
                        peripheral.writeValue(cmdRev, for: characteristic, type: .withResponse)
                        peripheral.writeValue(cmdSpeed, for: characteristic, type: .withResponse)
                        
                    }else{
                        batteryCounter = SUB_FREQUENCY
                        
                        let cmdBatt = self.CMD_Battery.data(using: String.Encoding.utf8, allowLossyConversion:true)!
                        let cmdFuel = self.CMD_Fuel.data(using: String.Encoding.utf8, allowLossyConversion:true)!
              
                        peripheral.writeValue(cmdBatt, for: characteristic, type: .withResponse)
                        peripheral.writeValue(cmdFuel, for: characteristic, type: .withResponse)

                    }
                }
            }
        })
    
    }
    
    
    func createBar() {
        let height:Double = Double(self.view.bounds.height)
        let gap:Double = 24     // 上下のギャップ　（文字の高さの半分は開けておく必要がある）
        
        let step:Double = (height  - gap) / Double(divide)
        
        for pos in 0 ..< divide {
            let y = height - gap - step * Double(pos) + 10
            let imgView = UIImageView(frame: CGRect(x: 30, y: y, width: 70, height: step - 2))
            imgView.backgroundColor = UIColor(hex:"92FFFF", alpha: 0.2)
            self.view.addSubview(imgView)
            revoBar.append(imgView)
        }
        
        var speed = 0
        let revStep:Double = (height  - gap) / Double(revMax)
        while speed <= revMax {
            let y = height - gap - revStep * Double(speed)
            let labelView = UILabel(frame: CGRect(x: 0, y: y, width: 25, height: 24))
            labelView.text = String(speed/1000)
            labelView.font = UIFont.systemFont(ofSize: 32, weight: .heavy)
            labelView.textColor = UIColor(red: 0xFF/255, green: 0xB4/255, blue: 0x24/255, alpha: 0.8)
            self.view.addSubview(labelView)
            speed += 1000
        }
        

        var frame = batteryViewBack.frame
        frame.size.width = frame.size.width
        frame.size.height = frame.size.height
        frame.origin.x = frame.origin.x
        frame.origin.y = frame.origin.y
        batteryView = UIView(frame: frame)
        self.view.addSubview(batteryView)
        //
        frame = fuelViewBack.frame
        frame.size.width = frame.size.width
        frame.size.height = frame.size.height
        frame.origin.x = frame.origin.x
        frame.origin.y = frame.origin.y
        fuelView = UIView(frame: frame)
        self.view.addSubview(fuelView)
    }
    
    func drawRev(_ value:Int) {
        
        let div = revoBar.count
        let divSpeed = revMax / div
        let yellowStep = revYellow / divSpeed
        let redStep = revRed / divSpeed
        let step = value / divSpeed
        
        for pos in 0 ..< div {
            let imgView = revoBar[pos]
            
            if pos < step {
                if pos > redStep {
                    imgView.backgroundColor = .red
                    
                }else if pos > yellowStep {
                    imgView.backgroundColor = .yellow
                    
                }else{
                    imgView.backgroundColor = UIColor(hex: "83f64d")
                }
            }else{
                imgView.backgroundColor = UIColor(hex:"92FFFF", alpha: 0.2)
                
            }
        }
    }
    
    func drawBattery(_ value:Double) {
        
        batteryLabel.text = String(value)
        
        let min = 11.0
        let max = 13.0
        
        var newValue = value
        if newValue > 14.0 { newValue = 14.0 }
        var frame = batteryView.frame
        
        let width:CGFloat = CGFloat((newValue - min) / (max - min) * Double(frame.size.width))
        frame.size.width = width
        batteryView.frame = frame
        
        if value < 12.0 {
            batteryView.backgroundColor = UIColor.red
        }else if value < 12.3 {
            batteryView.backgroundColor = UIColor.yellow
        }else{
            batteryView.backgroundColor = UIColor(hex: "83f64d")
        }
    }
  
    func drawFuel(_ value:Double) {
        
        fuelLabel.text = String(value)
        
        let min = 0.0
        let max = 100.0
        
        var frame = fuelView.frame
        
        let width:CGFloat = CGFloat((value - min) / (max - min) * Double(frame.size.width))
        frame.size.width = width
        fuelView.frame = frame
        
        if value < 10.0 {
            fuelView.backgroundColor = UIColor.red
        }else if value < 50.0 {
            fuelView.backgroundColor = UIColor.yellow
        }else{
            fuelView.backgroundColor = UIColor(hex: "83f64d")
        }
    }
    
    /// セントラルマネージャー、UUIDの初期化
    private func setup() {
        
        centralManager = CBCentralManager(delegate: self, queue: nil)

        // OBD2 device
        serviceUUID_OBD2 = CBUUID(string: "ffe0")
        charcteristicUUID_OBD2 = CBUUID(string: "ffe1")
        
        // SensorPole server
        serviceUUID_POLE = CBUUID(string: "f5fec56f-30b4-4816-9641-bfc409e0f5d6")
        charcteristicUUID_POLE = CBUUID(string: "d0767248-9078-4b5f-9b71-240ea4ae2469")
        
    }
    
    @IBAction func sendValue(_ sender: Any) {
        
        responceLabel.isHidden = !responceLabel.isHidden
        
        return
        
        let alert: UIAlertController = UIAlertController(title: "コマンドを入力してください", message: "", preferredStyle:  UIAlertController.Style.alert)
        alert.addTextField(configurationHandler: {(textField:UITextField!) -> Void in
                    textField.text = ""
    
        })
        
        let defaultAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler:{
            // ボタンが押された時の処理を書く（クロージャ実装）
            (action: UIAlertAction!) -> Void in
            
            
            let cmd = alert.textFields?.first!.text
            let data = cmd!.data(using: String.Encoding.utf8, allowLossyConversion:true)!
            
            if let periferal = self.peripheral_OBD2 {
                if let characteristic = self.charcteristic_OBD2 {
                    periferal.writeValue(data, for: characteristic, type: .withResponse)
                }
            }
        })
        
        alert.addAction(defaultAction)
        self.present(alert, animated: true, completion: nil)

    }
    
    @IBAction func changeCmd(_ sender: UIButton) {
        
      //  if !isConnected { return }
        
        let sel = sender.tag
        var cmd = "ATZ\r"
        
        switch sel {
        case 1:
            cmd = "010C\r"       // エンジン回転
        case 2:
            cmd = "010D\r"       // 車速
        case 3:
            cmd = "010B\r"       // ブースト
        case 4:
            cmd = "ATRV\r"       // バッテリ電圧
        case 5:
            cmd = "01A4\r"       // シフトポジション  -->　サポートされていなかった
        case 6:
            cmd = "012F\r"       // 燃料レベル
        default:
            cmd = ""
        }
        
        if cmd == "" { return }
        
        let data = cmd.data(using: String.Encoding.utf8, allowLossyConversion:true)!
        if let periferal = self.peripheral_OBD2 {
            if let characteristic = self.charcteristic_OBD2 {
                periferal.writeValue(data, for: characteristic, type: .withResponse)
            }
        }
        
       // self.peripheral.readValue(for: self.charcteristic_read)

    }
    
    
    @IBAction func flipView(_ sender: UIButton) {
        self.view.flipX()
    }


//MARK : - CBCentralManagerDelegate
//extension ViewController: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {

        switch central.state {

        //電源ONを待って、スキャンする
        case CBManagerState.poweredOn:
            let services: [CBUUID] = [serviceUUID_OBD2, serviceUUID_POLE]
            centralManager?.scanForPeripherals(withServices: services,
                                               options: nil)
        default:
            break
        }
    }

    /// ペリフェラルを発見すると呼ばれる
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        
        print("find the device:\(peripheral.name)")     // OBDBLE ?
        
        if peripheral.name == "OBDBLE" {
            self.peripheral_OBD2 = peripheral

        }else if peripheral.name == "POLE" {
            self.peripheral_POLE = peripheral
            displayMode = .DISTANCE_MODE
        }
        responceLabel.text = peripheral.name
        
        if self.peripheral_OBD2 != nil && self.peripheral_POLE != nil {
            centralManager?.stopScan()
        }
        
        //接続開始
        central.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        if peripheral.name == "OBDBLE" {
            self.statusOBD2.backgroundColor = .darkGray
            peripheral_OBD2 = nil
            charcteristic_OBD2 = nil
            centralManager?.scanForPeripherals(withServices: [serviceUUID_OBD2], options: nil)
            
            drawRev(0)
            speedLabel.text = "0"
            UIApplication.shared.isIdleTimerDisabled = false     // スリープタイマーをオンにする
            
        }else if peripheral.name == "POLE" {
            self.statusPole.backgroundColor = .darkGray
            displayMode = .SPEED_MODE
            peripheral_POLE = nil
            charcteristic_POLE = nil
            speedLabel.text = "0"
            centralManager?.scanForPeripherals(withServices: [serviceUUID_POLE], options: nil)
        }
    }
    
    /// Periferalに接続されると呼ばれる --> サービスを探す
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("connected")
        responceLabel.text = "Connected"
        peripheral.delegate = self
        
        if peripheral.name == "OBDBLE" {      // サービスは一つしか持っていないことが前提
            peripheral.discoverServices([serviceUUID_OBD2])
            
        }else if peripheral.name == "POLE" {
            peripheral.discoverServices([serviceUUID_POLE])
        }
    }

    /// サービス発見時に呼ばれる
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverServices error: Error?) {

        if error != nil {
            print(error.debugDescription)
            return
        }
        print("find serivices")
        responceLabel.text = "Service"
        //キャリアクタリスティク探索開始
        
        if peripheral.name == "OBDBLE" {
            peripheral.discoverCharacteristics([charcteristicUUID_OBD2], for: (peripheral.services?.first)!)
            
        }else if peripheral.name == "POLE" {
            peripheral.discoverCharacteristics([charcteristicUUID_POLE], for: (peripheral.services?.first)!)
        }
    }

    /// キャラクタリスティク発見時に呼ばれる
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {

        if error != nil {
            print(error.debugDescription)
            return
        }

        for characteristic in service.characteristics! {
            
            if characteristic.uuid.isEqual(charcteristicUUID_OBD2) {
                self.charcteristic_OBD2 = characteristic
                print("charcteristicUUID_OBD2 を発見")
                responceLabel.text = "Character"
                
                isConnected = true
                                
                // 通知をリクエスト
                peripheral.setNotifyValue(true, for: charcteristic_OBD2!)
                
            }else if characteristic.uuid.isEqual(charcteristicUUID_POLE) {
                self.charcteristic_POLE = characteristic
                print("charcteristicUUID_POLE を発見")
                responceLabel.text = "Character"
                // 通知をリクエスト
                peripheral.setNotifyValue(true, for: charcteristic_POLE!)
                
            }
            
            if charcteristic_OBD2 != nil && charcteristic_POLE != nil {
                
            }
        }
        
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        if let error = error {
            print("Write失敗...error: \(error)")
            return
        }
    }
    
    var buf_odb2:String = ""
    
    /// データ更新時に呼ばれる
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {

        if error != nil {
            print(error.debugDescription)
            return
        }
        
        if characteristic.uuid.isEqual(charcteristicUUID_POLE) {
            
            if characteristic.uuid.isEqual(charcteristicUUID_POLE) {
                print("charcteristicUUID_POLEから受信")
                
                if displayMode == .DISTANCE_MODE {     // センサーポールとの距離表示
                    displayDistance(characteristic)
                }
            }
            
        }else
        if characteristic.uuid.isEqual(charcteristicUUID_OBD2) {
            print("charcteristicUUID_OBD2から受信")

            if let data = characteristic.value {
                let str = String(data: data, encoding:String.Encoding.utf8) ?? ""
                responceLabel.text = str
         
                displayData(str)

            }
        }
    }
    
    func displayDistance(_ characteristic: CBCharacteristic?) {
        let data = characteristic!.value!
        let distance = Int(data[0]) + Int(data[1]) * 256
        
        if distance == 999 {
            // ポールとの通信ができていない
            displayMode = .SPEED_MODE
            speedLabel.textColor = UIColor(hex: "92FFFF")
            return
        }
        speedLabel.text = String(distance)
        if distance < distanceRed {
            speedLabel.textColor = .red
        }else{
            speedLabel.textColor = UIColor(hex: "92FFFF")
        }
        unitLabel.text = "cm"
    }
    
    enum dataType:Int {
        case NONE = 0
        case BATTERY = 1
        case BOOST = 2
        case REV = 3
        case SPEED = 4
        case FUEL = 5
        case ERROR = 99
    }
    
    var type:dataType = .NONE
    

    func displayData(_ inStr:String) {
    
        Log.writeWithTimestamp("\(inStr)\n")
        
        var displayStr = ""
        
        if inStr.suffix(1) == "\r" {
            displayStr = buf_odb2 + inStr
            buf_odb2 = ""
        }else{
            buf_odb2 = inStr
            return
        }
        
        let strArray = displayStr.split(separator: "\r")
    
        for str in strArray {
  
            let subArray = str.split(separator: " ")
            if subArray.count == 0 { continue }
            
            if type == .BATTERY {
                let revStr = String(strArray[0]).replacingOccurrences(of: "V", with: "")
                
                drawBattery(Double(revStr) ?? 0.0)
                gotBattery = true
                
                type = .NONE
            }
            else
            if type == .NONE {
                
                if subArray[0] == "ATRV" {
                    
                    if subArray.count > 1 {
                        // RVの後ろに値が付いている
                        let revStr = String(strArray[1]).replacingOccurrences(of: "V", with: "")
                        
                        drawBattery(Double(revStr) ?? 0.0)
                        gotBattery = true
                        
                        type = .NONE
                    }else{
                        type = .BATTERY
                    }
                    
                }else if subArray[0] == "41" && subArray.count > 2 {
                    
                    UIApplication.shared.isIdleTimerDisabled = true     // エンジンがかかっているのでスリープさせない
                    
                    switch subArray[1] {
                    case "0B":
                        type = .NONE
                        let value = (Int(subArray[2], radix: 16) ?? 0) / 100
                        
                    case "0C":
                        type = .NONE
                        if subArray.count < 4 { break }
                        
                        let value = (Int(subArray[2] + subArray[3], radix: 16) ?? 0 ) / 4
                        
                        drawRev(value)
                        
                    case "0D":
                        if displayMode == .SPEED_MODE {
                            type = .NONE
                            unitLabel.text = "km/h"
                            let value = Int(subArray[2] , radix: 16) ?? 0
                            speedLabel.text = String(value)
                        }
                    case "05":
                        type = .NONE
                        let value = Int(subArray[2] , radix: 16) ?? 0
                        let fuel = Int(Double(value) * 100.0 / 255.0)
                        drawFuel(Double(fuel) )
                        gotFuel = true
                    
                    case "2F":
                        type = .NONE
                        let value = Int(subArray[2] , radix: 16)!
                        let fuel = Int(Double(value) * 100.0 / 255.0)
                        drawFuel(Double(fuel) )
                        gotFuel = true
                    
                    default:
                        break
                    }
                    
                }else if subArray[0] == "CAN" {
                    // OBDの電源は入っているが、エンジンは掛かっていない状態
                    
                    type = .ERROR
                    gotBattery = false
                    //gotFuel = false
                    UIApplication.shared.isIdleTimerDisabled = false     // スリープタイマーをオンにする

                    /*
                    let alert: UIAlertController = UIAlertController(title: "CAN ERROR", message: "", preferredStyle:  UIAlertController.Style.alert)
                    
                    let defaultAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler:{
                        // ボタンが押された時の処理を書く（クロージャ実装）
                        (action: UIAlertAction!) -> Void in
                        
                    })
                    alert.addAction(defaultAction)
                    self.present(alert, animated: true, completion: nil)
                     */
                }
                
            }else if subArray[0] == ">" {
                type = .NONE
                
            }
            
        }
        
    }
}


extension UIView {

    /// Flip view horizontally.
    func flipX() {
        transform = CGAffineTransform(scaleX: -transform.a, y: transform.d)
    }

    /// Flip view vertically.
    func flipY() {
        transform = CGAffineTransform(scaleX: transform.a, y: -transform.d)
    }
 }

class Log {
    private static let file = "log.csv"

    static func write(_ log: String) {
        writeToFile(file: file, text: log)
    }
    
    static func writeWithTimestamp(_ log: String) {
        let dataWithLog = Util.formattedTime(Date())
        writeToFile(file: file, text: dataWithLog)
    }
    
    private static func writeToFile(file: String, text: String) {
        guard let documentPath =
            FileManager.default.urls(for: .documentDirectory,
                                     in: .userDomainMask).first else { return }

        let path = documentPath.appendingPathComponent(file)
        var newText = text.replacingOccurrences(of: " ", with: "_")
        newText = newText.replacingOccurrences(of: "\r", with: "¥r")
        _ = appendText(fileURL: path, text: newText)
    }

    private static func appendText(fileURL: URL, text: String) -> Bool {
        guard let stream = OutputStream(url: fileURL, append: true) else { return false }
        stream.open()

        defer { stream.close() }

        guard let data = text.data(using: .utf8) else { return false }

        let result = data.withUnsafeBytes {
            stream.write($0, maxLength: data.count)
        }

        return (result > 0)
    }
}

extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        let v = Int("000000" + hex, radix: 16) ?? 0
        let r = CGFloat(v / Int(powf(256, 2)) % 256) / 255
        let g = CGFloat(v / Int(powf(256, 1)) % 256) / 255
        let b = CGFloat(v / Int(powf(256, 0)) % 256) / 255
        self.init(red: r, green: g, blue: b, alpha: min(max(alpha, 0), 1))
    }
}
