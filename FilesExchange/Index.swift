//
//  Index.swift
//  FilesExchange
//
//  Created by Evgeny Velichko on 12.02.2021.
//

import Foundation

struct Index: Codable {
    let name: String
    let url: URL
    
    enum CodingKeys: String, CodingKey {
        case name
        case path
    }
    
    init(name: String,
         url: URL) {
        self.name = name
        self.url = url
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        name = try container.decode(String.self, forKey: .name)
        url = URL(fileURLWithPath: try container.decode(String.self, forKey: .path))
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        try container.encode(url.path, forKey: .path)
    }
}
