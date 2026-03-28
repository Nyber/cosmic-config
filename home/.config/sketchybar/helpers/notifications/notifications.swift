import Foundation
import AppKit
import SQLite3

let coreDataEpochOffset: Double = 978307200

struct Notification {
    let app: String
    let bundleId: String
    let title: String
    let body: String
    let subtitle: String
    let unixTimestamp: Double
}

func emptyResult() -> String {
    return "{\"count\":0,\"notifications\":[]}"
}

func escapeJSON(_ s: String) -> String {
    var result = ""
    for c in s {
        switch c {
        case "\"": result += "\\\""
        case "\\": result += "\\\\"
        case "\n": result += "\\n"
        case "\r": result += "\\r"
        case "\t": result += "\\t"
        default:
            if c.asciiValue != nil && c.asciiValue! < 0x20 {
                result += String(format: "\\u%04x", c.asciiValue!)
            } else {
                result.append(c)
            }
        }
    }
    return result
}

func appName(forBundleId bundleId: String) -> String {
    if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
        let name = url.deletingPathExtension().lastPathComponent
        if !name.isEmpty { return name }
    }
    // Fallback: last component of bundle ID
    let parts = bundleId.split(separator: ".")
    if let last = parts.last { return String(last) }
    return bundleId
}

func parseNotificationData(_ data: Data) -> (title: String, body: String, subtitle: String, bundleIdFromPlist: String?) {
    guard let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
        return ("", "", "", nil)
    }

    var title = ""
    var body = ""
    var subtitle = ""
    var bundleIdFromPlist: String? = nil

    if let req = plist["req"] as? [String: Any] {
        title = req["titl"] as? String ?? ""
        body = req["body"] as? String ?? ""
        subtitle = req["subt"] as? String ?? ""
    }

    bundleIdFromPlist = plist["app"] as? String

    return (title, body, subtitle, bundleIdFromPlist)
}

func main() {
    let dbPath = NSHomeDirectory() + "/Library/Group Containers/group.com.apple.usernoted/db2/db"
    var db: OpaquePointer?

    let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_URI
    guard sqlite3_open_v2(dbPath, &db, flags, nil) == SQLITE_OK else {
        print(emptyResult())
        return
    }
    defer { sqlite3_close(db) }

    // Enable WAL read mode
    var pragmaStmt: OpaquePointer?
    if sqlite3_prepare_v2(db, "PRAGMA journal_mode=wal", -1, &pragmaStmt, nil) == SQLITE_OK {
        sqlite3_step(pragmaStmt)
    }
    sqlite3_finalize(pragmaStmt)

    let query = """
        SELECT a.identifier, r.data, r.delivered_date
        FROM record r
        JOIN app a ON a.app_id = r.app_id
        WHERE r.delivered_date IS NOT NULL
        ORDER BY r.delivered_date DESC
        LIMIT 20
    """

    var stmt: OpaquePointer?
    guard sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK else {
        print(emptyResult())
        return
    }
    defer { sqlite3_finalize(stmt) }

    var notifications: [Notification] = []

    while sqlite3_step(stmt) == SQLITE_ROW {
        let identifier: String
        if let cStr = sqlite3_column_text(stmt, 0) {
            identifier = String(cString: cStr)
        } else {
            continue
        }

        let deliveredDate = sqlite3_column_double(stmt, 2)
        let unixTimestamp = deliveredDate + coreDataEpochOffset

        var title = ""
        var body = ""
        var subtitle = ""
        var resolvedBundleId = identifier

        if let blob = sqlite3_column_blob(stmt, 1) {
            let blobSize = sqlite3_column_bytes(stmt, 1)
            let data = Data(bytes: blob, count: Int(blobSize))
            let parsed = parseNotificationData(data)
            title = parsed.title
            body = parsed.body
            subtitle = parsed.subtitle
            if let plistBundleId = parsed.bundleIdFromPlist, !plistBundleId.isEmpty {
                resolvedBundleId = plistBundleId
            }
        }

        // Skip notifications with no title
        if title.isEmpty { continue }

        let app = appName(forBundleId: resolvedBundleId)

        notifications.append(Notification(
            app: app,
            bundleId: resolvedBundleId,
            title: title,
            body: body,
            subtitle: subtitle,
            unixTimestamp: unixTimestamp
        ))
    }

    // Build JSON manually (no Codable dependency needed for simple output)
    var items: [String] = []
    for n in notifications {
        let item = "{\"app\":\"\(escapeJSON(n.app))\",\"bundle_id\":\"\(escapeJSON(n.bundleId))\",\"title\":\"\(escapeJSON(n.title))\",\"body\":\"\(escapeJSON(n.body))\",\"subtitle\":\"\(escapeJSON(n.subtitle))\",\"unix_timestamp\":\(n.unixTimestamp)}"
        items.append(item)
    }

    let json = "{\"count\":\(notifications.count),\"notifications\":[\(items.joined(separator: ","))]}"
    print(json)
}

main()
