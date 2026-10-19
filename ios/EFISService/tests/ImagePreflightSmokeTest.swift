import Foundation

// Compile as main.swift with FirmwareLibrary.swift and SignedFirmware.swift.
// Offline checks only: no physical transfer, signing or publishing.
let arguments = CommandLine.arguments
precondition(arguments.count == 3, "Usage: image-preflight actual-efis.bin simulator.bin")
let valid = try Data(contentsOf: URL(fileURLWithPath: arguments[1]))
let simulator = try Data(contentsOf: URL(fileURLWithPath: arguments[2]))
precondition(FirmwareLibrary.imagePreflight(valid) == nil, "Valid EFIS image rejected")
precondition(FirmwareLibrary.imagePreflight(simulator) != nil, "Simulator image accepted")
var wrongProject = valid
wrongProject.replaceSubrange(80..<90, with: Array("efis_lab  ".utf8))
precondition(FirmwareLibrary.imagePreflight(wrongProject) != nil, "Wrong project accepted")
var wrongDescriptor = valid
wrongDescriptor[32] = 0
precondition(FirmwareLibrary.imagePreflight(wrongDescriptor) != nil, "Missing descriptor accepted")
print("PASS: EFIS accepted; simulator, wrong project, missing descriptor rejected")
