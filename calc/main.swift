//
//  main.swift
//  calc
//
//  Created by Jesse Clark on 12/3/18.
//  Copyright © 2018 UTS. All rights reserved.
//

import Foundation

class Equation{
    var args:[String]
    var result:Int
    
    init(args:[String]) {
        self.args=args
        self.result=0
    }
    
    func isValid() -> Bool{
        var valid = false
        for i in 0...args.count-1{
            let num = Int(args[i])
            if (args[i]=="+" || args[i]=="-" || args[i]=="x" || args[i]=="/" || args[i]=="%"){
                valid = true
            }
            else if num != nil
            {
                valid = true
            }
            else{
                valid = false
                break;
            }            
        }
        return valid
    }
    
    func highOperationValue() -> Bool{
        var isHight = false
        if args.count>2{
            for i in 0...args.count-1{
                if(args[i]=="x" || args[i]=="/" || args[i]=="%"){
                    isHight = true
                    break
                }
            }
        }
        return isHight
    }
    
    func newArgs(value:String,pos:Int) -> [String]{
        var new : [String] = []
        if(pos > 1){
            for a in 0...pos-2{
                new.append(args[a])
            }
        }
        new.append (value)
        if(pos != args.count-2){
            for b in pos+2...args.count-1{
                new.append(args[b])
            }
        }
        return new
    }
    
    func multiplyDivideModulus(){
        for i in 1...args.count-1{
            if args[i] == "x"{
                args = newArgs(value: String(Int(args[i-1])! * Int(args[i+1])!), pos: i)
                break
            }
            if args[i] == "/"{
                if args[i+1] == "0"{
                     //args = newArgs(value: String(Int(args[i-1])! / Int(args[i+1])!), pos: i)
                    print("Division by zero")
                    exit(4)
                }else{
                    args = newArgs(value: String(Int(args[i-1])! / Int(args[i+1])!), pos: i)
                    break
                }
            }
            
            if args[i] == "%"{
                if args[i+1] == "0"{
                    //args = newArgs(value: String(Int(args[i-1])! / Int(args[i+1])!), pos: i)
                    print("Module by zero")
                    exit(4)
                }else{
                    args = newArgs(value: String(Int(args[i-1])! % Int(args[i+1])!), pos: i)
                    break
                }
            }
            
        }
    }
    func addAndSubtract(){
        result = Int(args[0])!
        if args.count > 1 {
            for i in 1...args.count-1{
                if args[i] == "+"{
                    result += Int(args[i+1])!
                }
                if args[i] == "-"{
                    result -= Int(args[i+1])!
                }
            }
        }
    }
    func prntRes() {
        print("\(result)")
    }
}

func getargs() -> [String]{    
    var args = ProcessInfo.processInfo.arguments
    args.removeFirst() // make the args ready
    return args
}
func getInput() ->  [String] {
    
    //print("Please enter numbers to calculate: ")
    let inputString: String? = String(readLine()!)
    
    if inputString == nil {
        print("Input was not a number")
        exit(1)
    }
    
    guard let input = inputString else { return [] }
    
    var inputText = input.split{$0 == " "}.map(String.init)
    if inputText.count>0 {
        //print(inputText)
        inputText.removeFirst() // make the args ready
    }
    return inputText
}


func validArgs (arg:String) -> Bool{
    if arg=="+" || arg=="-" || arg=="x" || arg=="/" || arg=="%" || Int(arg) != nil {
        return true
    }else{
        return false
    }
}

func main() ->  [String] {
     let args = getargs()
    if args.count>0 {
        return args
    }
    else{
        return getInput()
    }
}

//1: If you want to run in Terminal Use 1 Uncomment below
//var equation: Equation = Equation(args: getInput()) //1
//2: If you need to Work for TestCases Use 2 Uncomment below
//var equation: Equation = Equation(args: getargs()) //2

//Main
var equation: Equation = Equation(args: main()) //2
if equation.args.count > 0{
//    let result = Int(equation.args[0])
    /*if equation.args.count < 3{
        print("Incomplete ")
        exit(2)
    }else*/
    if equation.args.count == 2{
        print("Invalid inputs")
        exit(2)
    }
    else if !equation.isValid(){
        print("Invalid ")
        exit(3)
    }else{
        while equation.highOperationValue(){
            equation.multiplyDivideModulus()
        }
        equation.addAndSubtract()
        equation.prntRes()
    }    
}
else {
    print("Invalid inputs")
    exit(2)
}

