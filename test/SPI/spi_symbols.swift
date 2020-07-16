// REQUIRES: VENDOR=apple
// RUN: %empty-directory(%t)

// RUN: %target-swift-frontend %S/Inputs/spi_helper.swift -emit-ir -o %t/spi_helper.ll -emit-tbd-path %t/spi_helper.tbd -module-name spi_helper

// RUN: cat %t/spi_helper.ll | %FileCheck -check-prefix=CHECK-IR %s
// RUN: cat %t/spi_helper.tbd | %FileCheck -check-prefix=CHECK-TBD %s

// Look for the SPI symbols in the IR
// CHECK-IR: define swiftcc void @"$s10spi_helper0A4FuncyyF"
// CHECK-IR: define swiftcc void @"$s10spi_helper9SPIStructC0A6MethodyyF"
// CHECK-IR: define swiftcc void @"$s10spi_helper8SPIClassC0A6MethodyyF"
// CHECK-IR: define swiftcc void @"$s10spi_helper7SPIEnumO0A6MethodyyF"
// CHECK-IR: define swiftcc void @"$s10spi_helper12PublicStructV0A6MethodyyF"
// CHECK-IR: define swiftcc void @"$s10spi_helper12otherApiFuncyyF"

// Look for the SPI symbols in the TBD file, these are sorted
// CHECK-TBD: _$s10spi_helper0A4FuncyyF
// CHECK-TBD: _$s10spi_helper12PublicStructV0A6MethodyyF
// CHECK-TBD: _$s10spi_helper12otherApiFuncyyF
// CHECK-TBD: _$s10spi_helper7SPIEnumO0A6MethodyyF
// CHECK-TBD: _$s10spi_helper8SPIClassC0A6MethodyyF
// CHECK-TBD: _$s10spi_helper9SPIStructC0A6MethodyyF
