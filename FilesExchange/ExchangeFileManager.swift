//
//  ExchangeFileManager.swift
//  FilesExchange
//
//  Created by Evgeny Velichko on 12.02.2021.
//

import Foundation

final class ExchangeFileManager {
    
    private enum C {
        static let indexesFileName = "Indexes.txt"
        static let outputDirectoryFileName = "Zip"
    }
    
    // MARK: - Properties
    
    private let consoleIO = ConsoleIO()
    private let fileManager = FileManager.default
    
    // MARK: - Operations
    
    private func loadIndexes(from urlPath: URL) -> [Index] {
        if fileManager.fileExists(atPath: urlPath.path) {
            do {
                return try JSONDecoder().decode([Index].self, from: try Data(contentsOf: urlPath, options: .mappedIfSafe))
            } catch {
                print(error)
            }
        }
        
        return []
    }
    
    private func createIndexes(from urlPath: URL,
                               fileExtension: String) -> [Index]
    {
        var indexes: [Index] = []
        
        if let enumerator = fileManager.enumerator(at: urlPath,
                                                   includingPropertiesForKeys: [.isRegularFileKey],
                                                   options: [.skipsHiddenFiles,
                                                             .skipsPackageDescendants])
        {
            for case let fileURL as URL in enumerator {
                do {
                    let fileAttributes = try fileURL.resourceValues(forKeys:[.isRegularFileKey])
                    
                    let name = (fileURL.path as NSString).lastPathComponent
                    if fileAttributes.isRegularFile! && name.contains(fileExtension) {
                        indexes.append(.init(name: name,
                                             url: fileURL))
                    }
                } catch {
                    print(error, fileURL)
                }
            }
        }
        
        return indexes
    }
    
    private func persistIndexes(_ indexes: [Index], to urlPath: URL) {
        guard !indexes.isEmpty else { return }
        
        let encoder = JSONEncoder()
        
        do {
            let encoded = try encoder.encode(indexes)
            if let json = String(data: encoded, encoding: .utf8) {
                try json.write(to: urlPath,
                               atomically: true,
                               encoding: .utf8)
            }
        } catch {
            print(error)
        }
    }
    
    private func replaceFiles(indexes: [Index],
                              from zipPathURL: URL,
                              to inputPathURL: URL)
    {
        var count = 0
        indexes.forEach {
            let currentFilezipPath = inputPathURL.deletingLastPathComponent().appendingPathComponent("\(C.outputDirectoryFileName)/\($0.name)")
            if fileManager.fileExists(atPath: $0.url.path) &&
                fileManager.fileExists(atPath: currentFilezipPath.path) {
                do {
                    _ = try fileManager.replaceItemAt($0.url, withItemAt: currentFilezipPath)
                    
                    count += 1
                } catch {
                    print(error)
                }
            }
        }
        
        consoleIO.writeMessage("Total files replaced: \(count)")
    }
        
    private func createDirectory(at urPath: URL) {
        if !isDirectoryExist(at: urPath) {
            do {
                try fileManager.createDirectory(
                    at: urPath,
                    withIntermediateDirectories: false,
                    attributes: nil
                )
            } catch {
                print(error)
            }
        }
    }
    
    // MARK: Is directory
    
    private func isDirectoryEmpty(at url: URL) -> Bool {
        if let enumerator = fileManager.enumerator(at: url,
                                                   includingPropertiesForKeys: [.isRegularFileKey],
                                                   options: [.skipsHiddenFiles,
                                                             .skipsPackageDescendants])
        {
            var isEmpty = true
            for case _ as URL in enumerator {
                isEmpty = false
                break
            }
            
            return isEmpty
        }
        
        return true
    }
    
    private func isDirectoryExist(at url: URL) -> Bool {
        var isDir: ObjCBool = false
        
        return fileManager.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
    }
    
    private func extractFiles(from indexes: [Index],
                              splitCount: Int,
                              inputPath: URL,
                              to destinationURL: URL)
    {
        var duplicateIndexes: [Index] = []
        
        if splitCount > 0 {
            let count = Int(Double(indexes.count / splitCount))
            let chunked = indexes.chunked(into: count)
                    
            for i in 0...splitCount - 1 {
                let destinationURLi = inputPath.deletingLastPathComponent().appendingPathComponent(C.outputDirectoryFileName + "\(i + 1)")
                chunked[i].forEach {
                    let zipPath = destinationURLi.appendingPathComponent("\($0.name)")
                    
                    if !fileManager.fileExists(atPath: zipPath.path) {
                        do {
                            try fileManager.copyItem(at: $0.url, to: zipPath)
                        } catch {
                            print(error)
                        }
                    } else {
                        duplicateIndexes.append($0)
                    }
                }
            }
        }
        // all files
        indexes.forEach {
            let zipPath = destinationURL.appendingPathComponent("\($0.name)")

            if !fileManager.fileExists(atPath: zipPath.path) {
                do {
                    try fileManager.copyItem(at: $0.url, to: zipPath)
                } catch {
                    print(error)
                }
            } else {
                duplicateIndexes.append($0)
            }
        }
        
        consoleIO.writeMessage("duplicates count: \(duplicateIndexes.count)")
    }
    
    // MARK: - Execute

    func execute() {
        consoleIO.writeMessage("Enter path: ")
        
        let stringPath = consoleIO.getInput()
        
        consoleIO.writeMessage("Enter file extension: ")
        
        let fileExtension = consoleIO.getInput()
        
        consoleIO.writeMessage("Enter split count: ")
        
        let split = Int(consoleIO.getInput()) ?? 0
        let inputPath = URL(fileURLWithPath: stringPath)
        let indexesPath = inputPath.deletingLastPathComponent().appendingPathComponent(C.indexesFileName)
        let zipPathFull = inputPath.deletingLastPathComponent().appendingPathComponent(C.outputDirectoryFileName)
        let loadedIndexes = loadIndexes(from: indexesPath)
        let indexes = loadedIndexes.isEmpty ? createIndexes(from: inputPath, fileExtension: fileExtension) : loadedIndexes
        
        consoleIO.writeMessage("indexes: \(indexes.count)")
        
        guard !indexes.isEmpty else {
            consoleIO.writeMessage("can't create indexes. Check permissions")
            
            return
        }
        
        persistIndexes(indexes, to: indexesPath)

        if isDirectoryExist(at: zipPathFull) && !isDirectoryEmpty(at: zipPathFull) {
            replaceFiles(indexes: indexes, from: zipPathFull, to: inputPath)
            
            consoleIO.writeMessage("Success!")
        } else {
            // create Zip directory
            createDirectory(at: zipPathFull)
            if split > 0 {
                [Int](0...split - 1).forEach {
                    createDirectory(at: inputPath.deletingLastPathComponent().appendingPathComponent(C.outputDirectoryFileName + "\($0 + 1)"))
                }
            }

            extractFiles(from: indexes,
                         splitCount: split,
                         inputPath: inputPath,
                         to: zipPathFull)
            
            consoleIO.writeMessage("Files extracted")
        }
        
        consoleIO.writeMessage("End")
    }
}
