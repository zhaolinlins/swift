// Test the -require-explicit-availability flag
// REQUIRES: OS=macosx

// RUN: %swiftc_driver -typecheck -parse-stdlib -target x86_64-apple-macosx10.10 -Xfrontend -verify -require-explicit-availability -require-explicit-availability-target "macOS 10.10"  %s
// RUN: %swiftc_driver -typecheck -parse-stdlib -target x86_64-apple-macosx10.10 -warnings-as-errors %s

public struct S { // expected-warning {{public declarations should have an availability attribute when building with -require-explicit-availability}}
  public func method() { }
}

public func foo() { bar() } // expected-warning {{public declarations should have an availability attribute when building with -require-explicit-availability}} {{1-1=@available(macOS 10.10, *)\n}}

@usableFromInline
func bar() { } // expected-warning {{public declarations should have an availability attribute when building with -require-explicit-availability}} {{1-1=@available(macOS 10.10, *)\n}}

@available(macOS 10.1, *)
public func ok() { }

@available(macOS, unavailable)
public func unavailableOk() { }

@available(macOS, deprecated: 10.10)
public func missingIntro() { } // expected-warning {{public declarations should have an availability attribute when building with -require-explicit-availability}} {{1-1=@available(macOS 10.10, *)\n}}

@available(iOS 9.0, *)
public func missingTargetPlatform() { } // expected-warning {{public declarations should have an availability attribute when building with -require-explicit-availability}} {{1-1=@available(macOS 10.10, *)\n}}

func privateFunc() { }

@_alwaysEmitIntoClient
public func alwaysEmitted() { }

@available(macOS 10.1, *)
struct SOk {
  public func okMethod() { }
}

precedencegroup MediumPrecedence {}
infix operator + : MediumPrecedence

public func +(lhs: S, rhs: S) -> S { } // expected-warning {{public declarations should have an availability attribute when building with -require-explicit-availability}} {{1-1=@available(macOS 10.10, *)\n}}

public enum E { } // expected-warning {{public declarations should have an availability attribute when building with -require-explicit-availability}} {{1-1=@available(macOS 10.10, *)\n}}

public class C { } // expected-warning {{public declarations should have an availability attribute when building with -require-explicit-availability}} {{1-1=@available(macOS 10.10, *)\n}}

public protocol P { } // expected-warning {{public declarations should have an availability attribute when building with -require-explicit-availability}} {{1-1=@available(macOS 10.10, *)\n}}

private protocol PrivateProto { }

extension S { // expected-warning {{public declarations should have an availability attribute when building with -require-explicit-availability}} {{1-1=@available(macOS 10.10, *)\n}}
  public func warnForPublicMembers() { } // expected-warning {{public declarations should have an availability attribute when building with -require-explicit-availability}} {{3-3=@available(macOS 10.10, *)\n  }}
}

extension S {
  internal func dontWarnWithoutPublicMembers() { }
  private func dontWarnWithoutPublicMembers1() { }
}

extension S : P { // expected-warning {{public declarations should have an availability attribute when building with -require-explicit-availability}} {{1-1=@available(macOS 10.10, *)\n}}
}

extension S : PrivateProto {
}

open class OpenClass { } // expected-warning {{public declarations should have an availability attribute when building with -require-explicit-availability}} {{1-1=@available(macOS 10.10, *)\n}}

private class PrivateClass { }

extension PrivateClass { }
