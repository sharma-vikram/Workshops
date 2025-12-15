package main

import (
	"context"
	"crypto/ecdsa"
	"encoding/json"
	"fmt"
	"log"
	"math/big"
	"net/http"
	"os"
	"time"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/joho/godotenv"
)

type OracleNode struct {
	client          *ethclient.Client
	contract        *Oracle
	privateKey      *ecdsa.PrivateKey
	address         common.Address
	config          *Config
	contractAddress common.Address
	nodeID          int
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprintln(w, "Oracle Node is running")
}

type CoinPrice struct {
	USD float64 `json:"usd"`
}

func fetchPrice(coinID, apiKey string) (float64, error) {
	url := fmt.Sprintf("https://api.coingecko.com/api/v3/simple/price?ids=%s&vs_currencies=usd", coinID)
	client := http.Client{Timeout: 10 * time.Second}

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return 0, err
	}

	if apiKey != "" {
		req.Header.Set("x-cg-demo-api-key", apiKey)
	}

	resp, err := client.Do(req)
	if err != nil {
		return 0, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return 0, fmt.Errorf("API request failed with status: %d", resp.StatusCode)
	}

	var result map[string]CoinPrice
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return 0, err
	}

	if priceData, ok := result[coinID]; ok {
		return priceData.USD, nil
	}
	return 0, fmt.Errorf("coin not found")
}

func priceHandler(w http.ResponseWriter, r *http.Request) {
	coin := r.URL.Query().Get("coin")
	if coin == "" {
		http.Error(w, "Missing 'coin' query parameter", http.StatusBadRequest)
		return
	}

	price, err := fetchPrice(coin, "")
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to fetch price: %v", err), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"coin":     coin,
		"price":    price,
		"currency": "usd",
	})
}

// Convert float64 price to big.Int with 8 decimals precision
// Example: 50000.25 USD -> 5000025000000 (50000.25 * 10^8)
func floatToBigInt(price float64) *big.Int {
	// Multiply by 10^8 to preserve 8 decimal places
	scaled := price * 1e8
	bigFloat := new(big.Float).SetFloat64(scaled)
	bigInt := new(big.Int)
	bigFloat.Int(bigInt)
	return bigInt
}

// Initialize the Oracle Node
func NewOracleNode(config *Config, nodeID int) (*OracleNode, error) {
	// Connect to Ethereum node
	client, err := ethclient.Dial(config.RPCURL)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to Ethereum node: %v", err)
	}

	// Load private key
	privateKey, err := crypto.HexToECDSA(config.PrivateKey)
	if err != nil {
		return nil, fmt.Errorf("invalid private key: %v", err)
	}

	publicKey := privateKey.Public()
	publicKeyECDSA, ok := publicKey.(*ecdsa.PublicKey)
	if !ok {
		return nil, fmt.Errorf("error casting public key to ECDSA")
	}

	address := crypto.PubkeyToAddress(*publicKeyECDSA)
	contractAddress := common.HexToAddress(config.ContractAddress)

	// Create contract instance
	contract, err := NewOracle(contractAddress, client)
	if err != nil {
		return nil, fmt.Errorf("failed to instantiate contract: %v", err)
	}

	log.Printf("[Node %d] Oracle Node initialized", nodeID)
	log.Printf("[Node %d]   Address: %s", nodeID, address.Hex())
	log.Printf("[Node %d]   Contract: %s", nodeID, contractAddress.Hex())
	log.Printf("[Node %d]   RPC: %s", nodeID, config.RPCURL)

	node := &OracleNode{
		client:          client,
		contract:        contract,
		privateKey:      privateKey,
		address:         address,
		config:          config,
		contractAddress: contractAddress,
		nodeID:          nodeID,
	}

	// Check if node is already registered
	if err := node.EnsureRegistered(context.Background()); err != nil {
		return nil, fmt.Errorf("failed to register node: %v", err)
	}

	return node, nil
}

// EnsureRegistered checks if the node is registered and registers it if not
func (n *OracleNode) EnsureRegistered(ctx context.Context) error {
	// Check if already registered
	isRegistered, err := n.contract.OracleCaller.IsNode(&bind.CallOpts{}, n.address)
	if err != nil {
		return fmt.Errorf("failed to check if node is registered: %v", err)
	}

	if isRegistered {
		log.Printf("[Node %d] ✓ Already registered in Oracle", n.nodeID)
		return nil
	}

	log.Printf("[Node %d] ⚠ Not registered. Requesting to join Oracle...", n.nodeID)

	// Get the suggested gas price
	gasPrice, err := n.client.SuggestGasPrice(ctx)
	if err != nil {
		return fmt.Errorf("failed to suggest gas price: %v", err)
	}

	// Get nonce
	nonce, err := n.client.PendingNonceAt(ctx, n.address)
	if err != nil {
		return fmt.Errorf("failed to get nonce: %v", err)
	}

	// Get chain ID
	chainID, err := n.client.ChainID(ctx)
	if err != nil {
		return fmt.Errorf("failed to get chain ID: %v", err)
	}

	// Create transaction options
	auth, err := bind.NewKeyedTransactorWithChainID(n.privateKey, chainID)
	if err != nil {
		return fmt.Errorf("failed to create transactor: %v", err)
	}

	auth.Nonce = big.NewInt(int64(nonce))
	auth.Value = big.NewInt(0)
	auth.GasLimit = uint64(100000)
	auth.GasPrice = gasPrice

	// Call addNode() to register
	tx, err := n.contract.OracleTransactor.AddNode(auth)
	if err != nil {
		return fmt.Errorf("failed to register node: %v", err)
	}

	log.Printf("[Node %d] Registration tx: %s", n.nodeID, tx.Hash().Hex())
	log.Printf("[Node %d] Waiting for confirmation...", n.nodeID)

	// Wait for transaction to be mined
	receipt, err := bind.WaitMined(ctx, n.client, tx)
	if err != nil {
		return fmt.Errorf("registration transaction failed: %v", err)
	}

	if receipt.Status == 1 {
		log.Printf("[Node %d] ✓ Successfully registered! Block: %d, Gas: %d",
			n.nodeID, receipt.BlockNumber.Uint64(), receipt.GasUsed)
	} else {
		return fmt.Errorf("registration transaction reverted")
	}

	return nil
}

// Submit price for a specific coin
func (n *OracleNode) SubmitPrice(ctx context.Context, coin string) error {
	// Fetch price from CoinGecko
	price, err := fetchPrice(coin, n.config.CoingeckoApiKey)
	if err != nil {
		return fmt.Errorf("failed to fetch price for %s: %v", coin, err)
	}

	// Convert to big.Int with 8 decimals
	priceInt := floatToBigInt(price)

	log.Printf("[Node %d] Fetched %s: $%.2f", n.nodeID, coin, price)

	// Get the suggested gas price
	gasPrice, err := n.client.SuggestGasPrice(ctx)
	if err != nil {
		return fmt.Errorf("failed to suggest gas price: %v", err)
	}

	// Get nonce
	nonce, err := n.client.PendingNonceAt(ctx, n.address)
	if err != nil {
		return fmt.Errorf("failed to get nonce: %v", err)
	}

	// Get chain ID
	chainID, err := n.client.ChainID(ctx)
	if err != nil {
		return fmt.Errorf("failed to get chain ID: %v", err)
	}

	// Create transaction options
	auth, err := bind.NewKeyedTransactorWithChainID(n.privateKey, chainID)
	if err != nil {
		return fmt.Errorf("failed to create transactor: %v", err)
	}

	auth.Nonce = big.NewInt(int64(nonce))
	auth.Value = big.NewInt(0)
	auth.GasLimit = uint64(300000)
	auth.GasPrice = gasPrice

	// Submit price to contract
	tx, err := n.contract.OracleTransactor.SubmitPrice(auth, coin, priceInt)
	if err != nil {
		return fmt.Errorf("failed to submit price: %v", err)
	}

	log.Printf("[Node %d] Submitting %s tx: %s", n.nodeID, coin, tx.Hash().Hex())

	// Wait for transaction to be mined
	receipt, err := bind.WaitMined(ctx, n.client, tx)
	if err != nil {
		return fmt.Errorf("transaction failed: %v", err)
	}

	if receipt.Status == 1 {
		log.Printf("[Node %d] ✓ %s submitted! Block: %d, Gas: %d",
			n.nodeID, coin, receipt.BlockNumber.Uint64(), receipt.GasUsed)
	} else {
		return fmt.Errorf("transaction reverted")
	}

	return nil
}

// Start automatic price submission loop
func (n *OracleNode) StartPriceSubmissionLoop(ctx context.Context) {
	ticker := time.NewTicker(time.Duration(n.config.SubmissionInterval) * time.Second)
	defer ticker.Stop()

	log.Printf("[Node %d] Starting submission loop (interval: %ds)", n.nodeID, n.config.SubmissionInterval)
	log.Printf("[Node %d] Tracking coins: %v", n.nodeID, n.config.Coins)

	// Removed staggered delay to allow simultaneous submission
	// initialDelay := time.Duration(n.nodeID*8) * time.Second ...

	// Submit prices immediately on start
	for _, coin := range n.config.Coins {
		if err := n.SubmitPrice(ctx, coin); err != nil {
			log.Printf("[Node %d] Error submitting %s: %v", n.nodeID, coin, err)
		}
		// Add delay between coins to avoid rate limits (1 second)
		time.Sleep(1 * time.Second)
	}

	// Then submit on interval
	for {
		select {
		case <-ctx.Done():
			log.Printf("[Node %d] Stopping submission loop", n.nodeID)
			return
		case <-ticker.C:
			for _, coin := range n.config.Coins {
				if err := n.SubmitPrice(ctx, coin); err != nil {
					log.Printf("[Node %d] Error submitting %s: %v", n.nodeID, coin, err)
				}
				// Add delay between coins to avoid rate limits (1 second)
				time.Sleep(1 * time.Second)
			}
		}
	}
}

func main() {
	// Load .env file if it exists
	if err := godotenv.Load(); err != nil {
		log.Printf("Note: No .env file found, using environment variables")
	}

	config := LoadConfig()

	// Anvil default private keys (first 10 accounts)
	anvilPrivateKeys := []string{
		"ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80", // Account 0
		"59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d", // Account 1
		"5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a", // Account 2
		"7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6", // Account 3
		"47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a", // Account 4
		"8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba", // Account 5
		"92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e", // Account 6
		"4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356", // Account 7
		"dbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97", // Account 8
		"2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6", // Account 9
	}

	ctx := context.Background()

	log.Printf("========================================")
	log.Printf("========================================")
	log.Printf("Starting 4 Oracle Nodes (Sharing 3 API Keys)")
	log.Printf("========================================\n")

	// API Key for CoinGecko
	apiKey := os.Getenv("COINGECKO_API_KEY")
	if apiKey == "" {
		log.Printf("⚠️  WARNING: COINGECKO_API_KEY not set, requests will use free tier")
	} else {
		log.Printf("✅ CoinGecko API Key loaded (length: %d)", len(apiKey))
	}

	// Launch 4 nodes concurrently
	for i := 0; i < 4; i++ {
		nodeID := i
		privateKey := anvilPrivateKeys[i]
		httpPort := fmt.Sprintf(":808%d", i)

		// Create a config for each node
		nodeConfig := &Config{
			RPCURL:             config.RPCURL,
			ContractAddress:    config.ContractAddress,
			PrivateKey:         privateKey,
			Coins:              config.Coins,
			SubmissionInterval: config.SubmissionInterval,
			HTTPPort:           httpPort,
			CoingeckoApiKey:    apiKey,
		}

		// Launch each node in a goroutine
		go func(id int, cfg *Config) {
			log.Printf("\n[Node %d] Initializing...", id)

			// Initialize Oracle Node
			oracleNode, err := NewOracleNode(cfg, id)
			if err != nil {
				log.Printf("[Node %d] Failed to initialize: %v", id, err)
				return
			}

			// Start HTTP server
			go func() {
				mux := http.NewServeMux()
				mux.HandleFunc("/health", healthHandler)
				mux.HandleFunc("/price", priceHandler)

				log.Printf("[Node %d] Starting HTTP server on %s", id, cfg.HTTPPort)
				if err := http.ListenAndServe(cfg.HTTPPort, mux); err != nil {
					log.Printf("[Node %d] HTTP server error: %v", id, err)
				}
			}()

			// Start price submission loop
			oracleNode.StartPriceSubmissionLoop(ctx)
		}(nodeID, nodeConfig)
	}

	// Keep main thread alive
	log.Printf("\n========================================")
	log.Printf("All 4 nodes launched successfully!")
	log.Printf("HTTP Ports: 8080-8083")
	log.Printf("Press Ctrl+C to stop all nodes")
	log.Printf("========================================\n")

	select {} // Block forever
}
