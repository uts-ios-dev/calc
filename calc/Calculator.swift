//
//  Calculator.swift
//  calc
//
//  Created by Toai Duong on 20/3/20.
//  Copyright © 2020 UTS. All rights reserved.
//

import Foundation

class Calculator {
    let consoleIO = ConsoleIO()
    var arrayOfArguments: [String] = []
    var priorityOperatorIndex: Int = 0
    
    func CheckParametersInput(){
        let argCount = CommandLine.argc
        var isInputCorrect = true
        for index in 1..<argCount {
            if index % 2 != 0 {
                if CommandLine.arguments[Int(index)].IsInt {
                    arrayOfArguments.append(CommandLine.arguments[Int(index)])
                }
                else {
                    print("\(CommandLine.arguments[Int(index)]) is not a number\n")
                    isInputCorrect = false
                    consoleIO.printUsage()
                    return
                }
            }
            else {
                if String.IsOperator(operatorArgument: Operators(rawValue: CommandLine.arguments[Int(index)]) ?? Operators.unknown) {
                    arrayOfArguments.append(CommandLine.arguments[Int(index)])
                }
                else {
                    print("\(CommandLine.arguments[Int(index)]) is not an operator\n")
                    isInputCorrect = false
                    consoleIO.printUsage()
                    return
                }
            }
        }
        if String.IsOperator(operatorArgument: Operators(rawValue: arrayOfArguments.last ?? Operators.unknown.rawValue) ?? Operators.unknown) {
            isInputCorrect = false
            print("Last argument \(arrayOfArguments.last!) must be a number\n")
            consoleIO.printUsage()
            return
        }
        
        if isInputCorrect == true {
            PerformCalculate()
        }
    }
    
    private func PerformCalculate() {
        if PerformHighPriorityCalculation() == false {
            return
        }
        PerformLowPriorityCalculatrion()
        print("result is \(arrayOfArguments[0])")
    }
    
    private func PerformLowPriorityCalculatrion() {
        var firstVal: Int
        var secondVal: Int
        var resultInt: Int
        var operatorRawVal: String
        let operatorPosition: Int = 1
        while operatorPosition < arrayOfArguments.count {
            firstVal = (arrayOfArguments[operatorPosition - 1] as NSString).integerValue
            secondVal = (arrayOfArguments[operatorPosition + 1] as NSString).integerValue
            operatorRawVal = arrayOfArguments[operatorPosition]
            
            switch operatorRawVal {
            case Operators.plus.rawValue:
                resultInt = firstVal + secondVal
            default:
                resultInt = firstVal - secondVal
            }
            
            ShrikArray(resultVal: resultInt, indexToRemove: operatorPosition)
            PerformLowPriorityCalculatrion()
            break
        }
    }
    
    private func PerformHighPriorityCalculation() -> Bool{
        var firstVal: Int
        var secondVal: Int
        var resultInt: Int
        var operatorRawVal: String
        var operatorPosition: Int = 1
        
        while operatorPosition < arrayOfArguments.count {
            if IsPriorityOperator(operators: Operators(rawValue: arrayOfArguments[operatorPosition]) ?? Operators.unknown) {
                firstVal = (arrayOfArguments[operatorPosition - 1] as NSString).integerValue
                secondVal = (arrayOfArguments[operatorPosition + 1] as NSString).integerValue
                operatorRawVal = arrayOfArguments[operatorPosition]
                
                switch operatorRawVal {
                case Operators.multiply.rawValue:
                    resultInt = firstVal * secondVal
                case Operators.devide.rawValue:
                    if secondVal == 0 {
                        print("Connot perform devide to zero \(firstVal) / \(secondVal)")
                        return false
                    }
                    resultInt = firstVal / secondVal
                default:
                    resultInt = firstVal % secondVal
                }
                
                ShrikArray(resultVal: resultInt, indexToRemove: operatorPosition)
                _ = PerformHighPriorityCalculation()
                break
            }
            
            operatorPosition = operatorPosition + 2
        }
        return true
    }
    
    private func ShrikArray(resultVal: Int, indexToRemove: Int) -> Void {
        arrayOfArguments.removeSubrange((indexToRemove - 1)...(indexToRemove + 1))
        arrayOfArguments.insert(String(resultVal), at: (indexToRemove - 1))
    }
    
    private func IsPriorityOperator(operators: Operators) -> Bool {
        switch operators {
        case Operators.multiply, Operators.modulus, Operators.devide:
            return true
        default:
            return false
        }
    }
}

enum Operators: String {
    case multiply = "x"
    case devide = "/"
    case plus = "+"
    case minus = "-"
    case modulus = "%"
    case unknown
}

