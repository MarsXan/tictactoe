/// A use case changed the match but could not save it. Carries the changed match, so play goes on
/// in memory and the next successful save writes it.
struct MatchNotSaved: Error {
    let match: Match
    let underlying: any Error
}
