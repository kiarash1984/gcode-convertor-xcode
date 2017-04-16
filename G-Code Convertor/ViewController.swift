//
//  ViewController.swift
//  G-Code Convertor
//
//  Created by Kiarash on 3/5/17.
//  Copyright © 2017 NeshaGostar Pardis Co. All rights reserved.
//

import Cocoa


class ArcCode {
    
    // Type 0 -> CW
    // Type 1 -> CCW
    
    var xValue: Float
    var yValue: Float
    var iValue: Float
    var jValue: Float
    var type: Int
    
    init(withXValue: Float, andYValue: Float, andIValue: Float, andJValue: Float, andType: Int)
    {
        xValue = withXValue
        yValue = andYValue
        iValue = andIValue
        jValue = andJValue
        type = andType
    }
}

class CNCCommand {
    
    var type: String
    var xValue: Float?
    var yValue: Float?
    var zValue: Float?
    var iValue: Float?
    var jValue: Float?

    
    init(withType: String, andXValue: Float?, andYValue: Float?, andZValue: Float?, andIValue: Float?, andJValue: Float?)
    {
        type = withType
        xValue = andXValue
        yValue = andYValue
        zValue = andZValue
        iValue = andIValue
        jValue = andJValue
    }
}

class ViewController: NSViewController {
    
    @IBOutlet weak var lblmaxX: NSTextField!
    @IBOutlet weak var lblminY: NSTextField!
    @IBOutlet weak var lblminX: NSTextField!
    @IBOutlet weak var lblmaxY: NSTextField!
    @IBOutlet weak var lblWidth: NSTextField!
    @IBOutlet weak var lblHeight: NSTextField!
    
    
    @IBOutlet weak var stockWidth: NSTextField!
    @IBOutlet weak var stockHeight: NSTextField!
    @IBOutlet weak var enableScale: NSButton!
    @IBOutlet weak var feedrateSpeed: NSTextField!
    
    @IBOutlet weak var btnConvert: NSButtonCell!
    
    var globalMin: Point?
    var globalMax: Point?
    
    var gcodeHeight: Double?
    var gcodeWidth: Double?
    
    var scaleFactor = Double(1.0)
    var translationSpeed = Double(300.0)
    
    var bScale = false
    private var pathOfFile: String?
    private var currentX: Float?
    private var currentY: Float?
    
    private var tempArcCode: ArcCode?
    
    private var step = Double(2.0)
    
    var convertedCode = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    @IBAction func scaleStateChanged(_ sender: Any) {
        bScale = !bScale
    }
    
    private func getValueInCommand(withCommand: String, value: String) -> Float?
    {
        var output = String()
        let digits = CharacterSet.decimalDigits
        let characters = CharacterSet.letters
        
        if let indexOfValue = withCommand.range(of: value)?.lowerBound {

            let subString = withCommand.substring(from: indexOfValue)
            
            for char in subString.unicodeScalars {
                if (char == " " || char.description == value) {
                    continue
                }
                if characters.contains(char) {
                    break
                }
                if (char == ".") {
                    output += "."
                    continue
                }
                if (char == "-") {
                    output += "-"
                    continue
                }
                if digits.contains(char) {
                    output += char.description
                    continue
                }
                
            }
            if let fOut = Float(output) {
                if value == "Z" {
                    return fOut
                }
                return fOut * Float(scaleFactor)
            }
            return Float(output)
        }
        return nil
    }
    
    private func saveToFile()
    {
        var path = pathOfFile!
        var tempPath: [String] = path.components(separatedBy: ".")
        if (tempPath.count != 2) { return}
        path = tempPath[0] + "-Converted." + tempPath[1]
        let path2 = URL(fileURLWithPath: path)
        
        do {
            try convertedCode.write(to: path2, atomically: false, encoding: String.Encoding.utf8)
        }
        catch {/* error handling here */}
    }
    
    @IBAction func selectFileClicked(_ sender: Any)
    {
        let dialog = NSOpenPanel();
        
        dialog.title                   = "Choose a G-Code file";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = true;
        dialog.canCreateDirectories    = true;
        dialog.allowsMultipleSelection = false;
        //        dialog.allowedFileTypes        = ["txt"];
        
        if (dialog.runModal() == NSModalResponseOK) {
            let result = dialog.url // Pathname of the file
            
            if (result != nil) {
                if let path = result?.path
                {
                    pathOfFile = path
//                    newFUNC(pathOfFile: path)
                    
                    let x = getDimensions(pathOfFile: path)
                    globalMax = x.max
                    globalMin = x.min
                    btnConvert.isEnabled = true
//                    readGcodeFile(path: path)
                }
            }
        } else {
            // User clicked on "Cancel"
            return
        }
        
    }
    @IBAction func convert(_ sender: Any) {
        if stockWidth.stringValue != "" && stockHeight.stringValue != "" && bScale {
            let dStockHeight = Double(stockHeight.stringValue)
            let dStockWidth = Double(stockWidth.stringValue)
            let xDif = dStockWidth! - gcodeWidth!
            let yDif = dStockHeight! - gcodeHeight!
            if xDif < 0.0 && yDif < 0 {
                if xDif < yDif {
                    scaleFactor = dStockHeight! / gcodeHeight!
                } else {
                    scaleFactor = dStockWidth! / gcodeWidth!
                }
                
            } else if xDif < 0.0 && yDif > 0.0 {
                scaleFactor = dStockWidth! / gcodeWidth!
            } else if yDif < 0.0 && xDif > 0.0 {
                scaleFactor = dStockHeight! / gcodeHeight!
            }
        }
        if let speed = Double(feedrateSpeed.stringValue) {
            if speed != 0.0 {
                translationSpeed = speed
            }
        }
        newFUNC(pathOfFile: pathOfFile!)
    }
    
    private func getDimensions(pathOfFile: String) -> (min: Point,max: Point) {
        var minX = Float(0.0)
        var maxX = Float(0.0)
        var minY = Float(0.0)
        var maxY = Float(0.0)
        do {
            let data = try String(contentsOfFile: pathOfFile, encoding: .utf8)
            let linesOfCode = data.components(separatedBy: .newlines)
            
            for currentLine in linesOfCode {
                if (currentLine == "") { continue }
//                print("Current Code = \(currentLine)")
                if let command = saveNCCommandElements(command: currentLine) {
                    if let tempX = command.xValue {
                        if minX > tempX {
                            minX = tempX
                        }
                        if maxX < tempX {
                            maxX = tempX
                        }
                    }
                    if let tempY = command.yValue {
                        if minY > tempY {
                            minY = tempY
                        }
                        if maxY < tempY {
                            maxY = tempY
                        }
                    }
                }
            }
            
        } catch {
            print(error)
        }
        lblmaxX.stringValue = NSString(format: "%.3f", maxX) as String
        lblmaxY.stringValue = NSString(format: "%.3f", maxY) as String
        lblminX.stringValue = NSString(format: "%.3f", minX) as String
        lblminY.stringValue = NSString(format: "%.3f", minY) as String
        
        let width = fabs(minX - maxX)
        let height = fabs(minY - maxY)
        
        gcodeWidth = Double(width)
        gcodeHeight = Double(height)
        
        lblWidth.stringValue = NSString(format: "%.3f", width) as String
        lblHeight.stringValue = NSString(format: "%.3f", height) as String
        
        return (Point(xValue: Double(minX), yValue: Double(minY)), Point(xValue: Double(maxX), yValue: Double(maxY)))
    }
    
    private func newFUNC(pathOfFile: String) {
        do {
            let data = try String(contentsOfFile: pathOfFile, encoding: .utf8)
            let linesOfCode = data.components(separatedBy: .newlines)
            
            for currentLine in linesOfCode {
                if (currentLine == "") { continue }
                print("Current Code = \(currentLine)")
                if let command = saveNCCommandElements(command: currentLine) {
                    if (command.type != "G2" && command.type != "G3") {
                        writeNormalCNCCommandToText(command: command)
                    } else {
                        convertNEW(command: command)
                    }
                }
            }
            saveToFile()
            
        } catch {
            print(error)
        }
    }
    
    private func saveNCCommandElements(command: String) -> CNCCommand? {
        var type = String()
        var xValue : Float?
        var yValue : Float?
        var zValue : Float?
        var iValue : Float?
        var jValue : Float?
        
        if (command.components(separatedBy: "G0").count == 2) {
            type = "G0"
        } else if (command.components(separatedBy: "G1").count == 2) {
            type = "G1"
        } else if (command.components(separatedBy: "G2").count == 2) {
            type = "G2"
        } else if (command.components(separatedBy: "G3").count == 2) {
            type = "G3"
        } else {
            return nil
        }
        
        xValue = getValueInCommand(withCommand: command, value: "X")
        yValue = getValueInCommand(withCommand: command, value: "Y")
        zValue = getValueInCommand(withCommand: command, value: "Z")
        iValue = getValueInCommand(withCommand: command, value: "I")
        jValue = getValueInCommand(withCommand: command, value: "J")
        
        return CNCCommand(withType: type,
                          andXValue: xValue,
                          andYValue: yValue,
                          andZValue: zValue,
                          andIValue: iValue,
                          andJValue: jValue)
    }
    
    private func writeNormalCNCCommandToText(command: CNCCommand) {
        
        convertedCode += "\(command.type)\((command.xValue == nil ? "" : " X\(command.xValue!)"))\((command.yValue == nil ? "" : " Y\(command.yValue!)"))\((command.zValue == nil ? "" : " Z\(command.zValue!)")) F \(translationSpeed)\n"

        
 //       print("Converted Simple:")

 //       print("\(command.type)\((command.xValue == nil ? "" : " X\(command.xValue!)"))\((command.yValue == nil ? "" : " Y\(command.yValue!)"))\((command.zValue == nil ? "" : " Z\(command.zValue!)"))")
        
        if (command.xValue != nil) {
            currentX = command.xValue!
        }
        if (command.yValue != nil) {
            currentY = command.yValue!
        }
    }
    
    private func convertNEW(command: CNCCommand)
    {
        
//        if currentX == nil { currentX = 0.0 }
//        if currentY == nil { currentY = 0.0 }
        
        let vectorA = Vector(iValue: Double(currentX!), jValue: Double(currentY!))
        let vectorB = Vector(iValue: Double(command.xValue!), jValue: Double(command.yValue!))
        let translationVector = Vector(iValue: Double(command.iValue!), jValue: Double(command.jValue!), reverse: true)
        let iVector = Vector(iValue: Double(command.iValue!), jValue: Double(command.jValue!))
        let vectorD = Vector.addVectors(vectors: [vectorA, iVector])
        let vectorE = Vector(iValue: vectorB.i - vectorD.i, jValue: vectorB.j - vectorD.j)
        
        
        var startPhi = Vector.getAngle(vectorA: translationVector, axis: .X)
        
        if translationVector.j < 0 {
            startPhi = -startPhi
        }
        
        var endPhi = Vector.getAngle(vectorA: translationVector, vectorB: vectorE)
        
        if command.type == "G2" {
//            endPhi = startPhi - endPhi
            endPhi = startPhi + endPhi
        } else {
//            endPhi = startPhi + endPhi
            endPhi = startPhi - endPhi
        }
        /*
        if vectorE.j < 0 {
            endPhi = -endPhi
        }
        */
        
        print("startPhi = \(startPhi * 180.0 / .pi)")
        print("endPhi = \(endPhi * 180.0 / .pi)")
        
        let radius = Point.calculateRadius(point: Point(xValue: Double(command.iValue!), yValue: Double(command.jValue!)))
        if Vector.checkIfConvertNecessary(vectorA: Vector(iValue: Double(currentX!), jValue: Double(currentY!)), vectorB: vectorB) == true {
            
            var step = fabs(startPhi - endPhi) / 3.0
            if fabs(startPhi - endPhi) < 0.5 {
                step = 1.0
            }
            
            if command.type == "G3" {
                while startPhi > endPhi  {
                    startPhi -= step
                    if startPhi > endPhi {
                        let point = Vector.getPointsForRotation(vectorD: vectorD, angle: startPhi, radius: radius)

                        self.convertedCode = self.convertedCode + "G1 X\(point.x!) Y\(point.y!) F \(translationSpeed)\n"
                        currentX = Float(point.x)
                        currentY = Float(point.y)
                        print("converted code = G1 X\(point.x) Y\(point.y)\n")
                    } else {
                        self.convertedCode = self.convertedCode + "G1 X\(command.xValue!) Y\(command.yValue!) F \(translationSpeed)\n"
                        currentX = Float(command.xValue!)
                        currentY = Float(command.yValue!)
                        print("converted code = G1 X\(command.xValue!) Y\(command.yValue!)\n")
                    }
                    
                }
                
            } else if command.type == "G2" {
                while startPhi < endPhi  {
                    startPhi += step
                    if startPhi < endPhi {
                        let point = Vector.getPointsForRotation(vectorD: vectorD, angle: startPhi, radius: radius)
                        
                        self.convertedCode = self.convertedCode + "G1 X\(point.x!) Y\(point.y!) F \(translationSpeed)\n"
                        currentX = Float(point.x)
                        currentY = Float(point.y)
                        print("converted code = G1 X\(point.x) Y\(point.y)\n")
                    } else {
                        self.convertedCode = self.convertedCode + "G1 X\(command.xValue!) Y\(command.yValue!) F \(translationSpeed)\n"
                        currentX = Float(command.xValue!)
                        currentY = Float(command.yValue!)
                        print("converted code = G1 X\(command.xValue!) Y\(command.yValue!)\n")
                    }
                }

            }
        } else {
            self.convertedCode = self.convertedCode + "G1 X\(command.xValue!) Y\(command.yValue!) F \(translationSpeed)\n"
            currentX! = command.xValue!
            currentY! = command.yValue!
        }
        
    }

}

