extension String {
    var nullsToNewlines: String {
        replacingOccurrences(of: "\0", with: "\n")
    }
}
