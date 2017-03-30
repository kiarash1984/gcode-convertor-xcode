//
//  Vector.swift
//  G-Code Convertor
//
//  Created by Kiarash on 3/16/17.
//  Copyright © 2017 NeshaGostar Pardis Co. All rights reserved.
//

import Foundation

var resolution: Double = 0.5

extension Double {
    func format(f: String) -> String {
        return String(format: "%\(f).2f", self)
    }
}

enum Axis {
    case X
    case Y
}

class Point {
    
    // MARK: -
    // MARK: Private variables
    
    var x: Double!
    var y: Double!
    
    init(xValue: Double, yValue: Double) {
        
        x = xValue
        y = yValue
    }
    
    class func calculateRadius(point: Point) -> Double {
        return sqrt(pow(point.x, 2.0) + pow(point.y, 2.0))
    }

}


class Vector {
    
    // MARK: - 
    // MARK: Private variables
    var i: Double!
    var j: Double!
    
    init(iValue: Double, jValue: Double, reverse: Bool = false) {
        
        i = (reverse == false ? iValue : -iValue)
        j = (reverse == false ? jValue : -jValue)
    }
    
    private class func generateVectorForAxis(axis: Axis) -> Vector {
        return Vector(iValue: (axis == .X ? 1.0 : 0.0), jValue: (axis == .X ? 0.0 : 1.0))
    }
    
    class func addVectors(vectors: [Vector]) -> Vector {
        let tempVector = Vector(iValue: 0.0, jValue: 0.0)
        for vector in vectors {
            tempVector.i = tempVector.i + vector.i
            tempVector.j = tempVector.j + vector.j
        }
        return tempVector
    }
    
    class func subtractVectors(vectorD: Vector, vectorB: Vector) -> Vector {
        return Vector(iValue: vectorD.i - vectorB.i, jValue: vectorD.j - vectorB.j)
    }
    
    class func getAngle(vectorA: Vector, axis: Axis) -> Double {
        let vectorB = Vector.generateVectorForAxis(axis: axis)
        let nominator = (vectorA.i * vectorB.i + vectorA.j * vectorB.j)
        let down = sqrt(pow(vectorA.i, 2.0) + pow(vectorA.j, 2.0))
        return acos(nominator / down)
    }
    
    class func getAngle(vectorA: Vector, vectorB: Vector) -> Double {
        let zarb = vectorA.i * vectorB.i + vectorA.j * vectorB.j
        let lengthA = sqrt(pow(vectorA.i, 2.0) + pow(vectorA.j, 2.0))
        let lengthB = sqrt(pow(vectorB.i, 2.0) + pow(vectorB.j, 2.0))
        var result = zarb / (lengthA * lengthB)
        if result > 1.0 {
            result = 1.0
        }
        if result < -1.0 {
            result = -1.0
        }
        
        
        
        return acos(result)
        
    }
    
    class func getPointsForRotation(vectorD: Vector, distVector: Vector, radius: Double, angle: Double) -> Point {
        let newVector = Vector(iValue: distVector.i * cos(angle) - distVector.j * sin(angle),
                               jValue: distVector.i * sin(angle) + distVector.j * cos(angle))
//        return Point(xValue: acos(newVector.i / radius) + initialAddToTranslationVector.i,
//                     yValue: asin(newVector.j / radius) + initialAddToTranslationVector.j)
        let xValue = sin(atan(newVector.j / newVector.i)) * radius + vectorD.j
        let yValue = cos(atan(newVector.j / newVector.i)) * radius + vectorD.i
        return Point(xValue: xValue,
                     yValue: yValue)
    }
    
    class func getPointsForRotation(vectorD: Vector, angle: Double, radius: Double) -> Point {
        
        return Point(xValue: radius * cos(angle) + vectorD.i,
                     yValue: radius * sin(angle) + vectorD.j)
    }
    
    class func checkIfConvertNecessary(vectorA: Vector, vectorB: Vector) -> Bool {
        let distance = sqrt(pow(vectorA.i - vectorB.i, 2.0) + pow(vectorA.j - vectorB.j, 2.0))
        return (distance > resolution)
    }
}
