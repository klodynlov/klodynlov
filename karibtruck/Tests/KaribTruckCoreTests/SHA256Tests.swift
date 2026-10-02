import XCTest
@testable import KaribTruckCore

/// Vecteurs standards FIPS 180-4 : prouvent que notre SHA-256 en Swift pur est
/// bit-exact. Ces valeurs sont universelles (identiques à `sha256sum` / hashlib).
final class SHA256Tests: XCTestCase {

    func testEmptyString() {
        XCTAssertEqual(
            SHA256.hexHash(""),
            "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
    }

    func testAbc() {
        XCTAssertEqual(
            SHA256.hexHash("abc"),
            "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }

    /// Message de 56 octets → franchit la frontière de bloc (test du padding/extension).
    func testMultiBlock() {
        let msg = "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"
        XCTAssertEqual(
            SHA256.hexHash(msg),
            "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1")
    }

    /// UTF-8 multi-octets correctement pris en compte (accents caribéens).
    /// Référence : `hashlib.sha256("crème antillaise".encode())`.
    func testUnicode() {
        XCTAssertEqual(
            SHA256.hexHash("crème antillaise"),
            "da2d03fc834e4d0b42ff1ebef6726ce673552fdb9afc5aeab9325ce6dd8ff7bd")
    }
}
