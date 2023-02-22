//
//  UDSProgrammer.swift
//  UDSProgrammer
//
//  Created by DanielVolt on 12/7/22.
//
//  CBOOT Code is a Swift Port from the original Python version https://github.com/bri3d/VW_Flash/blob/867e39124c183e5a6957e137975046320fbd7b9a/lib/patch_cboot.py
//  All credits go to the original Author Bri3d, thanks for letting me use this! 

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
}
