//
//  ConsoleIO.swift
//  calc
//
//  Created by Toai Duong on 19/3/20.
//  Copyright © 2020 UTS. All rights reserved.
//

import Foundation

class ConsoleIO {
    func writeMessage(_ message: String, to: OutputType = .standard) {
        switch to {
        case .standard:
            print("\(message)")
        case .error:
            fputs("Error: \(message)\n", stderr)
        }
    }
    
    func printUsage() {
        
        let executableName = (CommandLine.arguments[0] as NSString).lastPathComponent
        
        writeMessage("usage:")
        writeMessage("./\(executableName) number operator number operator number... ")
        writeMessage("Number: 0 1 2 3... 9 10 11 12...")
        writeMessage("Operator: +  - x / %")
        writeMessage("Example:")
        writeMessage("./\(executableName) 3 x 3 + 5 / 7 % 2")
    }
}

enum OutputType {
    case error
    case standard
}
