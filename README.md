# vedge_patient

Vedge for Patients — the consumer-facing Flutter app for the Vedge health
platform. Phone-first OTP auth, cross-tenant record claims, and read-only
access to lab results, appointments, and prescriptions.

## Quick start

```bash
# One-time: fill in platform shells (see BOOTSTRAP.md)
flutter create --org health.vedge --platforms=ios,android --project-name vedge_patient .

flutter pub get
flutter analyze

# Run against local backend on :8050
flutter run --dart-define=API_BASE_URL=http://localhost:8050
```

## Backend contract

Consumes the patient endpoints under `/api/patient/**` shipped in W5.4:

- `POST /api/patient/auth/register` → phone + name + DOB onboarding
- `POST /api/patient/auth/verify-otp` → completes registration
- `POST /api/patient/auth/login-otp` + `verify-login-otp` → returning users
- `GET  /api/patient/auth/me`
- `GET  /api/patient/my/links` → list claimed records across tenants
- `POST /api/patient/my/potential-matches` → discover unclaimed records
- `POST /api/patient/my/links/{id}/confirm` → v1 trust-based claim verify
- `POST /api/patient/my/links/{id}/set-current` → switch active provider
- `GET  /api/patient/my/lab-results`
- `GET  /api/patient/my/appointments`
- `GET  /api/patient/my/prescriptions`

All secured with a PATIENT-issuer JWT distinct from the staff JWT.

## Architecture

- **State**: `flutter_riverpod` (matches `vedge_staff`)
- **Routing**: `go_router` with auth + claims guards
- **Networking**: `dio` with single-flight JWT refresh interceptor
- **Persistence**: `flutter_secure_storage` with `vedge_patient.` key prefix
- **Design**: teal-700 primary, Fraunces display, Inter body, warmer surface
  tint and larger tap targets than the staff app (patient app ≠ clinical app).

## Status

W5.5 walking skeleton — full auth + claim flow + read-only data screens.
Booking, prescriptions refill, and push notifications are scaffolded as
stubs and will land in W5.5b.
# vedge_patient
