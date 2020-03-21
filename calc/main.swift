import Foundation

let consoleIO = ConsoleIO()
let calculator = Calculator()
if CommandLine.argc < 4 {
  //TODO: Handle interactive mode
    print("Inputed parameters must have at least 2 numbers and one operator")
    consoleIO.printUsage()
} else {
    calculator.CheckParametersInput()
}
