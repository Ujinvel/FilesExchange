//
//  Array+Chanked.swift
//  FilesExchange
//
//  Created by Evgeny Velichko on 12.02.2021.
//

import Foundation

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size)
            .map { Array(self[$0 ..< Swift.min($0 + size, count)]) }
    }
}
