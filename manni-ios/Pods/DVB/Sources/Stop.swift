import Foundation
import Marshal
import gausskrueger

public struct FindResponse {
    public let stops: [Stop]
    public let expirationTime: Date?
}

/// A place where a bus, tram or whatever can stop.
public struct Stop {
    public let id: String
    public let name: String
    public let region: String?
    public let location: WGSCoordinate?
}

// MARK: - JSON

extension FindResponse: Unmarshaling {
    public init(object: MarshaledObject) throws {
        stops = try object <| "Points"
        expirationTime = try object <| "ExpirationTime"
    }
}

extension Stop {
    init(string: String) throws {
        let components = string.components(separatedBy: "|")
        guard components.count == 9 else { throw DVBError.decode }
        id = components[0]
        region = components[2].isEmpty ? nil : components[2]
        name = components[3]

        guard let x = Double(components[5]),
            let y = Double(components[4]) else {
            throw DVBError.decode
        }
        if x != 0, y != 0 {
            location = GKCoordinate(x: x, y: y).asWGS
        } else {
            location = nil
        }
    }
}

extension Stop: ValueType {
    public static func value(from object: Any) throws -> Stop {
        guard let str = object as? String else {
            throw MarshalError.typeMismatch(expected: String.self, actual: type(of: object))
        }

        let components = str.components(separatedBy: "|")

        guard components.count == 9 else {
            throw MarshalError.typeMismatch(expected: "Stop string should have 9 different values", actual: components.count)
        }
        guard let x = Double(components[5]), let y = Double(components[4]) else {
            throw MarshalError.typeMismatch(expected: "X and Y should be number values", actual: (type(of: components[4]), type(of: components[5])))
        }

        let region: String? = components[2].isEmpty ? nil : components[2]
        let location = x != 0 && y != 0 ? GKCoordinate(x: x, y: y).asWGS : nil

        return Stop(id: components[0], name: components[3], region: region, location: location)
    }
}

// MARK: - API

extension Stop {
    public static func find(_ query: String, session: URLSession = .shared, completion: @escaping (Result<FindResponse>) -> Void) {
        let data: [String: Any] = [
            "limit": 0,
            "query": query,
            "stopsOnly": true,
            "dvb": true,
        ]
        post(Endpoint.pointfinder, data: data, session: session, completion: completion)
    }

    public static func findNear(lat: Double, lng: Double, session: URLSession = .shared, completion: @escaping (Result<FindResponse>) -> Void) {
        let coord = WGSCoordinate(latitude: lat, longitude: lng)
        findNear(coord: coord, session: session, completion: completion)
    }

    public static func findNear(coord: Coordinate, session: URLSession = .shared, completion: @escaping (Result<FindResponse>) -> Void) {
        guard let gk = coord.asGK else {
            completion(Result(failure: DVBError.coordinate))
            return
        }
        let data: [String: Any] = [
            "limit": 0,
            "assignedStops": true,
            "query": "coord:\(Int(gk.x)):\(Int(gk.y))",
        ]
        post(Endpoint.pointfinder, data: data, session: session, completion: completion)
    }
}

extension Stop {
    public func monitor(date: Date = Date(), dateType: Departure.DateType = .arrival, allowedModes modes: [Mode] = Mode.all, allowShorttermChanges: Bool = true, session: URLSession = .shared, completion: @escaping (Result<MonitorResponse>) -> Void) {
        Departure.monitor(stopWithId: self.id, date: date, dateType: dateType, allowedModes: modes, allowShorttermChanges: allowShorttermChanges, session: session, completion: completion)
    }
}

// MARK: - Utility

extension Stop: CustomStringConvertible {
    public var description: String {
        if let region = region, !region.isEmpty {
            return "\(name), \(region)"
        }
        return name
    }
}

extension Stop: Equatable {}
public func == (lhs: Stop, rhs: Stop) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

extension Stop: Hashable {
    public var hashValue: Int {
        return self.id.hashValue
    }
}
