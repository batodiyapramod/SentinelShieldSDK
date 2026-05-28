# Commercial Binary Distribution

Use this source package privately. Do not give customers this repository if you want to hide implementation files.

For public paid usage, ship `SentinelShieldSDK.xcframework` through a separate binary Swift package.

## Why

Swift Package Manager source packages expose every source file to the user. Access control such as `internal` hides APIs from code completion and compilation, but it does not hide source code.

Binary distribution hides implementation files. Customers receive:

- The compiled framework binary
- The generated public Swift module interface
- Public symbols and public models only
- No detector source files

## Recommended Repo Setup

Keep two repositories:

1. `SentinelShieldSDK-Private`
   - Full source code
   - Tests
   - Release scripts
   - CI/CD

2. `SentinelShieldSDK`
   - Public README
   - `Package.swift` with `.binaryTarget`
   - Changelog
   - License

The public repo should look like:

```text
SentinelShieldSDK/
  Package.swift
  README.md
  LICENSE.md
```

The public `Package.swift` should use the template in `Distribution/Package.swift`.

## Build Flow

1. Archive the SDK for iOS device.
2. Archive the SDK for iOS Simulator.
3. Combine both archives into `SentinelShieldSDK.xcframework`.
4. Zip the XCFramework.
5. Upload the zip to a private CDN or release asset URL.
6. Generate the SwiftPM checksum.
7. Update the public binary package `Package.swift`.

Checksum command:

```bash
swift package compute-checksum SentinelShieldSDK-1.0.0.xcframework.zip
```

## API Exposure Rules

Only mark customer-facing APIs as `public`.

Keep implementation types as `internal`, for example:

```swift
public enum SentinelShield {
    public static func scan(...) -> ShieldReport
}

struct JailbreakDetector {
    func evaluate() -> DetectionResult
}
```

Current SDK already follows this pattern: detector implementations are internal, while the facade and result models are public.

## Paid Service Enforcement

You can allow free SDK use in Debug builds and require a paid license in Release builds.

Do not rely on client-side license checks alone. Apps can be patched.

Recommended paid-service model:

1. Customer creates an account in your dashboard.
2. You issue an SDK key tied to bundle IDs and team IDs.
3. SDK calls your backend during setup.
4. Backend validates:
   - SDK key
   - App bundle ID
   - Apple Team ID
   - App Attest assertion
   - subscription/license status
5. Backend returns a short-lived signed policy token.
6. SDK sends that token with risk reports or protected service calls.

In the SDK, `LicenseGate` supports the first local gate:

- Debug with `allowDebugWithoutLicense = true`: allowed
- Release without a license key: blocked
- Release with backend entitlement mismatch/expiry: blocked

See `Distribution/BACKEND_VALIDATION.md` for the complete backend validation flow.

Keep high-value logic server-side:

- License enforcement
- Risk scoring thresholds
- Abuse rules
- Device reputation
- App Attest verification
- DeviceCheck exchange with Apple

Client-side code should collect signals and produce local summaries, but your backend should decide whether a customer is allowed to use the paid service.

## What Customers Can Still See

Even with a binary framework, customers may see:

- Public API names
- Public Swift interfaces
- Exported symbols
- Runtime behavior

For extra hardening:

- Keep most APIs behind one public facade
- Avoid exposing implementation class names
- Use `internal` by default
- Strip debug symbols from release builds
- Use server-side policy decisions
- Rotate signed policy tokens
- Monitor usage on your backend

Binary distribution protects your files and implementation structure. It does not make reverse engineering impossible.
