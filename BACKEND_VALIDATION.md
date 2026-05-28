# Backend Validation Blueprint

Use this flow to allow free Debug builds and require paid licenses for Release/App Store builds.

Your backend should validate subscription status, bundle ID, Apple Team ID, App Attest, and then return a signed short-lived entitlement. Do not rely on client-side checks alone; apps can be patched.

## Minimal Data Model

```text
customers
  id
  plan
  subscription_status

licenses
  id
  customer_id
  license_key_hash
  status
  allowed_bundle_ids
  allowed_team_ids

app_attest_keys
  id
  license_id
  key_id
  public_key
  bundle_id
  team_id
  environment
  sign_count
  revoked_at

challenges
  id
  nonce_hash
  purpose
  expires_at
  consumed_at
```

Store only a hash of the license key.

## Flow

### 1. Create Challenge

Client calls:

```http
POST /v1/sdk/challenge
Content-Type: application/json

{
  "licenseKey": "license_live_xxx",
  "bundleId": "com.example.app",
  "purpose": "app_attest_registration"
}
```

Server checks:

- License key exists and is active
- Customer subscription is active
- Bundle ID is allowed for the license

Server returns:

```json
{
  "challengeId": "chal_123",
  "challenge": "base64url-random-32-bytes"
}
```

Use a cryptographically random nonce, store its hash, bind it to the license and bundle ID, mark it single-use, and expire it quickly.

### 2. Register App Attest Key

Client creates an App Attest key and attestation object, then calls:

```http
POST /v1/sdk/app-attest/register
Content-Type: application/json

{
  "licenseKey": "license_live_xxx",
  "bundleId": "com.example.app",
  "teamId": "ABCDE12345",
  "keyId": "apple-app-attest-key-id",
  "challengeId": "chal_123",
  "clientDataHash": "base64url-sha256-challenge",
  "attestationObject": "base64url-cbor-attestation-object"
}
```

Server validates the attestation using Apple’s App Attest rules:

- Challenge exists, is unexpired, and has not been consumed
- `clientDataHash` matches `SHA256(challenge)`
- Attestation certificate chain is valid for Apple App Attest
- Attestation environment matches expectation, such as development or production
- App identifier hash matches `SHA256(teamID + "." + bundleID)`
- Credential ID matches the App Attest `keyId`
- Public key is extracted and stored
- Initial sign counter is stored

Server also validates business rules:

- License is active
- Customer subscription is active
- Bundle ID is allowed
- Team ID is allowed

Then store the App Attest public key and mark the challenge consumed.

### 3. Refresh Runtime Entitlement

For future SDK startup or protected calls, the app signs a canonical request with App Attest assertion.

Server validates:

- License and subscription are active
- Bundle ID and Team ID are allowed
- App Attest key exists and is not revoked
- Assertion signature verifies with the stored public key
- Assertion `clientDataHash` matches the canonical request payload
- Assertion app identifier hash matches `SHA256(teamID + "." + bundleID)`
- Assertion sign counter is greater than the stored counter
- Nonce/challenge has not been replayed

Update the stored sign counter after successful validation.

## Short-Lived Entitlement

Return a signed short-lived token, usually JWT:

```json
{
  "iss": "sentinelshield",
  "aud": "sentinelshield-sdk",
  "sub": "license_123",
  "bundle_id": "com.example.app",
  "team_id": "ABCDE12345",
  "plan": "pro",
  "features": ["jailbreak", "app_attest", "behavioral_signals"],
  "iat": 1780000000,
  "exp": 1780003600,
  "jti": "ent_123"
}
```

Recommendations:

- Expiry: 15 minutes to 1 hour
- Signing algorithm: ES256 or EdDSA
- Include `kid` in the JWT header for key rotation
- Keep signing private keys only on the backend
- Cache locally only until `exp`

## Subscription Validation

For direct B2B billing:

- Validate the subscription in Stripe or your billing provider.
- Mirror subscription state into your database through webhooks.
- Avoid calling the billing provider on every SDK request.

For App Store purchases:

- Validate with App Store Server API.
- Store original transaction ID and entitlement state.
- Update state from App Store Server Notifications.

For a paid SDK, direct billing plus license keys is usually simpler.

## DeviceCheck

DeviceCheck is optional for this licensing flow. Use it for coarse device-level abuse tracking, such as trial already used, blocked device, or repeated abuse. DeviceCheck does not replace subscription or App Attest validation.

## Failure Behavior

```text
Debug build + no license:
  allow

Release build + no license:
  block SDK features

Release build + invalid entitlement:
  block paid features

Release build + network unavailable:
  allow only if a cached entitlement is still valid
```

Apple’s App Attest docs describe the server-side attestation/assertion model:

- https://developer.apple.com/documentation/devicecheck/establishing-your-app-s-integrity
- https://developer.apple.com/documentation/devicecheck/validating-apps-that-connect-to-your-server
