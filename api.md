# Authentication Endpoints

## 1. Login Endpoint

### Endpoint

`POST /api/v1/auth/login`

### Headers

- `Content-Type: application/json`

### Request Body

```json
{
  "username": "string",
  "password": "string"
}
```

### Response

#### Success (200)

```json
{
  "access_token": "string",
  "refresh_token": "string",
  "role_name": "string"
}
```

#### Error (401)

```json
{
  "detail": "Invalid credentials"
}
```

---

## 2. Register Endpoint

### Endpoint

`POST /api/v1/auth/citizen-register`

### Headers

- `Content-Type: application/json`

### Request Body

```json
{
  "username": "string",
  "password": "string",
  "name": "string",
  "phone_number": "string",
  "email": "string",
  "home_address": "string"
}
```

### Response

#### Success (200)

```json
{
  "is_verified": true,
  "access_token": "string",
  "refresh_token": "string",
  "role_name": "citizen"
}
```

#### Error (400)

```json
{
  "detail": "User already exists"
}
```

---

## 3. Refresh Token Endpoint

### Endpoint

`POST /api/v1/auth/refresh`

### Headers

- `Content-Type: application/json`

### Request Body

```json
{
  "refresh_token": "string"
}
```

### Response

#### Success (200)

```json
{
  "access_token": "string",
  "refresh_token": "string",
  "role_name": "string"
}
```

#### Error (401)

```json
{
  "detail": "Invalid or expired token"
}
```

---
