# Baz - Node.js Server

A simple Express.js server that responds with "hello".

## Running the server

```bash
npm start
# or
npm run dev
```

The server will run on port 3000 by default.

## Endpoints

- `GET /` - Returns `{"message": "hello"}`
- `GET /health` - Returns `{"status": "ok", "service": "baz"}`
