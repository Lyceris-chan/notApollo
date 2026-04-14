# notApollo API Documentation

## Overview

The notApollo API provides comprehensive network diagnostic data through RESTful endpoints.

## Endpoints

### System Health
- `GET /api/diagnostics.sh` - Complete diagnostic data
- `GET /api/system.sh` - System health and status
- `POST /api/reboot.sh` - Safe router reboot with countdown

### Network Diagnostics
- `GET /api/dns.sh` - DNS health with cache optimization
- `GET /api/ont.sh` - ONT/Fiber guidance and status

## Response Format

All endpoints return JSON with the following structure:

```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "status": "healthy|degraded|broken",
  "user_friendly_status": "Everything is working great!",
  "data": {
    // Endpoint-specific data
  }
}
```

## Error Handling

- HTTP 200: Success
- HTTP 400: Bad Request (invalid parameters)
- HTTP 429: Too Many Requests (rate limited)
- HTTP 500: Internal Server Error

## Rate Limiting

- API endpoints: 10 requests per minute per IP
- Burst allowance: 5 requests
- DNS endpoints: Smart limiting based on cache performance

## Security

- Input validation on all parameters
- Command injection protection
- Rate limiting and abuse prevention
- Secure error handling without information disclosure