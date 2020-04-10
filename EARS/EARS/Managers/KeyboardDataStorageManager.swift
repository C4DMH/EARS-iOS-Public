//
//  KeyboardDataStorageManager.swift
//  EARS Keyboard
//
//  Created by Wyatt Reed on 11/28/18.
//  Copyright © 2018 UO Center for Digital Mental Health. All rights reserved.
//
//  This class is exclusively used for writing keyboard files.

import CommonCrypto
import Foundation
import Security
import AWSS3
import SwiftProtobuf


class KeyboardEncryption{

    enum AESError: Error {
        case KeyError((String, Int))
        case IVError((String, Int))
        case CryptorError((String, Int))
    }
    
    /// Encrypts or Decrypts input data for AES/CBC/PKCS7Padding given a key, IV and encrypt/decrypt flag. Uses CommonCrypto library
    ///
    /// - Parameters:
    ///   - data: data to be encrypted/decrypted. Input data for encryption should be UTF-8 encoded.
    ///   - keyData: 16-byte key data. (e.g. data from a password string encoded for UTF-8)
    ///   - ivData: 16-byte Initialization Vector Data. (e.g. data contents of a UInt8 Array of length 16)
    ///   - operation:
    /// - Returns: 0 or kCCEncrypt for Encryption, 1 or kCCDecrypt for Decryption.
    func aesCBCEncryption(data:Data, keyData:Data, ivData:Data, operation:Int) -> Data {
        let cryptLength  = size_t(data.count + kCCBlockSizeAES128 )
        var cryptData = Data(count:cryptLength)
        
        let keyLength             = size_t(kCCKeySizeAES128)
        let options   = CCOptions(kCCOptionPKCS7Padding)
        
        
        var numBytesEncrypted :size_t = 0
        
        let cryptStatus = cryptData.withUnsafeMutableBytes {cryptBytes in
            data.withUnsafeBytes {dataBytes in
                ivData.withUnsafeBytes {ivBytes in
                    keyData.withUnsafeBytes {keyBytes in
                        CCCrypt(CCOperation(operation),
                                CCAlgorithm(kCCAlgorithmAES),
                                options,
                                keyBytes, keyLength,
                                ivBytes,
                                dataBytes, data.count,
                                cryptBytes, cryptLength,
                                &numBytesEncrypted)
                    }
                }
            }
        }
        
        if UInt32(cryptStatus) == UInt32(kCCSuccess) {
            cryptData.removeSubrange(numBytesEncrypted..<cryptData.count)
            
        } else {
            //print("Error: \(cryptStatus)")
        }
        
        return cryptData;
    }
    
    
}

class KeyboardDataStorage{
    var device_id: String
    var dataType: String
    
    init(dataType: String){
        self.device_id = KeyboardViewController.device_id
        self.dataType = dataType
        //queue = DispatchQueue(label: "my.dataqueue." + self.dataType, attributes: [])
    }
    
    deinit {
        //NSLog("\(dataType) Datastorage deinit invoked.")
        //AppDelegate.debug.recordLog(line: "\(dataType) Datastorage de-initialized")
    }
    
    /**
     Generates a name for a file based on dataType, date, and upload count.
     - parameters:
     - dataType: Specifies the type of data file (e.g. GPS).
     - uploadCount: Denotes the number of times a file with the same dataType has been uploaded in a day.
     - returns: String name in the format dataType_date_count.txt (e.g. 'GPS_2018-01-25.txt') where date is Unix time since 1970 formatted to yyyy-MM-dd.
     
     
     */
    
    private func parseFileName(dataType: String) -> String {
        // dataType + Date + count
        let currentDateTime = Date()
        let dateFormatter = DateFormatter()
        //let date = dateFormatter.date(from: )
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH"
        let dateString = dateFormatter.string(from: currentDateTime)
        //let dateString = String(Int64(date.timeIntervalSince1970 * 1000))
        let fileName = "\(dataType)_\(dateString).txt"
        return fileName
    }
    
    private func parseImageFileName(dataType: String, epoch: Int64, uploadCount: Int) -> String {
        // dataType + Date + count
        let currentDateTime = Date()
        let dateFormatter = DateFormatter()
        //let date = dateFormatter.date(from: )
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: currentDateTime)
        //let dateString = String(Int64(date.timeIntervalSince1970 * 1000))
        let fileName = "\(dataType)_\(dateString)_\(String(epoch))_\(String(uploadCount)).txt"
        return fileName
    }
    
    
    /// Writes a file in the cache given the file name generated by parseFileName(). If a file already exists in the cache under the generated name (files will be generated with the same name for each day for each data type) the data will be appended to the end of the file.
    ///
    /// - Parameter data: UTF8 encoded String data.
    func writeFile(data: Data ){
        // THIS FUNCTION IS NO LONGER USED IN PRODUCTION.
        // Its only current case of use is in DebugManager.swift
        let fileName = parseFileName(dataType: dataType)
        
        guard let dir = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: GROUP_IDENTIFIER) else {
            //print("directory failed")
            return
        }
        
        let fileUrl = dir.appendingPathComponent(fileName)
        
        if FileManager.default.fileExists(atPath: fileUrl.path) {
            
            if let fileHandle = try? FileHandle(forUpdating: fileUrl) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            }
            //NSLog("File Written @ \(fileName)")
        } else {
            let appendString = String(data: data, encoding: .utf8)
            let devicePrefix = "\(self.device_id), \(UIDevice.modelName), \(getOSInfo()), \(getAppInfo())\n"
            let finalString = devicePrefix + appendString!
            
            try! finalString.data(using:String.Encoding.utf8)!.write(to: fileUrl, options: Data.WritingOptions.atomic)
            //NSLog("New File Written @ \(fileName)")
            
        }
        
    }
    
    
    func writeFileProto(messageArray: [SwiftProtobuf.Message] ){
        let fileName = parseFileName(dataType: dataType)
        /*
        guard let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            print("directory failed")
            return
        }
        */
        
         guard let dir = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: GROUP_IDENTIFIER) else {
             //print("directory failed")
             return
         }
        
        let fileUrl = dir.appendingPathComponent(fileName)
        
        if FileManager.default.fileExists(atPath: fileUrl.path) {

            if (try? FileHandle(forUpdating: fileUrl)) != nil {
                guard let outputStream = OutputStream(url: fileUrl, append: true) else {
                    NSLog("Could not create output stream")
                    return
                }

                outputStream.open()
                defer { outputStream.close() }
                
                for each in messageArray{
                    do{
                        try BinaryDelimited.serialize(message: each, to: outputStream)
                    }catch{
                        NSLog("Could not serialize to Protobuf from outputStream")
                        return
                    }
                }
            }
        } else {
            
            let fileHeader = Research_Header.with {
                $0.deviceID = "\(self.device_id)"
                $0.modelName = "\(UIDevice.modelName)"
                $0.osVersion = "\(getOSInfo())"
                $0.appVersion = "\(getAppInfo())"
                $0.timezone = "\(getTimeZone())"
            }
            //Header Delimiter
            guard let outputStream = OutputStream(url: fileUrl, append: true) else {
                NSLog("Could not create output stream.")
                return
            }
            outputStream.open()
            defer { outputStream.close() }
            do{
                try BinaryDelimited.serialize(message: fileHeader, to: outputStream)
            }catch{
                NSLog("Could not serialize to Protobuf from outputStream")
                return
            }
            for each in messageArray{
                do{
                    try BinaryDelimited.serialize(message: each, to: outputStream)
                }catch{
                    NSLog("Could not serialize to Protobuf from outputStream")
                    return
                }
            }

            //NSLog("New File Written @ \(fileName)")
        }
        
    }
    func getTimeZone() -> String{
        let currentDateTime = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'"
        var secondsFromGMT: Int { return TimeZone.current.secondsFromGMT() }
        dateFormatter.timeZone = TimeZone(secondsFromGMT: secondsFromGMT)
        dateFormatter.dateFormat = "ZZZZZ"
        let timeZoneString = dateFormatter.string(from: currentDateTime)
        return timeZoneString
    }
    
    
    
    func getOSInfo()->String {
        let os = ProcessInfo().operatingSystemVersion
        return String(os.majorVersion) + "." + String(os.minorVersion) + "." + String(os.patchVersion)
    }
    
    func getAppInfo()->String {
        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        let build = dictionary["CFBundleVersion"] as! String
        return version + "(" + build + ")"
    }
    
}

// https://stackoverflow.com/a/26962452/7507949
public extension UIDevice {

    static let modelName: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }

        func mapToDevice(identifier: String) -> String { // swiftlint:disable:this cyclomatic_complexity
            #if os(iOS)
            switch identifier {
            case "iPod5,1":                                 return "iPod touch (5th generation)"
            case "iPod7,1":                                 return "iPod touch (6th generation)"
            case "iPod9,1":                                 return "iPod touch (7th generation)"
            case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
            case "iPhone4,1":                               return "iPhone 4s"
            case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
            case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
            case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
            case "iPhone7,2":                               return "iPhone 6"
            case "iPhone7,1":                               return "iPhone 6 Plus"
            case "iPhone8,1":                               return "iPhone 6s"
            case "iPhone8,2":                               return "iPhone 6s Plus"
            case "iPhone9,1", "iPhone9,3":                  return "iPhone 7"
            case "iPhone9,2", "iPhone9,4":                  return "iPhone 7 Plus"
            case "iPhone8,4":                               return "iPhone SE"
            case "iPhone10,1", "iPhone10,4":                return "iPhone 8"
            case "iPhone10,2", "iPhone10,5":                return "iPhone 8 Plus"
            case "iPhone10,3", "iPhone10,6":                return "iPhone X"
            case "iPhone11,2":                              return "iPhone XS"
            case "iPhone11,4", "iPhone11,6":                return "iPhone XS Max"
            case "iPhone11,8":                              return "iPhone XR"
            case "iPhone12,1":                              return "iPhone 11"
            case "iPhone12,3":                              return "iPhone 11 Pro"
            case "iPhone12,5":                              return "iPhone 11 Pro Max"
            case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
            case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad (3rd generation)"
            case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad (4th generation)"
            case "iPad6,11", "iPad6,12":                    return "iPad (5th generation)"
            case "iPad7,5", "iPad7,6":                      return "iPad (6th generation)"
            case "iPad7,11", "iPad7,12":                    return "iPad (7th generation)"
            case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
            case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
            case "iPad11,4", "iPad11,5":                    return "iPad Air (3rd generation)"
            case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad mini"
            case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad mini 2"
            case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad mini 3"
            case "iPad5,1", "iPad5,2":                      return "iPad mini 4"
            case "iPad11,1", "iPad11,2":                    return "iPad mini (5th generation)"
            case "iPad6,3", "iPad6,4":                      return "iPad Pro (9.7-inch)"
            case "iPad6,7", "iPad6,8":                      return "iPad Pro (12.9-inch)"
            case "iPad7,1", "iPad7,2":                      return "iPad Pro (12.9-inch) (2nd generation)"
            case "iPad7,3", "iPad7,4":                      return "iPad Pro (10.5-inch)"
            case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4":return "iPad Pro (11-inch)"
            case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8":return "iPad Pro (12.9-inch) (3rd generation)"
            case "AppleTV5,3":                              return "Apple TV"
            case "AppleTV6,2":                              return "Apple TV 4K"
            case "AudioAccessory1,1":                       return "HomePod"
            case "i386", "x86_64":                          return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "iOS"))"
            default:                                        return identifier
            }
            #elseif os(tvOS)
            switch identifier {
            case "AppleTV5,3": return "Apple TV 4"
            case "AppleTV6,2": return "Apple TV 4K"
            case "i386", "x86_64": return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "tvOS"))"
            default: return identifier
            }
            #endif
        }

        return mapToDevice(identifier: identifier)
    }()

}
