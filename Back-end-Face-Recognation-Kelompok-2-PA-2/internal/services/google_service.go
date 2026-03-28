// internal/services/google_service.go
package services

import (
	"context"
	"os"

	"google.golang.org/api/idtoken"
)

func VerifyGoogleToken(token string) (*idtoken.Payload, error) {

	payload, err := idtoken.Validate(
		context.Background(),
		token,
		os.Getenv("GOOGLE_CLIENT_ID"),
	)

	if err != nil {
		return nil, err
	}

	return payload, nil
}

// untuk memferivikasi id_token dari google 