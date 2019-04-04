import Foundation

typealias JSON = [String: Any]

func get<T: Decodable>(_ url: URL, session: URLSession = .shared, completion: @escaping (Result<T>) -> Void) {
    var request = URLRequest(url: url)
    request.httpMethod = HTTPMethod.GET.rawValue
    dataTask(request: request, session: session, completion: completion)
}

func post<T: Decodable>(_ url: URL, data: [String: Any], session: URLSession = .shared, completion: @escaping (Result<T>) -> Void) {
    var request = URLRequest(url: url)
    request.httpMethod = HTTPMethod.POST.rawValue
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: data)
    } catch let e {
        completion(Result(failure: e))
        return
    }
    request.addValue("application/json;charset=UTF-8", forHTTPHeaderField: "Content-Type")

    dataTask(request: request, session: session, completion: completion)
}

private enum HTTPMethod: String {
    case GET
    case POST
}

private func dataTask<T: Decodable>(request: URLRequest, session: URLSession = .shared, completion: @escaping (Result<T>) -> Void) {
    let task = session.dataTask(with: request) { data, response, error in
        guard
            error == nil,
            let data = data,
            let response = response as? HTTPURLResponse
        else {
            completion(Result(failure: DVBError.network))
            return
        }

        guard response.statusCode / 100 == 2 else {
            completion(Result(failure: DVBError.server(statusCode: response.statusCode)))
            return
        }

        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? JSON else {
                completion(Result(failure: DVBError.decode))
                return
            }

            guard
                let status = json["Status"] as? JSON,
                let statusCode = status["Code"] as? String
            else {
                completion(Result(failure: DVBError.response))
                return
            }

            guard statusCode == "Ok" else {
                var message = ""
                if let messageTxt = status["Message"] as? String {
                    message = messageTxt
                }
                completion(Result(failure: DVBError.request(status: statusCode, message: message)))
                return
            }

            let jsonDecoder = JSONDecoder()
            jsonDecoder.dateDecodingStrategy = .custom(SAPDateDecoder.strategy)
            let decoded = try jsonDecoder.decode(T.self, from: data)
            completion(Result(success: decoded))

        } catch let e {
            completion(Result(failure: e))
        }
    }
    task.resume()
}
