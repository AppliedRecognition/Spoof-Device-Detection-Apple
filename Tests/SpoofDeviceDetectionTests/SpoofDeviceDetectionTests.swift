import XCTest
import SpoofDeviceDetection
@testable import SpoofDeviceDetectionFull

final class SpoofDeviceDetectionTests: XCTestCase {
    
    func testCreateSpoofDetector() throws {
        XCTAssertNoThrow(try SpoofDeviceDetector())
    }
    
    func testDetectSpoof() throws {
        let spoofDetector = try SpoofDeviceDetector()
        let spoofs = try spoofDetector.detectSpoofDevicesInImage(self.testImage)
        XCTAssertEqual(1, spoofs.count)
        XCTAssertEqual(0.96, spoofs.first!.confidence, accuracy: 0.1)
    }
    
    private lazy var testImage: UIImage = UIImage(named: "face_on_iPad_001.jpg", in: Bundle.module, compatibleWith: nil)!
}
