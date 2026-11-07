# Sahajjo — Phase 1: Authentication Module

Stack (from the SRS): **Flutter (Android, Dart)** → **Node.js + Express** → **MySQL**.
(The Python/FastAPI AI service, FAISS and S3 storage are not needed for authentication.)

## 1. Database
```bash
mysql -u root -p < backend/database/schema.sql
# create a least-privilege app user (pick your own password):
mysql -u root -p -e "CREATE USER 'sahajjo_app'@'localhost' IDENTIFIED BY '<your-password>'; GRANT SELECT,INSERT,UPDATE,DELETE ON sahajjo.* TO 'sahajjo_app'@'localhost';"
```

## 2. Backend
```bash
cd backend
cp .env.example .env     # fill DB_PASSWORD and JWT_SECRET (see comment in file)
npm install
npm start                # http://localhost:4000/health
```

| Method | Path | Auth | Purpose |
|---|---|---|---|
| POST | /api/auth/register | – | Create account (validated, bcrypt-hashed) |
| POST | /api/auth/login | – | Login with phone or email |
| GET | /api/auth/me | Bearer | Current user |
| DELETE | /api/auth/me | Bearer | Delete account and data (SRS FR-03) |

## 3. Flutter app
```bash
flutter create --org com.sahajjo --platforms android sahajjo_app
cd sahajjo_app
# replace its pubspec.yaml and lib/ with frontend/pubspec.yaml and frontend/lib/
```
In `android/app/src/main/AndroidManifest.xml`:
- add `<uses-permission android:name="android.permission.INTERNET"/>` above `<application>`
- for local HTTP testing only, add `android:usesCleartextTraffic="true"` to `<application>` (use HTTPS in production)
- set `minSdkVersion 23` in `android/app/build.gradle` (required by flutter_secure_storage)

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000/api   # emulator
```
For a physical phone use your computer's LAN IP instead of `10.0.2.2`.

## Security notes
- No credentials in code: DB password and JWT secret come only from `.env`; the app refuses to start without them.
- Passwords: bcrypt (cost 12), 8–72 chars with upper/lower/digit; never logged or returned.
- Prepared statements everywhere; generic login errors, timing equalised for unknown users.
- Rate limiting on auth routes + account lockout (5 failures → 15 min).
- JWT (HS256, 1h) stored on device in Android Keystore-backed secure storage.
- Privacy (FR-03): minimal data, explicit consent timestamp stored, self-service deletion.
