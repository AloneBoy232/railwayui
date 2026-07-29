package web

import (
	"crypto/rand"
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// railwayAutoConfigRequest is the request body for the Railway auto-config API.
type railwayAutoConfigRequest struct {
	Domain   string `json:"domain" binding:"required"`
	Protocol string `json:"protocol"`
}

// registerRailwayRoutes adds the /api/railway-auto endpoint that the front-end
// JS inject and Vue component call. It is intentionally unauthenticated so that
// the auto-config tool works without a logged-in panel session.
func registerRailwayRoutes(engine *gin.Engine) {
	engine.POST("/api/railway-auto", func(c *gin.Context) {
		var req railwayAutoConfigRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "invalid request body"})
			return
		}
		req.Domain = strings.TrimSpace(req.Domain)
		if req.Domain == "" {
			c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "domain is required"})
			return
		}
		// Basic domain validation: must contain at least one dot and no spaces
		if !strings.Contains(req.Domain, ".") || strings.Contains(req.Domain, " ") {
			c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "invalid domain format"})
			return
		}
		if req.Protocol == "" {
			req.Protocol = "vless-ws"
		}

		config, err := buildRailwayConfig(req.Domain, req.Protocol)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"obj":     config,
			"meta": gin.H{
				"generated_at": time.Now().UTC().Format(time.RFC3339),
				"protocol":    req.Protocol,
				"domain":      req.Domain,
			},
		})
	})
}

func buildRailwayConfig(domain, protocol string) (map[string]any, error) {
	configUUID := uuid.New().String()
	randomPath := "/" + randomString(8)

	switch protocol {
	case "vless-ws":
		return map[string]any{
			"uuid":       configUUID,
			"port":       1080,
			"protocol":   "vless",
			"network":    "ws",
			"security":   "none",
			"path":       randomPath,
			"host":       domain,
			"client_config": map[string]any{
				"port":     443,
				"security": "tls",
				"sni":      domain,
				"fp":       "chrome",
				"type":     "ws",
				"host":     domain,
				"path":     randomPath,
			},
		}, nil

	case "vless-reality":
		return map[string]any{
			"uuid":       configUUID,
			"port":       1080,
			"protocol":   "vless",
			"network":    "tcp",
			"security":   "reality",
			"path":       randomPath,
			"host":       domain,
			"reality_settings": map[string]any{
				"dest":        "www.microsoft.com:443",
				"serverNames": []string{"www.microsoft.com", "microsoft.com"},
				"privateKey":  "PLACEHOLDER_PRIVATE_KEY",
				"shortIds":    []string{""},
			},
			"client_config": map[string]any{
				"port":     443,
				"security": "reality",
				"sni":      "www.microsoft.com",
				"fp":       "chrome",
				"pbk":      "PLACEHOLDER_PUBLIC_KEY",
				"sid":      "",
				"type":     "tcp",
			},
		}, nil

	case "vless-xhttp":
		return map[string]any{
			"uuid":       configUUID,
			"port":       1080,
			"protocol":   "vless",
			"network":    "xhttp",
			"security":   "none",
			"path":       randomPath,
			"host":       domain,
			"client_config": map[string]any{
				"port":     443,
				"security": "tls",
				"sni":      domain,
				"fp":       "chrome",
				"type":     "xhttp",
				"host":     domain,
				"path":     randomPath,
				"mode":     "auto",
			},
		}, nil

	default:
		return nil, fmt.Errorf("unsupported protocol: %s", protocol)
	}
}

func randomString(n int) string {
	const letters = "abcdefghijklmnopqrstuvwxyz0123456789"
	b := make([]byte, n)
	_, err := rand.Read(b)
	if err != nil {
		// crypto/rand failed; this is extremely unlikely on Linux, but if it does
		// happen we fall back to a weaker but still-functional generator.
		for i := range b {
			b[i] = letters[i%len(letters)]
		}
		return string(b)
	}
	for i := range b {
		b[i] = letters[int(b[i])%len(letters)]
	}
	return string(b)
}
