import Foundation

/// Formats `value` exactly like JavaScript's `Number.prototype.toFixed(digits)`.
///
/// # Why not `String(format: "%.2f", …)`
///
/// C's `printf` family rounds half-way cases to even (`0.125` → `"0.12"`),
/// while ECMAScript's `toFixed` rounds half-way cases *up* (`0.125` → `"0.13"`).
/// "Half-way" here is measured against the **exact binary value** of the
/// `Double`, not against its shortest decimal representation — which is why
/// `(9.995).toFixed(2)` is `"9.99"` (the stored `Double` is slightly below
/// `9.995`) while `(0.125).toFixed(2)` is `"0.13"` (the stored `Double` is
/// exactly `0.125`).
///
/// # Algorithm (ECMA-262, `Number.prototype.toFixed`, step 10)
///
/// > Let `n` be an integer for which `n / 10^f - x` is as close to zero as
/// > possible. If there are two such `n`, pick the larger `n`.
///
/// Every finite `Double` is exactly `m * 2^e` for integers `m`, `e`. Therefore
/// `x * 10^f == (m * 10^f) / 2^k` (with `k = -e`) is an exact rational, and
/// `n` can be obtained with pure integer arithmetic:
///
/// - `q = (m * 10^f) / 2^k` (integer division) and `r` its remainder,
/// - `n = q + 1` when `2 * r >= 2^k` (ties round up), otherwise `n = q`.
///
/// No floating-point rounding happens anywhere in that path, so the result
/// matches ECMAScript bit for bit.
///
/// # Domain
///
/// Exactness is guaranteed for the values this app produces: finite values in
/// roughly `0 ... 1e17` with `digits` in `0 ... 2`. Outside that range the
/// intermediate integers can exceed `UInt64`; the function then falls back to
/// `String(format:)` with a fixed POSIX locale, which may differ from
/// JavaScript in half-way cases but never crashes. `NaN` and infinities return
/// the JavaScript string forms (`"NaN"`, `"Infinity"`, `"-Infinity"`).
///
/// - Parameters:
///   - value: The value to format.
///   - digits: Number of fraction digits. Clamped to `0 ... 100` (ECMAScript
///     throws a `RangeError` outside that range; this function clamps instead).
/// - Returns: The formatted string, with trailing zeros and the decimal point
///   preserved (e.g. `"1.20"`, `"120.0"`).
public func jsToFixed(_ value: Double, digits: Int) -> String {
    let fractionDigits = min(max(digits, 0), 100)

    if value.isNaN { return "NaN" }
    if value.isInfinite { return value < 0 ? "-Infinity" : "Infinity" }

    // ECMAScript: `if x < 0 then s = "-"`. Note `-0.0 < 0` is `false`, so
    // `(-0).toFixed(2)` is `"0.00"` — matching JavaScript.
    let isNegative = value < 0
    let magnitude = isNegative ? -value : value

    // ECMAScript falls back to `ToString(x)` for magnitudes >= 1e21.
    guard magnitude < 1e21 else { return "\(value)" }

    guard let scaled = jsToFixedScaledInteger(magnitude, fractionDigits: fractionDigits) else {
        return jsToFixedFallback(value, fractionDigits: fractionDigits)
    }

    let body = jsToFixedInsertPoint(String(scaled), fractionDigits: fractionDigits)
    return isNegative ? "-" + body : body
}

// MARK: - Integer core

/// Returns `n` from the ECMAScript definition: the integer closest to
/// `magnitude * 10^fractionDigits`, ties away from zero (i.e. up, as the input
/// is non-negative). Returns `nil` when the exact computation would overflow
/// `UInt64`.
private func jsToFixedScaledInteger(_ magnitude: Double, fractionDigits: Int) -> UInt64? {
    precondition(magnitude >= 0 && magnitude.isFinite)

    if magnitude == 0 { return 0 }
    guard let power = jsToFixedPowerOfTen(fractionDigits) else { return nil }

    // Decompose into `magnitude == significand * 2^exponent` exactly.
    var (significand, exponent) = jsToFixedDecompose(magnitude)

    // Normalizing away trailing zero bits keeps `2^-exponent` representable
    // in `UInt64` for the common case.
    while exponent < 0 && significand % 2 == 0 {
        significand >>= 1
        exponent += 1
    }

    let (numerator, overflowed) = significand.multipliedReportingOverflow(by: power)
    guard !overflowed else { return nil }

    if exponent >= 0 {
        // `numerator * 2^exponent` is already an integer; no rounding needed.
        guard exponent < 64 else { return nil }
        if exponent > 0 {
            guard numerator <= (UInt64.max >> exponent) else { return nil }
            return numerator << exponent
        }
        return numerator
    }

    let shift = -exponent

    if shift >= 64 {
        // `numerator < 2^64 <= 2^shift`, so the quotient is 0. It rounds up to
        // 1 only when `2 * numerator >= 2^shift`, which can only happen at
        // `shift == 64`.
        if shift == 64 {
            return numerator >= (UInt64(1) << 63) ? 1 : 0
        }
        return 0
    }

    let divisor = UInt64(1) << shift
    let quotient = numerator / divisor
    let remainder = numerator % divisor

    // `2 * remainder >= divisor`, written to avoid overflowing the doubling.
    guard remainder >= divisor - remainder else { return quotient }

    let (rounded, roundOverflow) = quotient.addingReportingOverflow(1)
    return roundOverflow ? nil : rounded
}

/// Splits a positive finite `Double` into `(significand, exponent)` such that
/// `value == significand * 2^exponent` exactly.
private func jsToFixedDecompose(_ value: Double) -> (significand: UInt64, exponent: Int) {
    let bits = value.bitPattern
    let biasedExponent = Int((bits >> 52) & 0x7FF)
    let mantissa = bits & 0x000F_FFFF_FFFF_FFFF

    if biasedExponent == 0 {
        // Subnormal: no implicit leading bit.
        return (mantissa, -1074)
    }
    return (mantissa | (UInt64(1) << 52), biasedExponent - 1075)
}

private func jsToFixedPowerOfTen(_ exponent: Int) -> UInt64? {
    guard exponent >= 0, exponent <= 19 else { return nil }
    var result: UInt64 = 1
    for _ in 0..<exponent {
        let (next, overflowed) = result.multipliedReportingOverflow(by: 10)
        guard !overflowed else { return nil }
        result = next
    }
    return result
}

// MARK: - String assembly

/// Turns the digit string of `n` into the final fixed-point representation,
/// left-padding with zeros so that a decimal point can always be inserted.
private func jsToFixedInsertPoint(_ digitString: String, fractionDigits: Int) -> String {
    guard fractionDigits > 0 else { return digitString }

    var digits = digitString
    if digits.count <= fractionDigits {
        digits = String(repeating: "0", count: fractionDigits - digits.count + 1) + digits
    }

    let splitIndex = digits.index(digits.endIndex, offsetBy: -fractionDigits)
    return String(digits[digits.startIndex..<splitIndex]) + "." + String(digits[splitIndex...])
}

/// Locale-independent `printf` formatting, used only for magnitudes outside the
/// exactly-supported domain.
private func jsToFixedFallback(_ value: Double, fractionDigits: Int) -> String {
    String(format: "%.\(fractionDigits)f", locale: Locale(identifier: "en_US_POSIX"), value)
}
