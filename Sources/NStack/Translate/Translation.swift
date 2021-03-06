import Vapor
import Foundation
import Cache

public struct Translation {
    
    let drop: Droplet
    let application: Application
    let json: JSON
    let platform: String
    let language: String
    let date: Date
    
    init(drop: Droplet, application: Application, json: JSON, platform: String, language: String) {
        self.drop = drop
        self.application = application
        self.json = json
        self.platform = platform
        self.language = language
        
        self.date = Date()
    }
    
    init(drop: Droplet, application: Application, node: Node) throws {
        self.drop = drop
        self.application = application
        
        self.json = try node.extract("json")
        self.platform = try node.extract("platform")
        self.language = try node.extract("language")
    
        self.date = try Date.parse(node.extract("date"))
    }
    
    func isOutdated() -> Bool {
        let cacheInMinutes = drop.config["nstack", "translate", "cacheInMinutes"]?.int ?? 60

        let secondsInMinutes: TimeInterval = Double(cacheInMinutes) * 60
        let dateAtCacheExpiration: Date = Date().addingTimeInterval(-secondsInMinutes)
        
        return dateAtCacheExpiration.isAfter(self.date)
    }
    
    func get(section: String, key: String) -> String {
        do {
            let data: Node = try self.json.extract("data")
            let section: Node = try data.extract(section)
            let key: String = try section.extract(key)
            return key
        } catch  {
            application.nStackConfig.log("NStack.Translate.get error:" + error.localizedDescription)
            return Translation.fallback(section: section, key: key)
        }
    }
    
    public static func fallback(section: String, key: String) -> String{
        return section + "." + key
    }
    
    func toNode() throws -> Node{
        return Node([
            "language": Node(language),
            "platform": Node(platform),
            "json": json.node,
            "date": try Node(date.toDateTimeString())
        ])
    }
}
