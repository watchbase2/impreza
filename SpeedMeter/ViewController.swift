//
//  ViewController.swift
//  SpeedMeter
//
//  Created by HIdeji Kitamura on 2020/11/15.
//

import UIKit
import CoreBluetooth


class ViewController: UIViewController, CBPeripheralDelegate, CBCentralManagerDelegate  {

    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var responceLabel: UILabel!
    @IBOutlet weak var StatusLED: UILabel!
    
    enum DisplayMode: Int {
        case DISTANCE_MODE = 0
        case SPEED_MODE = 1
    }
    
    var displayMode = DisplayMode.SPEED_MODE
    
    var revoBar:[UIImageView] = []
    
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!
    var serviceUUID : CBUUID!
    var charcteristicUUID_read: CBUUID!
    var charcteristicUUID_write: CBUUID!
    var charcteristic_read: CBCharacteristic!
    var charcteristic_write: CBCharacteristic!
    var isConnected = false
    
    var timer: Timer?
    let divide:Int = 50     // エンジン回転用のバーの分割数
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        valueLabel.text = "----"
        createBar()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        setup()
    }
    
    func createBar() {
        let height:Double = Double(self.view.bounds.height)
        let gap:Double = 20
        
        let step:Double = (height  - gap) / Double(divide)
        
        for pos in 0 ..< divide {
            let y = gap + step * Double(pos)
            let imgView = UIImageView(frame: CGRect(x: 10, y: y, width: 80, height: step - 2))
            imgView.backgroundColor = .gray
            self.view.addSubview(imgView)
            revoBar.append(imgView)
        }
            
    }
    /// セントラルマネージャー、UUIDの初期化
    private func setup() {
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        /*
        serviceUUID = CBUUID(string: "6db168dc-4143-4fbf-8036-2a63526dae35")
        charcteristicUUID_read = CBUUID(string: "7175cca6-878f-4aad-9a43-59a1ff8fb526")     // PIR
        charcteristicUUID_write = CBUUID(string: "93b3d490-19a3-11ea-836a-2e728ce88125")    // light
        */
        serviceUUID = CBUUID(string: "ffe0")
        charcteristicUUID_read = CBUUID(string: "ffe1")
        charcteristicUUID_write = CBUUID(string: "ffe1")
        
    }
    
    @IBAction func sendValue(_ sender: Any) {
        let alert: UIAlertController = UIAlertController(title: "コマンドを入力してください", message: "", preferredStyle:  UIAlertController.Style.alert)
        alert.addTextField(configurationHandler: {(textField:UITextField!) -> Void in
                    textField.text = ""
    
        })
        
        let defaultAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler:{
            // ボタンが押された時の処理を書く（クロージャ実装）
            (action: UIAlertAction!) -> Void in
            
            
            let cmd = alert.textFields?.first!.text
            let data = cmd!.data(using: String.Encoding.utf8, allowLossyConversion:true)!
            self.peripheral.writeValue(data, for: self.charcteristic_write, type: .withResponse)
            
        })
        alert.addAction(defaultAction)
        //self.present(alert, animated: true, completion: nil)

    }
    @IBAction func changeCmd(_ sender: UIButton) {
        
        if !isConnected { return }
        
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
        default:
            cmd = ""
        }
        
        if cmd == "" { return }
        
        let data = cmd.data(using: String.Encoding.utf8, allowLossyConversion:true)!
        self.peripheral.writeValue(data, for: self.charcteristic_write, type: .withResponse)
        
       // self.peripheral.readValue(for: self.charcteristic_read)

    }
    
    @IBAction func speed(_ sender: Any) {
        let cmd = "010C\r"
        
        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            let data = cmd.data(using: String.Encoding.utf8, allowLossyConversion:true)!
            self.peripheral.writeValue(data, for: self.charcteristic_write, type: .withResponse)
            
           // self.peripheral.readValue(for: self.charcteristic_read)
        })

    }
    
    
    @IBAction func flipView(_ sender: UIButton) {
        self.view.flipX()
    }
    
//}

//MARK : - CBCentralManagerDelegate
//extension ViewController: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {

        switch central.state {

        //電源ONを待って、スキャンする
        case CBManagerState.poweredOn:
            let services: [CBUUID] = [serviceUUID]
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
        responceLabel.text = peripheral.name
        self.peripheral = peripheral
        centralManager?.stopScan()

        //接続開始
        central.connect(peripheral, options: nil)
    }

    /// 接続されると呼ばれる
    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {
        print("connected")
        responceLabel.text = "Connected"
        peripheral.delegate = self
        peripheral.discoverServices([serviceUUID])
    }
//}


//MARK : - CBPeripheralDelegate
//extension ViewController: CBPeripheralDelegate {

    /// サービス発見時に呼ばれる
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverServices error: Error?) {

        if error != nil {
            print(error.debugDescription)
            return
        }
        print("find characteristics")
        responceLabel.text = "Service"
        //キャリアクタリスティク探索開始
        peripheral.discoverCharacteristics([charcteristicUUID_write, charcteristicUUID_read],
                                           for: (peripheral.services?.first)!)
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
            
            if characteristic.uuid.isEqual(charcteristicUUID_write) {
                self.charcteristic_write = characteristic
                print("charcteristic_write を発見")
                responceLabel.text = "Character"
                StatusLED.backgroundColor = .green
                isConnected = true
                // 通知をリクエスト
                peripheral.setNotifyValue(true, for: (charcteristic_write)!)
            }
            if characteristic.uuid.isEqual(charcteristicUUID_read) {
                self.charcteristic_read = characteristic
                print("charcteristic_read を発見")
                isConnected = true
                // 通知をリクエスト
                //peripheral.setNotifyValue(true, for: (charcteristic_read)!)
                
            }
        }
        
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        if let error = error {
            print("Write失敗...error: \(error)")
            return
        }
    }
    /// データ更新時に呼ばれる
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {

        if error != nil {
            print(error.debugDescription)
            return
        }
        
        if displayMode == .DISTANCE_MODE {     // センサーポールとの距離表示
        
        
        }else{
            if characteristic.uuid.isEqual(charcteristicUUID_write) {
                print("charcteristicUUID_writeから受信")
                displayData(characteristic)
            }
            if characteristic.uuid.isEqual(charcteristicUUID_read) {
                print("charcteristicUUID_readから受信")
                displayData(characteristic)
            }
        }

    }
    
    func displayData(_ characteristic: CBCharacteristic) {
        let data = characteristic.value!
        let newStr = String(data: data, encoding:String.Encoding.utf8) ?? ""
        responceLabel.text = "write:\(newStr)"
        var valueStr = ""
        
        let strArray = newStr.split(separator: " ")
        if strArray.count < 4 {
            
            valueStr = newStr
            
        }else{
            let str1 = strArray[0]
            let str2 = strArray[1]
            let str3 = strArray[2]
            let str4 = strArray[3]
            
            if str1 == "41" {
                switch str2 {
                case "0B":  // ブースト圧
                    let value = (Int(str3)! * 100 + Int(str4)! )
                    valueStr = String(value)
                    break
                case "0C":  // エンジン回転
                    let value = (Int(str3)! * 100 + Int(str4)! ) / 4
                    valueStr = String(value)
                    
                    let div = revoBar.count
                    let divSpeed = 8000 / div
                    let redStep = 6000 / divSpeed
                    let step = value / divSpeed
                    
                    for pos in 0 ..< div {
                        let imgView = revoBar[pos]
                        
                        if pos < step {
                            if pos < redStep {
                                imgView.backgroundColor = .green
                            }else{
                                imgView.backgroundColor = .red
                            }
                        }else{
                            imgView.backgroundColor = .gray
                        }
                    }
                    
                    break
                case "0D":  // 車速
                    let value = (Int(str3)! * 100 + Int(str4)! )
                    valueStr = String(value)
                    break
                default:
                    break
                }
                
            }else{
                valueStr = newStr
            }
            
        }
        
        if valueStr != "" {
            valueLabel.text = valueStr
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

extension UIView {
    
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    @IBInspectable
    var borderWidth: CGFloat {
        get {
            return self.layer.borderWidth
        }
        set {
            self.layer.borderWidth = newValue
        }
    }
    
    @IBInspectable
    var borderColor: UIColor? {
        get {
            return UIColor(cgColor: self.layer.borderColor!)
        }
        set {
            self.layer.borderColor = newValue?.cgColor
        }
    }
}
