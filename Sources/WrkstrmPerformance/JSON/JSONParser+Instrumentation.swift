import Foundation
import WrkstrmFoundation
import WrkstrmMain

// Type-erased boxes to concretize existential JSON coders when wrapping with Instrumented<>
private struct _AnyJSONEncoding: JSONDataEncoding {
  let base: any JSONDataEncoding
  func encode<T: Encodable>(_ value: T) throws -> Data { try base.encode(value) }
}
private struct _AnyJSONDecoding: JSONDataDecoding {
  let base: any JSONDataDecoding
  func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
    try base.decode(T.self, from: data)
  }
}

public extension WrkstrmMain.JSON.Parser {
  /// Build a composite parser from a list of parser details.
  /// - Parameters:
  ///   - details: Array of parser name+parser pairs. The first is considered primary for .usePrimary/.shadow.
  ///   - mode: Selection mode: `.parallel` (round-robin), `.shadow` (primary returns, others run in background), `.usePrimary` (always first).
  ///   - context: Optional context string attached to metrics events.
  ///   - store: Metrics store for instrumentation.
  static func composite(
    _ details: [WrkstrmMain.JSON.ParserInstrumentationDetails],
    mode: WrkstrmMain.JSON.CompositeMode,
    context: String? = nil,
    store: JSON.ParseMetricsStore?
  ) -> WrkstrmMain.JSON.Parser {
    precondition(!details.isEmpty, "At least one parser is required")

    var encoders: [any JSONDataEncoding] = []
    var decoders: [any JSONDataDecoding] = []
    for detail in details {
      let boxedEncoder = _AnyJSONEncoding(base: detail.parser.encoder)
      let boxedDecoder = _AnyJSONDecoding(base: detail.parser.decoder)
      encoders.append(
        JSONInstrumented(base: boxedEncoder, name: detail.name, context: context, recorder: store))
      decoders.append(
        JSONInstrumented(base: boxedDecoder, name: detail.name, context: context, recorder: store))
    }

    let encoder = WrkstrmMain.JSON.CompositeEncoding(encoders: encoders, mode: mode)
    let decoder = WrkstrmMain.JSON.CompositeDecoding(decoders: decoders, mode: mode)
    return JSON.Parser(encoder: encoder, decoder: decoder)
  }

  /// Returns an instrumented copy of this parser using the generic wrapper.
  func instrumented(
    name: String,
    context: String? = nil,
    store: JSON.ParseMetricsStore?
  ) -> WrkstrmMain.JSON.Parser {
    let encoder = InstrumentedAnyEncoder(
      base: self.encoder, name: name, context: context, recorder: store)
    let decoder = InstrumentedAnyDecoder(
      base: self.decoder, name: name, context: context, recorder: store)
    return JSON.Parser(encoder: encoder, decoder: decoder)
  }
}
