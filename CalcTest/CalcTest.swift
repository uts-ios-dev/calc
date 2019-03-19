//
//  CalcTest.swift
//  CalcTest
//
//  Created by Jesse Clark on 13/3/17.
//  Copyright © 2017 UTS. All rights reserved.
//

import XCTest
import GameKit // for deterministic random number generator

let randomSource = GKLinearCongruentialRandomSource(seed: 9)

let calcBundle = Bundle(identifier: "UTS.CalcTest")!
let calcPath = ProcessInfo.processInfo.environment["CALC_PATH"] ?? calcBundle.path(forResource: "calc", ofType: nil)

enum calcError: Error {
    case exitStatus(Int32)
    case timeout
    case launchFailed
}
extension calcError: Equatable {
    static func ==(lhs: calcError, rhs: calcError)->Bool {
        switch (lhs, rhs) {
        case (.timeout, .timeout):
            return true
        case (.launchFailed, .launchFailed):
            return true
        default:
            return false
        }
    }
}

class calcProcess {
    var input: String
    var output: String
    var status: calcError?
    
    convenience init(_ args:Any...) {
        let arguments = args.map { (a:Any) -> String in
            String(describing:a)
        }
        self.init(arguments)
    }
    
    init(_ arguments: [String]) {
        input = "calc " + arguments.joined(separator: " ")
        
        let task = Process()
        let stdout = Pipe()
        task.standardOutput = stdout
        task.launchPath = calcPath
        task.arguments = arguments
        do {
            task.launch()
            if !task.isRunning {
                throw calcError.launchFailed
            }
        } catch _ {
            output = "<Failed to Launch>"
            status = calcError.launchFailed
            return
        }
        
        var timedOut = false
        DispatchQueue.main.asyncAfter(deadline: .now()+5.0) {
            timedOut = true
            task.terminate()
        }
        task.waitUntilExit()
        
        let data: Data = stdout.fileHandleForReading.readDataToEndOfFile()
        output = String(bytes: data, encoding: String.Encoding.utf8)!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        if (timedOut) {
            status = calcError.timeout
            output += "<Timed Out>"
        }
        else if (task.terminationStatus != 0) {
            status = calcError.exitStatus(task.terminationStatus)
        }
    }
}

class CalcTest: XCTestCase {
    func testParseInteger() {
        let n1 = randomSource.nextInt(upperBound:100)
        let task1 = calcProcess(n1)
        XCTAssertEqual(task1.output, String(n1), task1.input)
        
        let n2 = randomSource.nextInt(upperBound:100)
        let task2 = calcProcess("+\(n2)")
        XCTAssertEqual(task2.output, String(n2), task2.input)
        
        let n3 = -randomSource.nextInt(upperBound:100)
        let task3 = calcProcess(n3)
        XCTAssertEqual(task3.output, String(n3), task3.input)
        
        let task4 = calcProcess(0)
        XCTAssertEqual(task4.output, String(0), task4.input)
        
        let n5 = Int(Int32.max) - randomSource.nextInt(upperBound:1000)
        let task5 = calcProcess(n5)
        XCTAssertEqual(task5.output, String(n5), task5.input)
        
        let n6 = Int(Int32.min) + randomSource.nextInt(upperBound:1000)
        let task6 = calcProcess(n6)
        XCTAssertEqual(task6.output, String(n6), task6.input)
    }
    
    func testInvalidInput() {
        var task: calcProcess
        
        // valid input should not produce an error
        task = calcProcess(1, "+", 1)
        XCTAssertNil(task.status, "exit with zero status on valid input: \(task.input)")
        
        // expect out-of-bounds parsing to emit an error
        task = calcProcess("\(Int.max)\(randomSource.nextInt(upperBound:90)+10)")
        XCTAssertNotNil(task.status, "exit with nonzero status on invalid input: \(task.input)")
        XCTAssert(task.status != calcError.timeout, "exit with nonzero status on invalid input: \(task.input)")
        
        task = calcProcess("-\(Int.max)\(randomSource.nextInt(upperBound:90)+10)")
        XCTAssertNotNil(task.status, "exit with nonzero status on invalid input: \(task.input)")
        XCTAssert(task.status != calcError.timeout, "exit with nonzero status on invalid input: \(task.input)")
        
        // various invalid things
        task = calcProcess("x")
        XCTAssertNotNil(task.status, "exit with nonzero status on invalid input: \(task.input)")
        XCTAssert(task.status != calcError.timeout, "exit with nonzero status on invalid input: \(task.input)")
        
        task = calcProcess("10101", "10110")
        XCTAssertNotNil(task.status, "exit with nonzero status on invalid input: \(task.input)")
        XCTAssert(task.status != calcError.timeout, "exit with nonzero status on invalid input: \(task.input)")
        
        task = calcProcess("33", "-")
        XCTAssertNotNil(task.status, "exit with nonzero status on invalid input: \(task.input)")
        XCTAssert(task.status != calcError.timeout, "exit with nonzero status on invalid input: \(task.input)")
        
        task = calcProcess("66", "-6")
        XCTAssertNotNil(task.status, "exit with nonzero status on invalid input: \(task.input)")
        XCTAssert(task.status != calcError.timeout, "exit with nonzero status on invalid input: \(task.input)")
        
        task = calcProcess("3.1", "-4", "xyz")
        XCTAssertNotNil(task.status, "exit with nonzero status on invalid input: \(task.input)")
        XCTAssert(task.status != calcError.timeout, "exit with nonzero status on invalid input: \(task.input)")
        
        task = calcProcess("2", "+", "n")
        XCTAssertNotNil(task.status, "exit with nonzero status on invalid input: \(task.input)")
        XCTAssert(task.status != calcError.timeout, "exit with nonzero status on invalid input: \(task.input)")
        
        task = calcProcess("50%", "+", "25%")
        XCTAssertNotNil(task.status, "exit with nonzero status on invalid input: \(task.input)")
        XCTAssert(task.status != calcError.timeout, "exit with nonzero status on invalid input: \(task.input)")
        
        task = calcProcess("3", "x", "4.5.6")
        XCTAssertNotNil(task.status, "exit with nonzero status on invalid input: \(task.input)")
        XCTAssert(task.status != calcError.timeout, "exit with nonzero status on invalid input: \(task.input)")
        
        task = calcProcess("7", "foo", "8")
        XCTAssertNotNil(task.status, "exit with nonzero status on invalid input: \(task.input)")
        XCTAssert(task.status != calcError.timeout, "exit with nonzero status on invalid input: \(task.input)")
        
        task = calcProcess("12", "x", "/", "2")
        XCTAssertNotNil(task.status, "exit with nonzero status on invalid input: \(task.input)")
        XCTAssert(task.status != calcError.timeout, "exit with nonzero status on invalid input: \(task.input)")
        
        task = calcProcess("12", "+")
        XCTAssertNotNil(task.status, "exit with nonzero status on invalid input: \(task.input)")
        XCTAssert(task.status != calcError.timeout, "exit with nonzero status on invalid input: \(task.input)")
        
        task = calcProcess("12", "++", "12")
        XCTAssertNotNil(task.status, "exit with nonzero status on invalid input: \(task.input)")
        XCTAssert(task.status != calcError.timeout, "exit with nonzero status on invalid input: \(task.input)")
    }
    
    func testAdd() {
        var task: calcProcess
        let n1 = randomSource.nextInt(upperBound:100)
        let n2 = randomSource.nextInt(upperBound:100)
        let n3 = randomSource.nextInt(upperBound:100)-100
        let n4 = randomSource.nextInt(upperBound:100)-100
        
        task = calcProcess(n1, "+", n2)
        XCTAssertEqual(task.output, String(n1 + n2), task.input)
        
        task = calcProcess(n1, "+", "+\(n2)")
        XCTAssertEqual(task.output, String(n1 + n2), task.input)
        
        task = calcProcess(n1, "+", n3)
        XCTAssertEqual(task.output, String(n1 + n3), task.input)
        
        task = calcProcess(n1, "+", n4)
        XCTAssertEqual(task.output, String(n1 + n4), task.input)
        
        task = calcProcess(n2, "+", n3)
        XCTAssertEqual(task.output, String(n2 + n3), task.input)
        
        task = calcProcess(n3, "+", n4)
        XCTAssertEqual(task.output, String(n3 + n4), task.input)
        
        task = calcProcess(n4, "+", n1)
        XCTAssertEqual(task.output, String(n4 + n1), task.input)
        
        task = calcProcess(n1, "+", n2, "+", n3, "+", n4)
        XCTAssertEqual(task.output, String(n1 + n2 + n3 + n4), task.input)
    }

    func testAddExtended() {
        var task: calcProcess
        
        var nums: [Int] = []
        var args: [String] = []
        for _ in 0...20 {
            let n = randomSource.nextInt(upperBound:10000) - 50000
            nums.append(n)
            if args.count > 0 {
                args.append("+")
            }
            args.append(String(n))
        }
        let sum: Int = nums.reduce(0) { (a: Int, b: Int) -> Int in
            a + b
        }
        task = calcProcess(args)
        XCTAssertEqual(task.output, String(sum), task.input)
    }

    func testSubtract() {
        var task: calcProcess
        let n1 = randomSource.nextInt(upperBound:100)
        let n2 = randomSource.nextInt(upperBound:100)
        let n3 = randomSource.nextInt(upperBound:100)-100
        let n4 = randomSource.nextInt(upperBound:100)-100
        
        task = calcProcess(n1, "-", n2)
        XCTAssertEqual(task.output, String(n1 - n2), task.input)
        
        task = calcProcess(n1, "-", n3)
        XCTAssertEqual(task.output, String(n1 - n3), task.input)
        
        task = calcProcess(n1, "-", n4)
        XCTAssertEqual(task.output, String(n1 - n4), task.input)
        
        task = calcProcess(n2, "-", n3)
        XCTAssertEqual(task.output, String(n2 - n3), task.input)
        
        task = calcProcess(n3, "-", n4)
        XCTAssertEqual(task.output, String(n3 - n4), task.input)
        
        task = calcProcess(n4, "-", n1)
        XCTAssertEqual(task.output, String(n4 - n1), task.input)
        
        task = calcProcess(n1, "-", n2, "-", n3, "-", n4)
        XCTAssertEqual(task.output, String(n1 - n2 - n3 - n4), task.input)
        
        var nums: [Int] = []
        var args: [String] = []
        for _ in 0...20 {
            let n = randomSource.nextInt(upperBound:10000) - 5000
            nums.append(n)
            if args.count > 0 {
                args.append("-")
            }
            args.append(String(n))
        }
        let sum: Int = nums[1...].reduce(nums[0]) { (a: Int, b: Int) -> Int in
            a - b
        }
        task = calcProcess(args)
        XCTAssertEqual(task.output, String(sum), task.input)
    }

    
    func testSubtractExtended() {
        var task: calcProcess
        
        var nums: [Int] = []
        var args: [String] = []
        for _ in 0...20 {
            let n = randomSource.nextInt(upperBound:10000) - 5000
            nums.append(n)
            if args.count > 0 {
                args.append("-")
            }
            args.append(String(n))
        }
        let sum: Int = nums[1...].reduce(nums[0]) { (a: Int, b: Int) -> Int in
            a - b
        }
        task = calcProcess(args)
        XCTAssertEqual(task.output, String(sum), task.input)
    }



    func testMultiply() {
        var task: calcProcess
        let n1 = randomSource.nextInt(upperBound:100)+1
        let n2 = randomSource.nextInt(upperBound:100)+1
        let n3 = randomSource.nextInt(upperBound:100)-101
        
        task = calcProcess(n1, "x", n2)
        XCTAssertEqual(task.output, String(n1 * n2), task.input)
        
        task = calcProcess(n1, "x", n3)
        XCTAssertEqual(task.output, String(n1 * n3), task.input)
        
        task = calcProcess(n3, "x", n2)
        XCTAssertEqual(task.output, String(n3 * n2), task.input)
        
        task = calcProcess(n1, "x", n2, "x", n3)
        XCTAssertEqual(task.output, String(n1 * n2 * n3), task.input)
    }
    
    func testMultiplyExtended() {
        var task: calcProcess
        
        var nums: [Int] = []
        var args: [String] = []
        for _ in 0...10 {
            let n = randomSource.nextInt(upperBound:20)+1
            nums.append(n)
            if args.count > 0 {
                args.append("x")
            }
            args.append(String(n))
        }
        let sum: Int = nums.reduce(1) { (a: Int, b: Int) -> Int in
            a * b
        }
        task = calcProcess(args)
        XCTAssertEqual(task.output, String(sum), task.input)
    }
    
    
    func testDivide() {
        var task: calcProcess
        let n1 = randomSource.nextInt(upperBound:4096) + 300
        let n2 = randomSource.nextInt(upperBound:256) + 20
        let n3 = randomSource.nextInt(upperBound:16) + 1
        
        task = calcProcess(n1, "/", n2)
        XCTAssertEqual(task.output, String(n1 / n2), task.input)
        
        task = calcProcess(n2, "/", n3)
        XCTAssertEqual(task.output, String(n2 / n3), task.input)
        
        task = calcProcess(n1, "/", -n3)
        XCTAssertEqual(task.output, String(n1 / -n3), task.input)
        
        task = calcProcess(n1, "/", n2, "/", n3)
        XCTAssertEqual(task.output, String(n1 / n2 / n3), task.input)
    }
    
    func testModulus() {
        let n1 = randomSource.nextInt(upperBound:100) + 20
        let n2 = randomSource.nextInt(upperBound:20) + 1
        let task = calcProcess(n1, "%", n2)
        XCTAssertEqual(task.output, String(n1 % n2), task.input)
    }
    
    func testDivideByZero() {
        let task0 = calcProcess(0, "/", 1)
        XCTAssertEqual(task0.output, String(0), task0.input)
        XCTAssertNil(task0.status, "exit with zero status: \(task0.input)")
        
        let n1 = randomSource.nextInt(upperBound:100) + 1
        let task1 = calcProcess(n1, "/", 0)
        XCTAssertNotNil(task1.status, "exit with nonzero status when dividing by zero: \(task1.input)")
        XCTAssert(task1.status != calcError.timeout, "exit with nonzero status when dividing by zero: \(task1.input)")
        
        let n2 = randomSource.nextInt(upperBound:100) + 1
        let task2 = calcProcess(n2, "%", 0)
        XCTAssertNotNil(task2.status, "exit with nonzero status when dividing by zero: \(task2.input)")
        XCTAssert(task2.status != calcError.timeout, "exit with nonzero status when dividing by zero: \(task2.input)")
    }
    
    func testAddSubtract() {
        let n1 = randomSource.nextInt(upperBound:100)
        let n2 = randomSource.nextInt(upperBound:100)
        let n3 = randomSource.nextInt(upperBound:100)
        let task1 = calcProcess(n1, "+", n2, "-", n3)
        XCTAssertEqual(task1.output, String(n1 + n2 - n3), task1.input)
        
        let n4 = randomSource.nextInt(upperBound:200)-100
        let n5 = randomSource.nextInt(upperBound:200)-100
        let n6 = randomSource.nextInt(upperBound:200)-100
        let n7 = randomSource.nextInt(upperBound:200)-100
        let n8 = randomSource.nextInt(upperBound:200)-100
        let n9 = randomSource.nextInt(upperBound:200)-100
        let task2 = calcProcess(n4, "-", n5, "-", n6, "+", n7, "-", n8, "+", n9)
        XCTAssertEqual(task2.output, String(n4 - n5 - n6 + n7 - n8 + n9), task2.input)
    }
    
    func testMultDivide() {
        // verify that same-precedence is evaluated left-to-right
        let n1 = randomSource.nextInt(upperBound:50) + 5
        let n2 = randomSource.nextInt(upperBound:50) + 5
        let n3 = randomSource.nextInt(upperBound:20) + 1
        let task1 = calcProcess(n1, "x", n2, "/", n3)
        XCTAssertEqual(task1.output, String(n1 * n2 / n3), task1.input)
        
        // verify that same-precedence is evaluated left-to-right
        let n4 = randomSource.nextInt(upperBound:50) + 5
        let n5 = randomSource.nextInt(upperBound:50) + 5
        let n6 = randomSource.nextInt(upperBound:20) + 1
        let task2 = calcProcess(n4, "x", n5, "%", n6)
        XCTAssertEqual(task2.output, String(n4 * n5 % n6), task2.input)
        
        // note: these ops are not the same predence in all languages
        let n7 = randomSource.nextInt(upperBound:50) + 40
        let n8 = randomSource.nextInt(upperBound:20) + 20
        let n9 = randomSource.nextInt(upperBound:20) + 1
        let task3 = calcProcess(n7, "%", n8, "/", n9)
        XCTAssertEqual(task3.output, String((n7 % n8) / n9), task3.input)
    }
    
    func testPrecedence1() {
        // verify that multiplication is evaluated before addition
        let n1 = randomSource.nextInt(upperBound:100) + 1
        let n2 = randomSource.nextInt(upperBound:100) + 1
        let n3 = randomSource.nextInt(upperBound:100) + 1
        
        let task1 = calcProcess(n1, "x", n2, "+", n3)
        XCTAssertEqual(task1.output, String(n1 * n2 + n3), task1.input)
        
        let task2 = calcProcess(n1, "+", n2, "x", n3)
        XCTAssertEqual(task2.output, String(n1 + n2 * n3), task2.input)
    }
    
    func testPrecedence2() {
        // verify that division is evaluated before addition or subtraction
        let n4 = randomSource.nextInt(upperBound:100) + 1
        let n5 = randomSource.nextInt(upperBound:20) + 20
        let n6 = randomSource.nextInt(upperBound:20) + 1
        let n7 = randomSource.nextInt(upperBound:100) + 1
        let task3 = calcProcess(n4, "+", n5, "/", n6, "-", n7)
        XCTAssertEqual(task3.output, String(n4 + n5 / n6 - n7), task3.input)
        
        let n8 = randomSource.nextInt(upperBound:10)
        let n9 = randomSource.nextInt(upperBound:10)
        // ((7/3) * 5) % 3
        let n10 = 7
        let n11 = 3
        let n12 = 5
        let n13 = 3
        let task4 = calcProcess(n8, "-", n9, "+", n10, "/", n11, "x", n12, "%", n13)
        XCTAssertEqual(task4.output, String(n8 - n9 + (((n10/n11) * n12) % n13)), task4.input)
        
        // 1 + 2 + 3 x 4 / 2 + 5 + 6 / 2 x 7 + 8
        let expected = 1 + 2 + ((3 * 4) / 2) + 5 + ((6 / 2) * 7) + 8
        let task6 = calcProcess(1, "+", 2, "+", 3, "x", 4, "/", 2, "+", 5, "+", 6, "/", 2, "x", 7, "+", 8)
        XCTAssertEqual(task6.output, String(expected), task6.input)
    }

    func testOutOfBounds() {
        let support64bit = (calcProcess(Int.max).output == String(Int.max))
        var min = Int.min
        var max = Int.max
        if (!support64bit) {
            min = Int(Int32.min)
            max = Int(Int32.max)
        }
        // test additive overflow
        let n1 = max - randomSource.nextInt(upperBound:50)
        let n2 = randomSource.nextInt(upperBound:100) + 60
        let task1 = calcProcess(n1, "+", n2)
        XCTAssertNotNil(task1.status, "Error on integer overflow: \(task1.input)")
        XCTAssert(task1.status != calcError.timeout, "Error on integer overflow: \(task1.input)")
        
        let task2 = calcProcess(n1, "-", -n2)
        XCTAssertNotNil(task2.status, "Error on integer overflow: \(task2.input)")
        XCTAssert(task2.status != calcError.timeout, "Error on integer overflow: \(task2.input)")
        
        // test additive underflow
        let n3 = min + randomSource.nextInt(upperBound:50)
        let n4 = randomSource.nextInt(upperBound:100) + 60
        let task3 = calcProcess(n3, "-", n4)
        XCTAssertNotNil(task3.status, "Error on integer underflow: \(task3.input)")
        let task4 = calcProcess(n3, "+", -n4)
        XCTAssertNotNil(task4.status, "Error on integer underflow: \(task4.input)")
        
        // test multiplicative overflow
        let n5 = Int(Int32.max) - randomSource.nextInt(upperBound:100)
        let n6 = Int(Int32.max) - randomSource.nextInt(upperBound:100)
        let n7 = Int(Int32.max) - randomSource.nextInt(upperBound:100)
        let task5 = calcProcess(n5, "x", n6, "x", n7)
        XCTAssertNotNil(task5.status, "Error on integer overflow: \(task5.input)")
        
        let task6 = calcProcess(-n5, "x", n6, "x", n7)
        XCTAssertNotNil(task6.status, "Error on integer underflow: \(task6.input)")
    }
}


