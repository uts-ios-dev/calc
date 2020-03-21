//
//  StringExtension.swift
//  calc
//
//  Created by Toai Duong on 19/3/20.
//  Copyright © 2020 UTS. All rights reserved.
//

import Foundation

extension String {
    
    var IsInt: Bool {
        Int(self) != nil
    }
        
    static func IsOperator(operatorArgument: Operators) -> Bool {
        switch operatorArgument {
        case Operators.multiply, Operators.minus, Operators.plus, Operators.modulus, Operators.devide:
            return true
        default:
            return false
        }
    }
}


