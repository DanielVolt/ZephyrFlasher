//
//  UDSProgrammer.swift
//  UDSProgrammer
//  Gosh do i hate SWIFT.
//  Created by DanielVolt on 12/7/22.
//
//  CBOOT Code is a Swift Port from the original Python version https://github.com/bri3d/VW_Flash/blob/867e39124c183e5a6957e137975046320fbd7b9a/lib/patch_cboot.py
//  All credits go to the original Author Bri3d, thanks for letting me use this! 
//
//  Checksumming is a Swift Port from the original Python version https://github.com/bri3d/VW_Flash/blob/b751dc9b29069bb84227ba3742a6dc0c7cb7be99/lib/checksum.py
//  And also from the Java/Kotlin code that JoeDubz wrote that is included in ST for Android: https://github.com/joeFischetti/simos_helpers/blob/main/encryptSimos.kt
//  Big thanks to both Bri3d and JoeDubz & Co, without y'all we wouldn't have such beauties.

import Foundation

class UDSProgrammer {
    private let CBOOTneedle: [UInt8] = [0xDA, 0x00, 0x3C, 0x02, 0xDA, 0x01, 0x02, 0xF2]
    private let CBOOTpatch: [UInt8] = [0x00, 0x00, 0x00, 0x00, 0xDA, 0x01, 0x02, 0xF2]
    
    func patchCboot(cbootBinary: Data) -> Data {
        let needleBytes = Data(CBOOTneedle)
        let patchBytes = Data(CBOOTpatch)
        var cbootBinary = cbootBinary
        
        guard let firstAddress = cbootBinary.range(of: needleBytes) else {
            print("Could not find needle for CBOOT patching. Already patched?")
            
            return cbootBinary
        }
        
        guard let secondAddress = cbootBinary.range(of: needleBytes, options: [], in: firstAddress.upperBound..<cbootBinary.endIndex) else {
            print("Could not find needle for CBOOT patching. Already patched?")
            
            return cbootBinary
        }
        
        guard let thirdAddress = cbootBinary.range(of: needleBytes, options: [], in: secondAddress.upperBound..<cbootBinary.endIndex) else {
            print("BIN is unpatched! patching...")
            
            cbootBinary.replaceSubrange(firstAddress, with: patchBytes)
            print("found first, patching: \(firstAddress)")
            
            cbootBinary.replaceSubrange(secondAddress, with: patchBytes)
            print("found second, patching: \(secondAddress)")
            
            return cbootBinary
        }
        
        print("Too many bitches")
        return cbootBinary
    }
    
    func checksumBIN(bin: [UInt8], baseAddress: UInt, checksumLocation: Int) -> [UInt8] {
        print("UDSProgrammer: Checksumming block, base address \(baseAddress), and checksum location: \(checksumLocation)")

        let currentChecksum = Array(bin[checksumLocation..<checksumLocation + 8])
        print("UDSProgrammer: Current Checksum: \(currentChecksum)")

        let offset = baseAddress
        var startAddress1 = Int(byteArrayToInt(Array(bin[checksumLocation + 12..<checksumLocation + 16]).reversed())) - Int(offset)
        var endAddress1 = Int(byteArrayToInt(Array(bin[checksumLocation + 16..<checksumLocation + 20]).reversed())) - Int(offset)
        var startAddress2 = Int(byteArrayToInt(Array(bin[checksumLocation + 20..<checksumLocation + 24]).reversed())) - Int(offset)
        var endAddress2 = Int(byteArrayToInt(Array(bin[checksumLocation + 24..<checksumLocation + 28]).reversed())) - Int(offset)

        var checksumData: [UInt8] = []

        checksumData = Array(bin[Int(startAddress1)..<Int(endAddress1) + 1])

        if(endAddress2 - startAddress2 > 0) {
            checksumData += Array(bin[Int(startAddress2)..<Int(endAddress2) + 1])
        }

        let polynomial: UInt32 = 0x4c11db7
        var crc: UInt32 = 0x00000000

        for c in checksumData {
            for j in (0...7).reversed() {
                let z32: UInt8 = UInt8((crc >> 31) & 0xff)
                crc = crc << 1
                let test = ((UInt32(c) >> j) & 1) ^ UInt32(z32)
                if test > 0 {
                    crc = crc ^ polynomial
                }

                crc = crc & 0xffffffff
            }
        }

        let checksumCalculated = [UInt8(0x0), UInt8(0x0), UInt8(0x0), UInt8(0x0)] + intToByteArray(value: crc).reversed()

        let currentChecksumHex = currentChecksum.map { String(format: "%02x", $0) }.joined()
        print("UDSProgrammer: Current checksum: \(currentChecksumHex)")
        
        let checksumCalculatedHex = checksumCalculated.map { String(format: "%02x", $0) }.joined()
        print("UDSProgrammer: Calculated checksum: \(checksumCalculatedHex)")

        if Array(currentChecksum) == checksumCalculated {
            print("UDSProgrammer: Checksum of BIN matches!")
        } else {
            print("UDSProgrammer: Checksum of BIN doesn't match!")
        }

        var newBin = bin

        for i in 0..<checksumCalculated.count {
            newBin[checksumLocation + i] = checksumCalculated[i]
        }

        return newBin
    }
    
    func checksumECM3BIN(bin: [UInt8], addresses: [Int], second: [Int]) -> [UInt8] {
        var startAddress = addresses[0]
        var endAddress = second[0]

        let checksumLocation = 0x400
        let checksumCurrent = bin[checksumLocation..<(checksumLocation + 8)]

        // Starting Value
        var checksum = UInt64(byteArrayToInt(bin[(checksumLocation + 8)..<(checksumLocation + 12)].reversed())) << 32
        checksum += UInt64(byteArrayToInt(bin[(checksumLocation + 12)..<(checksumLocation + 16)].reversed()))

        for i in stride(from: startAddress, to: endAddress, by: 4) {
            checksum += UInt64(byteArrayToInt(bin[i..<(i + 4)].reversed()))
        }

        let checksumCalculated = intToByteArray(value: Int((checksum >> 32))).reversed() as [UInt8] + intToByteArray(value: Int(checksum & 0xFFFFFFFF)).reversed() as [UInt8]

        let checksumCurrentHex = checksumCurrent.map { String(format: "%02x", $0) }.joined()
        let checksumCalculatedHex = checksumCalculated.map { String(format: "%02x", $0) }.joined()
        print("UDSProgrammer: Current ECM3: \(checksumCurrentHex)")
        print("UDSProgrammer: Calculated ECM3: \(checksumCalculatedHex)")

        if Array(checksumCurrent) == checksumCalculated {
            print("UDSProgrammer: ECM3 Checksum of BIN matches!")
        } else {
            print("UDSProgrammer: ECM3 Checksum doesn't match!")
        }

        var newBin = bin

        for i in 0..<checksumCalculated.count {
            newBin[0x400 + i] = checksumCalculated[i]
        }

        return newBin
    }

}
