package middleware

import (
	"net/http"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
)

// RateLimiter is a simple token-bucket-style in-memory rate limiter per client IP.
type RateLimiter struct {
	mu       sync.Mutex
	clients  map[string]*clientBucket
	rate     time.Duration
	capacity int
	cleanup  time.Duration
}

type clientBucket struct {
	tokens   int
	lastSeen time.Time
}

// NewRateLimiter creates a rate limiter that allows `rate` burst of `capacity`
// per client. For example rate=time.Second and capacity=10 allows 10 req/s.
func NewRateLimiter(rate time.Duration, capacity int) *RateLimiter {
	r := &RateLimiter{
		clients:  make(map[string]*clientBucket),
		rate:     rate,
		capacity: capacity,
		cleanup:  time.Minute * 5,
	}
	go r.gcLoop()
	return r
}

func (r *RateLimiter) gcLoop() {
	ticker := time.NewTicker(r.cleanup)
	defer ticker.Stop()
	for range ticker.C {
		r.mu.Lock()
		cutoff := time.Now().Add(-r.cleanup)
		for ip, b := range r.clients {
			if b.lastSeen.Before(cutoff) {
				delete(r.clients, ip)
			}
		}
		r.mu.Unlock()
	}
}

func (r *RateLimiter) Middleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		ip := c.ClientIP()
		allowed := r.allow(ip)
		if !allowed {
			c.AbortWithStatusJSON(http.StatusTooManyRequests, gin.H{
				"success": false,
				"error":   "rate limit exceeded, please try again later",
			})
			return
		}
		c.Next()
	}
}

func (r *RateLimiter) allow(ip string) bool {
	r.mu.Lock()
	defer r.mu.Unlock()

	b, ok := r.clients[ip]
	if !ok {
		r.clients[ip] = &clientBucket{tokens: r.capacity - 1, lastSeen: time.Now()}
		return true
	}
	if time.Since(b.lastSeen) >= r.rate {
		b.tokens = r.capacity
	}
	if b.tokens <= 0 {
		b.lastSeen = time.Now()
		return false
	}
	b.tokens--
	b.lastSeen = time.Now()
	return true
}
