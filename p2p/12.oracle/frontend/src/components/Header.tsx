"use client";

export default function Header() {
  return (
    <header className="relative z-10 w-full px-6 py-4 flex items-center justify-between">
      <div className="flex items-center gap-3">
        <div className="size-8 text-primary flex items-center justify-center">
          <svg className="w-full h-full drop-shadow-[0_0_8px_rgba(43,238,121,0.5)]" fill="none" viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
            <path d="M24 4L29.2 14.6L40.6 15.6L32 23.2L34.6 34.4L24 28.2L13.4 34.4L16 23.2L7.4 15.6L18.8 14.6L24 4Z" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" strokeWidth="3"></path>
          </svg>
        </div>
        <h1 className="text-xl font-bold tracking-tight hidden sm:block">PoC Innovation</h1>
      </div>
      <div className="flex items-center gap-4">
        <button 
          onClick={() => window.location.href = "https://www.poc-innovation.fr"}
          className="bg-primary/10 cursor-pointer hover:bg-primary/20 text-primary border border-primary/20 hover:border-primary/50 transition-all duration-300 h-10 px-5 rounded-full text-sm font-bold flex items-center gap-2"
        >
          <span className="truncate">PoC Website</span>
        </button>
      </div>
    </header>
  );
}
