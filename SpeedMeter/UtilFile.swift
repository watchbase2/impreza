//
//  UtilFile.swift
//  NewMtrain
//
//  Created by HIDEJI　KITAMMURA on 2019/01/05.
//  Copyright © 2019年 HIDEJI　KITAMMURA. All rights reserved.
//

import Foundation
import UIKit

class Util {
    
    static func getOSversion() ->String {
        let os = ProcessInfo().operatingSystemVersion
        let ios = String(os.majorVersion) + "." + String(os.minorVersion) + "." + String(os.patchVersion)
        return ios
    }
    
    static func getAppVersion() -> String {
        return  Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    }
    
    static func numberStr2currency(_ number:Double? , currencyCode:String?) -> String{
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.currencyCode = currencyCode
        
        let formattedNumber = numberFormatter.string(from: NSNumber(value:number ?? 0.0))!
        
        return formattedNumber
    }
    
    static func numberStrNormal(_ number:Double? ) -> String{
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.none
        
        let formattedNumber = numberFormatter.string(from: NSNumber(value:number ?? 0.0))!
        
        return formattedNumber
    }

    static func dateFromString(string: String, format: String) -> Date {
        let formatter: DateFormatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = format
        return formatter.date(from: string)!
    }

    
    static func formattedTime (_ date:Date) -> String {
        let formatter = DateFormatter()
        
        formatter.dateFormat = "HH:mm:ss"
        formatter.locale = Locale(identifier: "ja_JP")
        
        let normalizedStr = formatter.string(from: date)
        return normalizedStr
        
    }
    
    static func formattedDateTime (_ date:Date) -> String {
        let formatter = DateFormatter()
        
        formatter.dateFormat = "MM/dd HH:mm"
        formatter.locale = Locale(identifier: "ja_JP")
        
        let normalizedStr = formatter.string(from: date)
        return normalizedStr
        
    }
    
    static func formattedDate (_ date:Date, format:String) -> String {
        
        let formatter = DateFormatter()
        
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "ja_JP")
        
        let normalizedStr = formatter.string(from: date)
        return normalizedStr
        
    }
    
    static func formattedDate (_ date:Date) -> String {
        
        let formatter = DateFormatter()
        
        formatter.dateFormat = "yyyy/M/d"
        formatter.locale = Locale(identifier: "ja_JP")
        
        let normalizedStr = formatter.string(from: date)
        return normalizedStr
        
    }
   
    static func formattedDateWithFormat (_ date:Date, format:String ) -> String {
        
        let formatter = DateFormatter()
        
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "ja_JP")
        
        let normalizedStr = formatter.string(from: date)
        return normalizedStr
        
    }
    
    static func formattedLongDate (_ date:Date) -> String {
        let formatter = DateFormatter()
        
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        formatter.locale = Locale(identifier: "ja_JP")
        
        let normalizedStr = formatter.string(from: date)
        return normalizedStr
        
    }
    
    static func formattedFullDate (_ date:Date) -> String {
        let formatter = DateFormatter()
        
        formatter.timeStyle = .none
        formatter.dateStyle = .full
        formatter.locale = Locale(identifier: "ja_JP")
  
        let normalizedStr = formatter.string(from: date)
        return normalizedStr
    }

    static func formattedLongDateEn (_ date:Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        
        let normalizedStr = formatter.string(from: date)
        return normalizedStr
        
    }

    
    // 年初からの日数を得る
    static func getDayOfYear(_ date:Date) -> Int {
        let cal = Calendar.current
        let days = cal.ordinality(of: .day, in: .year, for: date)
        return days!
    }
    
    static func concatinatedName(firstName:String, lastName:String) -> String {
        var concatinatedName = firstName + " " + lastName
        let hasSpecialCharacters =  concatinatedName.range(of: ".*[^A-Za-z0-9 ].*", options: .regularExpression)
        if hasSpecialCharacters != nil {
            
            concatinatedName = lastName + " " + firstName

        }
        return concatinatedName
    }
    // 0時の日付を返す
    static func getZeroDate(_ date:Date) -> Date? {
    
        let formatter = DateFormatter()
        
        formatter.dateFormat = "yyyy/MM/dd"
        formatter.locale = Locale(identifier: "ja_JP")

        let normalizedDateStr = formattedDate(date)

        let date = formatter.date(from: normalizedDateStr)

        
        return date
    }

}

/*
 @IBDesignable class CustomButton: UIButton {

    // 角丸の半径(0で四角形)
    @IBInspectable var cornerRadius: CGFloat = 0.0
    
    // 枠
    @IBInspectable var borderColor: UIColor = UIColor.clear
    @IBInspectable var borderWidth: CGFloat = 0.0
    
    override func draw(_ rect: CGRect) {
        // 角丸
        self.layer.cornerRadius = cornerRadius
        self.clipsToBounds = (cornerRadius > 0)
        
        // 枠線
        self.layer.borderColor = borderColor.cgColor
        self.layer.borderWidth = borderWidth
        
        super.draw(rect)
    }

}
 */

/*
extension UIButton {
    
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

@IBDesignable class CustomImageView: UIImageView {
    
    // 角丸の半径(0で四角形)
    @IBInspectable var cornerRadius: CGFloat = 0.0
    
    // 枠
    @IBInspectable var borderColor: UIColor = UIColor.clear
    @IBInspectable var borderWidth: CGFloat = 0.0
    
    override func draw(_ rect: CGRect) {
        // 角丸
        self.layer.cornerRadius = cornerRadius
        self.clipsToBounds = (cornerRadius > 0)
        
        // 枠線
        self.layer.borderColor = borderColor.cgColor
        self.layer.borderWidth = borderWidth
        
        super.draw(rect)
    }
}
*/
 
/*
@IBDesignable class CustomUIView: UIView {
    
    // 角丸の半径(0で四角形)
    @IBInspectable var cornerRadius: CGFloat = 0.0
    
    // 枠
    @IBInspectable var borderColor: UIColor = UIColor.clear
    @IBInspectable var borderWidth: CGFloat = 0.0
    
    override func draw(_ rect: CGRect) {
        // 角丸
        self.layer.cornerRadius = cornerRadius
        self.clipsToBounds = (cornerRadius > 0)
        
        // 枠線
        self.layer.borderColor = borderColor.cgColor
        self.layer.borderWidth = borderWidth
        
        super.draw(rect)
    }
}
*/
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

/*
@IBDesignable class CustomUITextView: UITextView {
    
    // 角丸の半径(0で四角形)
    @IBInspectable var cornerRadius: CGFloat = 0.0
    
    // 枠
    @IBInspectable var borderColor: UIColor = UIColor.clear
    @IBInspectable var borderWidth: CGFloat = 0.0
    
    override func draw(_ rect: CGRect) {
        // 角丸
        self.layer.cornerRadius = cornerRadius
        self.clipsToBounds = (cornerRadius > 0)
        
        // 枠線
        self.layer.borderColor = borderColor.cgColor
        self.layer.borderWidth = borderWidth
        
        super.draw(rect)
    }
}
*/
extension Date {
    var weekday: String {
        let calendar = Calendar(identifier: .gregorian)
        let component = calendar.component(.weekday, from: self)
        let weekday = component - 1
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja")
        return formatter.shortWeekdaySymbols[weekday]
    }
}

extension Dictionary {
    var json: String? {
        // Generate JSON string from dict
        var json:String?
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self, options: []) //(*)options??
            json = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)! as String
        }catch{
            json = nil
        }
        return json
    }
}

extension UIViewController {
  func showAlert(withTitle title: String?, message: String?) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
    alert.addAction(action)
    present(alert, animated: true, completion: nil)
  }
}

// show alert always on current top view
public extension UIAlertController {
    func showOnTop() {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate

        var topController: UIViewController = appDelegate.window!.rootViewController!
        while (topController.presentedViewController != nil) {
            topController = topController.presentedViewController!
        }

        topController.present(self, animated: true, completion: nil)
    }
    
}

//閉じるボタンの付いたキーボード
class DoneTextFierd: UITextField{

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit(){
        let tools = UIToolbar()
        tools.frame = CGRect(x: 0, y: 0, width: frame.width, height: 40)
        tools.backgroundColor = UIColor.clear
        tools.tintColor = UIColor.clear
        
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        
        //let closeButton = UIBarButtonItem(barButtonSystemItem: .some("X"), target: self, action: #selector(self.closeButtonTapped))
        let closeButton = UIBarButtonItem(title: "X", style: .plain, target: self, action: #selector(self.closeButtonTapped))
        closeButton.tintColor = UIColor(named: "Dim Gray")
        tools.items = [spacer, closeButton]
        self.inputAccessoryView = tools
    }

    @objc func closeButtonTapped(){
        self.endEditing(true)
        self.resignFirstResponder()
    }
}
