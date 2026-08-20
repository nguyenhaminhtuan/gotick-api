# Gotick

Ticketing platform API.

## Local development

The toolchain is pinned in `mise.toml`; run `mise install` once. Everything else runs in Docker.

```bash
cp .env.example .env
docker compose up -d
make migrate-up
make run              # or: make watch
```

| Service                | URL                        |
| ---------------------- | -------------------------- |
| API                    | <http://localhost:8080/v1> |
| API reference (Scalar) | <http://localhost:8081>    |
| Auth emulator UI       | <http://localhost:4000>    |
| Postgres console       | <http://localhost:9876>    |

`./scripts/seed-auth-users.sh` creates three emulator users — `admin@`, `owner@` and `user@gotick.example`, all with password `password@123`. Each gets a verified email and a phone number, which is what `POST /me/profile` insists on.

`./scripts/idtoken.sh <email> <password>` prints an ID token for one of them.

## Granting platform staff

`/admin/*` is gated on the `staff` claim in the caller's token, and nothing in the API can grant it: the first owner has nobody to grant it to them, and there is no admin endpoint for it yet. `cmd/grant-staff` fills that gap. It writes the `platform_staff` row and stamps the matching claim, so the two never disagree.

**1. Create the account the ordinary way,** so it has to pass the same checks as everyone else's.

```bash
./scripts/idtoken.sh owner@gotick.example password@123
```

Open the [API reference](http://localhost:8081), paste that token into the authentication panel (`bearerAuth`), and send `POST /me/profile` with any `fullName`.

**2. Find the UID.** Open the [emulator UI](http://localhost:4000) → **Authentication**, and copy the account's **User UID**.

**3. Grant the role.**

```bash
go run ./cmd/grant-staff -uid=<uid> -role=owner
```

`-role` is `staff` unless you say otherwise. Re-running is safe: it reuses the account, writes the same role and re-stamps the claim, which is also how you repair a claim that went missing.

**4. Take a fresh token.** Claims live inside the token, so the one from step 1 still carries no role. Run `idtoken.sh` again, paste the new token into the API reference, and `GET /admin/staff` should answer 200 with the account listed.

### When the account does not exist yet

An identity created straight in the emulator UI — or in the Identity Platform console, for a deployed environment — has neither a verified email nor a phone, so it cannot get through `POST /me/profile` at all. `grant-staff` creates the account itself in that case, and then `-name` and `-phone` are required:

```bash
go run ./cmd/grant-staff -uid=<uid> -role=owner -name="Owner" -phone=+84900000000
```

This deliberately skips the checks every other account had to pass, which is right for an operator account and wrong for anyone who also buys tickets. Prefer step 1 wherever the identity can get through it.
