import Foundation
import Marshal

public struct LinesResponse {
    public let lines: [Line]
    public let expirationTime: Date
}

public struct Line {
    public struct Direction {
        public let name: String
        public let timetables: [TimeTable]
    }

    public struct TimeTable {
        public let id: String
        public let name: String
    }

    public let name: String
    public let mode: Mode
    public let changes: [String]?
    public let directions: [Direction]
    public let diva: Diva?
}

// MARK: - JSON

extension LinesResponse: Unmarshaling {
    public init(object: MarshaledObject) throws {
        lines = try object <| "Lines"
        expirationTime = try object <| "ExpirationTime"
    }
}

extension Line: Unmarshaling {
    public init(object: MarshaledObject) throws {
        name = try object <| "Name"
        mode = try object <| "Mot"
        directions = try object <| "Directions"
        changes = try object <| "Changes"
        diva = try object <| "Diva"
    }
}

extension Line.Direction: Unmarshaling {
    public init(object: MarshaledObject) throws {
        name = try object <| "Name"
        timetables = try object <| "TimeTables"
    }
}

extension Line.TimeTable: Unmarshaling {
    public init(object: MarshaledObject) throws {
        name = try object <| "Name"
        id = try object <| "Id"
    }
}

// MARK: - API

extension Line {
    public static func get(forStopId id: String, session: URLSession = .shared, completion: @escaping (Result<LinesResponse>) -> Void) {
        let data = [
            "stopid": id,
        ]
        post(Endpoint.lines, data: data, session: session, completion: completion)
    }

    /// Convenience function taking a stop name. Sends of a find request first and uses the first result's `id` as an argument for the lines request.
    public static func get(forStopName name: String, session: URLSession = .shared, completion: @escaping (Result<LinesResponse>) -> Void) {
        Stop.find(name, session: session) { result in
            switch result {
            case let .failure(error): completion(Result(failure: error))
            case let .success(response):
                guard let first = response.stops.first else {
                    completion(Result(failure: DVBError.response))
                    return
                }
                Line.get(forStopId: first.id, session: session, completion: completion)
            }
        }
    }
}

// MARK: - Utility

extension Line: CustomStringConvertible {
    public var description: String {
        let dirs = directions.map { $0.name }.joined(separator: ", ")
        return "\(name): \(dirs)"
    }
}

extension Line: Equatable {}
public func == (lhs: Line, rhs: Line) -> Bool {
    return lhs.name == rhs.name && lhs.directions == rhs.directions
}

extension Line.Direction: Equatable {}
public func == (lhs: Line.Direction, rhs: Line.Direction) -> Bool {
    return lhs.name == rhs.name && lhs.timetables == rhs.timetables
}

extension Line.TimeTable: Equatable {}
public func == (lhs: Line.TimeTable, rhs: Line.TimeTable) -> Bool {
    return lhs.id == rhs.id
}
