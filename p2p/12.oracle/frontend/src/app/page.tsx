"use client";

import { useState, useEffect } from "react";
import { ethers } from "ethers";
import Header from "@/components/Header";
import PriceCard from "@/components/PriceCard";
import Footer from "@/components/Footer";
import BackgroundDecoration from "@/components/BackgroundDecoration";

interface EventLog {
  id: string;
  coin: string;
  price: string;
  roundId: string;
  timestamp: Date;
  exiting?: boolean;
}

const ORACLE_ABI = [
  {
    "inputs": [{ "internalType": "string", "name": "", "type": "string" }],
    "name": "currentPrices",
    "outputs": [{ "internalType": "uint256", "name": "", "type": "uint256" }],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "anonymous": false,
    "inputs": [
      { "indexed": false, "internalType": "string", "name": "coin", "type": "string" },
      { "indexed": false, "internalType": "uint256", "name": "price", "type": "uint256" },
      { "indexed": false, "internalType": "uint256", "name": "roundId", "type": "uint256" }
    ],
    "name": "PriceUpdated",
    "type": "event"
  }
];

const ORACLE_ADDRESS = process.env.NEXT_PUBLIC_ORACLE_ADDRESS || "";

interface Coin {
  id: string;
  symbol: string;
  name: string;
  color: string;
  initial: string;
  logoUrl: string;
}

const COINS: Coin[] = [
  { id: "ethereum", symbol: "ETH", name: "Ethereum", color: "#627EEA", initial: "E", logoUrl: "https://assets.coincap.io/assets/icons/eth@2x.png" }
];

const COIN_IDS = COINS.map(c => c.id);

declare global {
  interface Window {
    ethereum?: any;
  }
}

export default function Home() {
  const [prices, setPrices] = useState<Record<string, string>>({});
  const [walletAddress, setWalletAddress] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [selectedCoin, setSelectedCoin] = useState<Coin>(COINS[0]);
  const [eventLogs, setEventLogs] = useState<EventLog[]>([]);
  const [priceUpdated, setPriceUpdated] = useState(false);

  const connectWallet = async () => {
    if (typeof window !== "undefined" && window.ethereum) {
      try {
        const provider = new ethers.BrowserProvider(window.ethereum);
        const accounts = await provider.send("eth_requestAccounts", []);
        setWalletAddress(accounts[0]);
      } catch (error) {
        console.error("Error connecting wallet:", error);
      }
    } else {
      alert("Please install MetaMask!");
    }
  };

  const formatPrice = (priceWei: string): string => {
    try {
      if (!priceWei || priceWei === '0' || priceWei === '0.00') {
        return '0.00';
      }
      // Prix stocké avec 8 décimales: diviser par 10^8
      const priceBigInt = BigInt(priceWei);
      const priceFloat = Number(priceBigInt) / 1e8;
      return priceFloat.toLocaleString("en-US", {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
      });
    } catch (error) {
      console.error('Error formatting price:', error, priceWei);
      return '0.00';
    }
  };

  const fetchAllPrices = async () => {
    if (!ORACLE_ADDRESS || ORACLE_ADDRESS === "0x0000000000000000000000000000000000000000") {
      console.warn("Oracle address not set");
      return;
    }

    setLoading(true);
    try {
      let provider;
      if (typeof window !== "undefined" && window.ethereum) {
        provider = new ethers.BrowserProvider(window.ethereum);
      } else {
        provider = new ethers.JsonRpcProvider("http://127.0.0.1:8545");
      }

      const contract = new ethers.Contract(ORACLE_ADDRESS, ORACLE_ABI, provider);

      const newPrices: Record<string, string> = {};
      for (const coin of COIN_IDS) {
        try {
          const priceData = await contract.currentPrices(coin);
          newPrices[coin] = priceData.toString();
        } catch (error) {
          console.error(`Error fetching price for ${coin}:`, error);
          newPrices[coin] = "0";
        }
      }

      setPrices(newPrices);
    } catch (error) {
      console.error("Error fetching prices:", error);
    } finally {
      setLoading(false);
    }
  };

  const setupEventListener = async () => {
    if (!ORACLE_ADDRESS || ORACLE_ADDRESS === "0x0000000000000000000000000000000000000000") {
      return;
    }

    try {
      // Always use JsonRpcProvider for local events to ensure we catch them
      // regardless of what network MetaMask is connected to.
      const provider = new ethers.JsonRpcProvider("http://127.0.0.1:8545");
      provider.pollingInterval = 1000; 

      const contract = new ethers.Contract(ORACLE_ADDRESS, ORACLE_ABI, provider);

      // Listen for PriceUpdated events
      contract.on("PriceUpdated", (coin: string, price: bigint, roundId: bigint) => {
        const formattedPrice = formatPrice(price.toString());
        
        // Add event to log (toast notification)
        const newEvent: EventLog = {
          id: `${Date.now()}-${Math.random()}`,
          coin,
          price: formattedPrice,
          roundId: roundId.toString(),
          timestamp: new Date(),
        };
        
        setEventLogs(prev => [newEvent, ...prev].slice(0, 5));
        
        // Auto-remove toast after 4 seconds
        setTimeout(() => {
          setEventLogs(prev => 
            prev.map(e => e.id === newEvent.id ? { ...e, exiting: true } : e)
          );
          setTimeout(() => {
            setEventLogs(prev => prev.filter(e => e.id !== newEvent.id));
          }, 300);
        }, 4000);

        // Trigger price animation
        setPriceUpdated(true);
        setTimeout(() => setPriceUpdated(false), 600);

        // Update the price for this coin
        setPrices(prev => ({
          ...prev,
          [coin]: price.toString()
        }));
      });

      console.log("✓ Event listener setup complete");
    } catch (error) {
      console.error("Error setting up event listener:", error);
    }
  };

  useEffect(() => {
    fetchAllPrices();
    setupEventListener();
    const interval = setInterval(fetchAllPrices, 10000); // Refresh every 10s
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="h-screen w-full overflow-hidden flex flex-col selection:bg-primary selection:text-background-dark relative">
      <BackgroundDecoration />
      <Header/>

      {/* Toast Notifications */}
      <div className="fixed top-4 right-4 z-50 flex flex-col gap-2">
        {eventLogs.map((event) => (
          <div
            key={event.id}
            className={`${event.exiting ? 'toast-exit' : 'toast-enter'} flex items-center gap-3 bg-card-dark border border-primary/30 rounded-xl px-4 py-3 shadow-lg shadow-primary/10`}
          >
            <div className="w-2 h-2 rounded-full bg-primary animate-pulse" />
            <div className="flex flex-col">
              <span className="text-xs text-slate-400">
                Round #{event.roundId}
              </span>
              <span className="text-sm font-semibold text-white">
                {event.coin.toUpperCase()} → ${event.price}
              </span>
            </div>
            <span className="text-xs text-slate-500 ml-2">
              {event.timestamp.toLocaleTimeString()}
            </span>
          </div>
        ))}
      </div>

      {/* Main Content Centered */}
      <main className="relative z-10 flex-1 flex flex-col items-center justify-center p-4 sm:p-6">
        <PriceCard
          price={formatPrice(prices[selectedCoin.id] || "0")}
          selectedCoin={selectedCoin}
          isUpdating={priceUpdated}
        />
      </main>

      <Footer />
    </div>
  );
}
