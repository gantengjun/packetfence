package aaa

import (
	"time"

	cache "github.com/patrickmn/go-cache"
)

type MemTokenBackend struct {
	store         *cache.Cache
	maxExpiration time.Duration
}

func NewMemTokenBackend(expiration time.Duration, maxExpiration time.Duration) *MemTokenBackend {
	return &MemTokenBackend{
		store:         cache.New(expiration, 10*time.Minute),
		maxExpiration: maxExpiration,
	}
}

func (mtb *MemTokenBackend) TokenIsValid(token string) bool {
	_, found := mtb.store.Get(token)
	return found
}

func (mtb *MemTokenBackend) TokenInfoForToken(token string) *TokenInfo {
	o, expiration, found := mtb.store.GetWithExpiration(token)
	if found {
		ti := o.(*TokenInfo)
		if time.Now().Sub(ti.CreatedAt) > mtb.maxExpiration {
			// Token has reached max expiration
			return nil
		}

		//TODO handle locking
		ti.ExpiresAt = expiration
		return ti
	} else {
		return nil
	}
}

func (mtb *MemTokenBackend) TenantIdForToken(token string) int {
	if ti := mtb.TokenInfoForToken(token); ti != nil {
		return ti.TenantId
	} else {
		return AccessNoTenants
	}
}

func (mtb *MemTokenBackend) AdminActionsForToken(token string) map[string]bool {
	if ti := mtb.TokenInfoForToken(token); ti != nil {
		return ti.AdminActions()
	} else {
		return make(map[string]bool)
	}
}

func (mtb *MemTokenBackend) StoreTokenInfo(token string, ti *TokenInfo) error {
	ti.CreatedAt = time.Now()
	mtb.store.SetDefault(token, ti)
	return nil
}

func (mtb *MemTokenBackend) TouchTokenInfo(token string) {
	if ti := mtb.TokenInfoForToken(token); ti != nil {
		mtb.store.SetDefault(token, ti)
	}
}
