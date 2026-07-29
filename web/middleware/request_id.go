package middleware

import (
	"crypto/rand"
	"encoding/hex"
	"net/http"

	"github.com/gin-gonic/gin"
)

// RequestID middleware adds a unique X-Request-ID header to every response.
// It reads an existing X-Request-ID from the inbound request when present
// (useful when nginx injects one) and otherwise generates a fresh one.
func RequestID() gin.HandlerFunc {
	return func(c *gin.Context) {
		rid := c.GetHeader("X-Request-ID")
		if rid == "" {
			b := make([]byte, 8)
			_, err := rand.Read(b)
			if err == nil {
				rid = hex.EncodeToString(b)
			} else {
				rid = "0"
			}
		}
		c.Writer.Header().Set("X-Request-ID", rid)
		c.Set("request_id", rid)
		c.Next()
	}
}
