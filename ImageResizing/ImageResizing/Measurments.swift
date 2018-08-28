//
//  Measurments.swift
//  ImageResizing
//
//  Created by Eugene Bokhan on 27/08/2018.
//  Copyright © 2018 Eugene Bokhan. All rights reserved.
//

import Foundation

public func measure <T> (_ f: @autoclosure () -> T) -> (result: T, duration: String) {
    let startTime = CFAbsoluteTimeGetCurrent()
    let result = f()
    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
    let formattedTimeString = String(format: "%.00004f", timeElapsed)
    return (result, "\(formattedTimeString) sec.")
}
