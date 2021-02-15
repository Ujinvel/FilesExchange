//
//  ConsoleIO.swift
//  FilesExchange
//
//  Created by Evgeny Velichko on 12.02.2021.
//

import Foundation

enum OutputType {
    case error
    case standard
}

class ConsoleIO {
  func writeMessage(_ message: String, to: OutputType = .standard) {
    switch to {
    case .standard:
      print(message)
    case .error:
      fputs("\u{001B}0;31m\(message)\n", stderr)
    }
  }
    
  func getInput() -> String {
    let keyboard = FileHandle.standardInput
    let inputData = keyboard.availableData
    let strData = String(data: inputData, encoding: String.Encoding.utf8)
    
    return strData?.trimmingCharacters(in: CharacterSet.newlines) ?? ""
  }
}


