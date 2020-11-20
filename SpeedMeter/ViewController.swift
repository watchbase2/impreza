//
//  ViewController.swift
//  SpeedMeter
//
//  Created by HIdeji Kitamura on 2020/11/15.
//

import UIKit
import CoreBluetooth


class ViewController: UIViewController, CBPeripheralDelegate, CBCentralManagerDelegate  {

    
    @IBOutlet weak var speedBar: UIView!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var responceLabel: UILabel!
    @IBOutlet weak var statusOBD2: UILabel!
    @IBOutlet weak var statusPOLE: UILabel!
    @IBOutlet weak var unitLabel: UILabel!
    @IBOutlet weak var fuelLabel: UILabel!
    @IBOutlet weak var batteryViewBack: UIView!
    @IBOutlet weak var batteryLabel: UILabel!
    @IBOutlet weak var fuelViewBack: UIView!
    @IBOutlet weak var coolantViewBack: UIView!
    @IBOutlet weak var coolantLabel: UILabel!
    @IBOutlet weak var shiftPositionLabel: UILabel!
    
    
    enum DisplayMode: Int {
        case DISTANCE_MODE = 0
        case SPEED_MODE = 1
    }
    
    let Color_Syan = UIColor(hex:"92FFFF", alpha:1.0)
    let Color_SyanLabel = UIColor(hex:"92FFFF", alpha:0.6)
    let Color_DarkSyan = UIColor(hex:"92FFFF", alpha:0.2)
    let Color_Red = UIColor(hex:"FF0000", alpha:1.0)
    let Color_Yellow = UIColor(hex:"FFFB00", alpha:1.0)
    let Color_Orange = UIColor(hex:"FFB424", alpha:1.0)
    let Color_Green = UIColor(hex:"7BF997", alpha:1.0)
    let Color_Blue = UIColor(hex:"006FC3", alpha:1.0)
    

    
    var batteryView:UIView!
    var fuelView:UIView!
    var coolantView:UIView!

    var displayMode = DisplayMode.SPEED_MODE    // POLEと接続できたら、DISTANCE_MODEとなり、距離を表示させる。切断された SPEED_MODE になる
    
    var revoBar:[UIImageView] = []
    var revValue:Int = 0        // ログ記録用
    var speedValue:Int = 0
    
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
        statusOBD2.backgroundColor = Color_DarkSyan
        statusPOLE.backgroundColor = Color_DarkSyan
        
        speedLabel.text = "0"
        UIApplication.shared.isIdleTimerDisabled = false
        
        createBar()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        setup()
        
        auto()  // 連続的にデータを取得する
        

        /*
        //shiftPositionLabel.text = "4"
        displayData("41 0D 28\r")       // 車速   40km/h
        displayData("41 0C 10 AC\r")    // エンジン回転
        displayData("41 05 90\r")       // クーラント
        displayData("ATRV\r")           // バッテリー
        displayData("12.5V\r")
      //  drawBattery(12.0)
        drawFuel(55.0)
        //drawRev(4000)
       */
    }
    
    let CMD_Battery = "ATRV\r"      // バッテリー電圧
    let CMD_Speed = "010D\r"        // 車速
    let CMD_Revo = "010C\r"         // エンジン回転
    let CMD_Coolant = "0105\r"    // 冷却水温度
    let CMD_Boost = "010B\r"        //　ブースト圧
    let CMD_Throttle = "0111\r"     // スロットルポジション
    let CMD_Fuel = "012F\r"         // 燃料
    
    let gearRatio = [3.60, 2.155, 1.516, 1.092, 0.842, 0.6657, 0.556]
    let gearAdjust = 0.033
    
    
    // 連続してコマンドを送信する
    @IBAction func auto() {
        var batteryCounter = 0
        let FREQUENCY = 0.2
        let SUB_FREQUENCY = Int(1.0 / FREQUENCY * 10)     // バッテリーを読み取る周期 = 10秒になるように算出
        var logCounter = 0
        let LOG_FREQUENCY = Int(1.0 / FREQUENCY)           // ログの記録周期　＝ 1秒になるように算出
        
        var gearRange:[Double] = []
        gearRange.append( (gearRatio[0]))
        gearRange.append( (gearRatio[0] + gearRatio[1]) / 2.0 )
        gearRange.append( (gearRatio[1] + gearRatio[2]) / 2.0 )
        gearRange.append( (gearRatio[2] + gearRatio[3]) / 2.0 )
        gearRange.append( (gearRatio[3] + gearRatio[4]) / 2.0 )
        gearRange.append( (gearRatio[4] + gearRatio[5]) / 2.0 )
        gearRange.append( (gearRatio[5] + gearRatio[6]) / 2.0 )
            
        self.timer = Timer.scheduledTimer(withTimeInterval: FREQUENCY, repeats: true, block: { _ in
            
            logCounter += 1
            
            if logCounter > LOG_FREQUENCY {
               // Log.write("\(self.speedValue) , \(self.revValue)\n")
                logCounter = 0
            }
            
            if self.speedValue == 0 {
                self.shiftPositionLabel.text = "0"
            }else{
                let ratio = Double(self.revValue) / Double(self.speedValue) * self.gearAdjust
     
                for shift in 0..<7 {
                    if ratio > gearRange[shift] {
                        self.shiftPositionLabel.text = String(shift)  // Neutral を "N"と表示させようとしたが"n"と表示されるため採用せず、"0" を採用した。
                        break
                    }
                }
            }

            if let peripheral = self.peripheral_POLE {
                if let characteristic = self.charcteristic_POLE {
                    
                    peripheral.readValue(for: characteristic)
                    
                }
            }
            
            if let peripheral = self.peripheral_OBD2 {
                
                if self.gotFuel && self.gotBattery {
                    batteryCounter -= 1
                    self.statusOBD2.backgroundColor = self.Color_Green     // バッテリー電圧のチェックが済んだら グリーンにする
                }else{
                    
                    self.statusOBD2.backgroundColor = self.Color_Yellow
                }
                
                if let characteristic = self.charcteristic_OBD2 {
                    
                    if batteryCounter > 0  {
                        
                        let cmdRev = self.CMD_Revo.data(using: String.Encoding.utf8, allowLossyConversion:true)!
                        let cmdSpeed = self.CMD_Speed.data(using: String.Encoding.utf8, allowLossyConversion:true)!
              
                        peripheral.writeValue(cmdRev, for: characteristic, type: .withResponse)
                        peripheral.writeValue(cmdSpeed, for: characteristic, type: .withResponse)
                        
                    }else{
                        // SUB_FREQUENCYで定義されている回数分の1回の割合でバッテリー電圧と燃料残量を読み取る
                        batteryCounter = SUB_FREQUENCY
                        
                        let cmdBatt = self.CMD_Battery.data(using: String.Encoding.utf8, allowLossyConversion:true)!
                        let cmdFuel = self.CMD_Fuel.data(using: String.Encoding.utf8, allowLossyConversion:true)!
                        let cmdCoolant = self.CMD_Coolant.data(using: String.Encoding.utf8, allowLossyConversion:true)!
                        peripheral.writeValue(cmdBatt, for: characteristic, type: .withResponse)
                        peripheral.writeValue(cmdFuel, for: characteristic, type: .withResponse)
                        peripheral.writeValue(cmdCoolant, for: characteristic, type: .withResponse)

                    }
                }
            }
        })
    }
    
    
    func createBar() {
        let height:Double = Double(self.view.bounds.height)
        let gap:Double = 30    // 上下のギャップ　（文字の高さの半分は開けておく必要がある）
        
        let step:Double = (height  - gap) / Double(divide)
        
        // バーを描画
        for pos in 0 ..< divide {
            let y = height - gap - step * Double(pos) + 10
            let imgView = UIImageView(frame: CGRect(x: 32, y: y, width: 68, height: step - 2))
            imgView.backgroundColor = Color_DarkSyan
            self.view.addSubview(imgView)
            revoBar.append(imgView)
        }
        
        //　ラベルを描画
        var speed = 0
        let revStep:Double = (height  - gap) / Double(revMax)
        while speed <= revMax {
            let y = height - gap - revStep * Double(speed) + 4
            let labelView = UILabel(frame: CGRect(x: 0, y: y, width: 25, height: 24))
            labelView.text = String(speed/1000)
            labelView.font = UIFont.systemFont(ofSize: 32, weight: .heavy)
            labelView.textColor = Color_Syan
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
        //
        frame = coolantViewBack.frame
        frame.size.width = frame.size.width
        frame.size.height = frame.size.height
        frame.origin.x = frame.origin.x
        frame.origin.y = frame.origin.y
        coolantView = UIView(frame: frame)
        self.view.addSubview(coolantView)
    }
    
    func drawRev(_ value:Int) {
        
        let div = revoBar.count
        let divSpeed = revMax / div
        let yellowStep = revYellow / divSpeed
        let redStep = revRed / divSpeed
        let step = value / divSpeed
        
        var color = Color_Orange    //Color_Syan
        
        if step > redStep {
            color = Color_Red
        }else if step > yellowStep {
            color = Color_Yellow
        }
        for pos in 0 ..< div {
            let imgView = revoBar[pos]
            
            if pos < step {
                imgView.backgroundColor = color

            }else{
                imgView.backgroundColor = Color_DarkSyan
                
            }
        }
    }
    
    func drawBattery(_ value:Double) {
        
        batteryLabel.text = String(value)
        
        let min = 11.0
        let max = 13.0
        
        var newValue = value
        if newValue > max { newValue = max }
        if newValue < min { newValue = min }
        
        var frame = batteryViewBack.frame
        
        let width:CGFloat = CGFloat((newValue - min) / (max - min) * Double(frame.size.width))
        frame.size.width = width
        batteryView.frame = frame
        
        if value < 12.0 {
            batteryView.backgroundColor = Color_Red
        }else if value < 12.3 {
            batteryView.backgroundColor = Color_Yellow
        }else{
            batteryView.backgroundColor = Color_Green
        }
    }
  
    func drawFuel(_ value:Double) {
        
        fuelLabel.text = String(Int(value))
        
        let min = 0.0
        let max = 100.0
        
        var frame = fuelViewBack.frame
        
        let width:CGFloat = CGFloat((value - min) / (max - min) * Double(frame.size.width))
        frame.size.width = width
        fuelView.frame = frame
        
        if value < 10.0 {
            fuelView.backgroundColor = Color_Red
        }else if value < 30.0 {
            fuelView.backgroundColor = Color_Yellow
        }else{
            fuelView.backgroundColor = Color_Green
        }
    }
    
    func drawCoolant(_ value:Double) {
        
        coolantLabel.text = String(Int(value))
        
        let min = -40.0
        let max = 120.0
        
        var frame = coolantViewBack.frame
        
        let width:CGFloat = CGFloat((value - min) / (max - min) * Double(frame.size.width))
        frame.size.width = width
        coolantView.frame = frame
        
        if value > 100.0 {
            coolantView.backgroundColor = Color_Red
        }else if value > 90.0 {
            coolantView.backgroundColor = Color_Yellow
        }else{
            coolantView.backgroundColor = Color_Green
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
            self.statusOBD2.backgroundColor = Color_DarkSyan
            peripheral_OBD2 = nil
            charcteristic_OBD2 = nil
            centralManager?.scanForPeripherals(withServices: [serviceUUID_OBD2], options: nil)
            
            drawRev(0)
            speedLabel.text = "0"
            UIApplication.shared.isIdleTimerDisabled = false     // スリープタイマーをオンにする
            
        }else if peripheral.name == "POLE" {
            self.statusPOLE.backgroundColor = Color_DarkSyan
            if self.charcteristic_OBD2 == nil {
                speedLabel.textColor = Color_DarkSyan
                speedLabel.text = "---"
            }else{
                speedLabel.textColor = Color_Syan
            }
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
                
                displayDistance(characteristic)
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
        var distance = Int(data[0]) + Int(data[1]) * 256
        
        print("charcteristicUUID_POLEから受信: \(distance)")
        
        if distance == 999 {
            // コントローラと通信はできているがポールからデータを受け取れていない
            
            if displayMode == .DISTANCE_MODE {
                displayMode = .SPEED_MODE
                speedLabel.textColor = Color_DarkSyan
                self.statusPOLE.backgroundColor = Color_Yellow
            }
            return
        }
        
        if distance > 300 { distance = 333 }
        displayMode = .DISTANCE_MODE
        
        self.statusPOLE.backgroundColor = Color_Green
        speedLabel.text = String(distance)
        if distance < distanceRed {
            speedLabel.textColor = Color_Red
        }else{
            speedLabel.textColor = Color_Syan
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
        case COOLANT = 6
        case ERROR = 99
    }
    
    var type:dataType = .NONE
    
    /*
     OBD2からのレスポンスはコマンドの識別子に続いて値が返ってくる。
     例えば、バッテーリ電圧を得るために"ATRV"コマンドを送信した場合、
        "ATRV\r12.5V\r\r>"
     のように返ってくる。しかし、このようにまとまって返ってくるのではなく、
        "ATRV\r", "12.5V\r\r>"
     のように分割されて返ってくるケースがある。
     
     */
    
    func displayData(_ inStr:String) {
    
        Log.writeWithTimestamp("\(inStr)\n")
        
        var displayStr = ""
        
        if inStr.suffix(1) == "\r" || inStr.suffix(1) == ">" {
            // データも含めて返ってきたので表示する
            displayStr = buf_odb2 + inStr
            buf_odb2 = ""
        }else{
            //　コマンドは返ってきたが、値が含まれていないので次のデータを待つ
            buf_odb2 = inStr
            return
        }
        
        let strArray = displayStr.split(separator: "\r")
    
        for str in strArray {
  
            let subArray = str.split(separator: " ")
            if subArray.count == 0 { continue }
            
            if type == .BATTERY {
                let str = String(strArray[0]).replacingOccurrences(of: "V", with: "")
                let bat = Double(str) ?? 0.0
                if bat == 0 {
                    // 数字以外のものを受けた
                    if str.contains(">") {
                        type = .NONE        // リセット
                    }
                    
                }else{
                    drawBattery(bat)
                    gotBattery = true
                    type = .NONE
                }
                
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
                    
                    case "05":  // Coolant Temp.
                        type = .NONE
                        let value = Int(subArray[2] , radix: 16) ?? 0   // Scale -40 to 215
                        let coolant = Double(value - 40)
                        drawCoolant(coolant)
                        
                    case "0B":  //  Boost Pressure
                        type = .NONE
                        //let value = (Int(subArray[2], radix: 16) ?? 0) / 100
                        
                    case "0C":  // Engine Revolution
                        type = .NONE
                        if subArray.count < 4 { break }
                        
                        let value = (Int(subArray[2] + subArray[3], radix: 16) ?? 0 ) / 4
                        revValue = value
                        drawRev(value)
                        
                    case "0D":  // Vehicle Speed
                        if displayMode == .SPEED_MODE {
                            type = .NONE
                            unitLabel.text = "km/h"
                            let value = Int(subArray[2] , radix: 16) ?? 0
                            speedLabel.text = String(value)
                            speedValue = value
                            speedLabel.textColor = Color_Syan
                        }

                    case "2F":  // Fuel
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
                    gotFuel = false
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
        let dataWithLog = "\(Util.formattedTime(Date())):  \(log)"
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
