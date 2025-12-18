"use client";

interface Coin {
  id: string;
  symbol: string;
  name: string;
  color: string;
  initial: string;
  logoUrl: string;
}

interface PriceCardProps {
  price: string;
  selectedCoin: Coin;
  isUpdating?: boolean;
}

export default function PriceCard({ price, selectedCoin, isUpdating }: PriceCardProps) {
  return (
    <div className={`w-full max-w-[480px] bg-white dark:bg-card-dark border border-slate-200 dark:border-border-dark rounded-2xl sm:rounded-3xl shadow-glow p-2 flex flex-col gap-1 transition-all ${isUpdating ? 'price-updated border-primary/50' : ''}`}>
      {/* Top Section: Header & Settings */}
      <div className="flex items-center justify-start px-4 py-2">
        <span className="text-slate-500 dark:text-slate-400 font-medium text-sm">Real-time Price</span>
      </div>
      
      {/* Input / Selection Area */}
      <div className="relative bg-slate-50 dark:bg-black/20 rounded-xl sm:rounded-2xl p-4 sm:p-5 border border-transparent focus-within:border-primary/30 transition-all group">
        <div className="flex items-center justify-between gap-4 mb-2">
          <div className="relative">
            <div
              className="flex items-center gap-2 bg-white dark:bg-slate-800 shadow-sm border border-slate-200 dark:border-slate-700 rounded-full py-1.5 pl-2 pr-3 transition-colors group/token"
            >
              <img
                src={selectedCoin.logoUrl}
                alt={selectedCoin.name}
                className="w-6 h-6 rounded-full"
              />
              <span className="font-semibold text-lg">{selectedCoin.symbol}</span>
            </div>
          </div>
          {/* Search Input masquerading as part of the header */}
          <div className="flex-1 flex justify-end">
            <span className="text-xs font-medium text-slate-400 bg-slate-200 dark:bg-slate-800 px-2 py-1 rounded-md">{selectedCoin.name}</span>
          </div>
        </div>
        
        {/* Big Price Display */}
        <div className="mt-4 flex flex-col items-start">
          <div className={`text-5xl pb-30 sm:text-[64px] font-bold tracking-tight leading-none transition-colors duration-300 ${isUpdating ? 'text-primary' : 'text-slate-900 dark:text-white'}`}>
            ${price}
          </div>
        </div>

        {/* Abstract Chart Background inside the card area */}
        <div className="absolute bottom-0 right-0 w-[99%] h-1/2 opacity-20 pointer-events-none overflow-hidden rounded-br-2xl">
          <svg className="w-full h-full text-primary" preserveAspectRatio="none" viewBox="0 0 200 100">
            <path d="M0 80 Q 20 70, 40 75 T 80 50 T 120 40 T 160 20 T 200 5 L 200 100 L 0 100 Z" fill="url(#gradient)"></path>
            <path className="path-anim" d="M0 80 Q 20 70, 40 75 T 80 50 T 120 40 T 160 20 T 200 5" fill="none" stroke="currentColor" strokeWidth="3"></path>
            <defs>
              <linearGradient id="gradient" x1="0" x2="0" y1="0" y2="1">
                <stop offset="0%" stopColor="currentColor"></stop>
                <stop offset="100%" stopColor="currentColor" stopOpacity="0"></stop>
              </linearGradient>
            </defs>
          </svg>
        </div>
      </div>
    </div>
  );
}
