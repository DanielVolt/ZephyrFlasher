//
//  SA2Seedkey.swift
//  SA2Seedkey
//
//  Created by DanielVolt on 12/13/22.
//
//  SA2SeedKey Code is a Swift Port from the original Python version https://github.com/bri3d/sa2_seed_key/blob/76f5e776f9e816bfa3f34cc29ea6f64ca9d1b55d/sa2_seed_key/sa2_seed_key.py
//  Big thanks to JoeDubs, you can find his Java/Kotlin port that is used in the infamous ST Android app here: https://github.com/joeFischetti/simos_helpers/blob/main/sa2seedkey.kt
//  All credits go to the original Author Bri3d, thanks for letting me use this! 

Import Foundation

class Sa2SeedKey {
    var instructionPointer = 0
    var instructionTape: [UInt8]
    var register: UInt32
    var carryFlag: UInt32 = 0
    var forPointers: [Int] = []
    var forIterations: [Int] = []
    
    init(inputTape: [UInt8], seed: [UInt8]) {
        instructionTape = inputTape
        register = UInt32(seed[0]) << 24 | UInt32(seed[1]) << 16 | UInt32(seed[2]) << 8 | UInt32(seed[3])
    }
    
    func rsl() {
        carryFlag = register & 0x80000000
        register = register << 1
        if carryFlag != 0 {
            register |= 0x1
        }
        
        register &= 0xFFFFFFFF
        instructionPointer += 1
    }
    
    func rsr() {
        carryFlag = register & 0x1
        register = register >> 1
        
        if carryFlag != 0 {
            register |= 0x80000000
        }
        
        instructionPointer += 1
    }
    
    func add() {
        carryFlag = 0
        let operands = Array(instructionTape[instructionPointer + 1..<instructionPointer + 5])
        let operand: UInt32 = UInt32(operands[0]) << 24 | UInt32(operands[1]) << 16 | UInt32(operands[2]) << 8 | UInt32(operands[3])
        var outputRegister = register &+ operand
        
        if outputRegister > 0xFFFFFFFF {
            carryFlag = 1
            outputRegister = outputRegister & 0xFFFFFFFF
        }
        
        register = outputRegister
        instructionPointer += 5
    }
    
    func sub() {
        carryFlag = 0
        let operands = Array(instructionTape[instructionPointer + 1..<instructionPointer + 5])
        let operand: UInt32 = UInt32(operands[0]) << 24 | UInt32(operands[1]) << 16 | UInt32(operands[2]) << 8 | UInt32(operands[3])
        var outputRegister = register &- operand
        
        if outputRegister < 0 {
            carryFlag = 1
            outputRegister = outputRegister & 0xFFFFFFFF
        }
        
        register = outputRegister
        instructionPointer += 5
    }
    
    func eor() {
        let operands = Array(instructionTape[instructionPointer + 1..<instructionPointer + 5])
        let operand: UInt32 = UInt32(operands[0]) << 24 | UInt32(operands[1]) << 16 | UInt32(operands[2]) << 8 | UInt32(operands[3])
        register ^= operand
        instructionPointer += 5
    }
    
    func forLoop() {
        let operand = instructionTape[instructionPointer + 1]
        forIterations.insert(Int(operand - 1), at: 0)
        instructionPointer += 2
        forPointers.insert(instructionPointer, at: 0)
    }
    
    func nextLoop() {
        if forIterations[0] > 0 {
            forIterations[0] -= 1
            instructionPointer = forPointers[0]
        } else {
            forIterations.remove(at: 0)
            forPointers.remove(at: 0)
            instructionPointer += 1
        }
    }
    
    func bcc() {
        let operands = instructionTape[instructionPointer + 1]
        let skip_count = Int(operands) + 2
        if carryFlag == 0 {
            instructionPointer += skip_count
        } else {
            instructionPointer += 2
        }
    }
    
    func bra() {
        let operands = instructionTape[instructionPointer + 1]
        let skip_count = Int(operands) + 2
        instructionPointer += skip_count
    }
    
    func finish() {
        instructionPointer += 1
    }
    
    func execute() -> [UInt8] {
        let instructionSet: [UInt8: () -> Void] = [
            0x81: rsl,
            0x82: rsr,
            0x93: add,
            0x84: sub,
            0x87: eor,
            0x68: forLoop,
            0x49: nextLoop,
            0x4A: bcc,
            0x6B: bra,
            0x4C: finish
        ]
        
        while instructionPointer < instructionTape.count {
            instructionSet[instructionTape[instructionPointer]]?()
        }
        
        return UIntToByteArray(register)
    }
    
    func UIntToByteArray(_ value: UInt32) -> [UInt8] {
        return [
            UInt8((value & 0xff000000) >> 24),
            UInt8((value & 0x00ff0000) >> 16),
            UInt8((value & 0x0000ff00) >> 8),
            UInt8(value & 0x000000ff)
        ]
    }
    
}
