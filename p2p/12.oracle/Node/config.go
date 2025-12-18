package main

import (
	"os"
)

type Config struct {
	// Ethereum RPC URL (ex: http://localhost:8545 or Infura/Alchemy)
	RPCURL string

	// Oracle contract address
	ContractAddress string

	// Node private key (without 0x prefix)
	PrivateKey string

	// CoinGecko coin IDs to track
	Coins []string

	// Submission interval in seconds
	SubmissionInterval int

	// HTTP server port
	HTTPPort string

	// CoinGecko API Key
	CoingeckoApiKey string
}

func LoadConfig() *Config {
	rpcURL := os.Getenv("RPC_URL")
	if rpcURL == "" {
		rpcURL = "http://localhost:8545" // Default to local Anvil/Hardhat
	}
	contractAddr := os.Getenv("CONTRACT_ADDRESS")
	if contractAddr == "" {
		contractAddr = "0x5FbDB2315678afecb367f032d93F642f64180aa3" // Default Anvil first deployment
	}

	privateKey := os.Getenv("PRIVATE_KEY")
	if privateKey == "" {
		// Default Anvil test key (DO NOT USE IN PRODUCTION)
		privateKey = "ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
	}

	httpPort := os.Getenv("HTTP_PORT")
	if httpPort == "" {
		httpPort = ":8080"
	}

	return &Config{
		RPCURL:          rpcURL,
		ContractAddress: contractAddr,
		PrivateKey:      privateKey,
		Coins:           []string{"ethereum"},
		SubmissionInterval: 20,
		HTTPPort:        httpPort,
	}
}
