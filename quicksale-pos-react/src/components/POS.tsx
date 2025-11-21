import React, { useState, useEffect, useRef } from 'react';
import { Product, CartItem, Sale } from '../types';
import { saveSale } from '../services/storageService';
import { Search, ShoppingCart, Trash2, Plus, Minus, CreditCard, Banknote, ScanBarcode, ArrowLeft, ChevronUp, X, CheckCircle, Package } from 'lucide-react';
import { jsPDF } from 'jspdf';

interface POSProps {
  products: Product[];
  refreshData: () => void;
}

const Numpad = ({ onInput, onDelete, onClear }: { onInput: (n: string) => void, onDelete: () => void, onClear: () => void }) => (
  <div className="grid grid-cols-3 gap-1">
    {['1', '2', '3', '4', '5', '6', '7', '8', '9', 'C', '0', '.'].map(key => (
      <button 
        key={key} 
        onClick={() => key === 'C' ? onClear() : onInput(key)}
        className={`rounded-lg h-14 text-xl font-semibold transition-colors ${key === 'C' ? 'bg-rose-100 text-rose-600' : 'bg-slate-100 hover:bg-slate-200 text-slate-800'}`}
      >
        {key}
      </button>
    ))}
    <button onClick={onDelete} className="rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-800 flex items-center justify-center">
      <ArrowLeft size={20} strokeWidth={2.5} />
    </button>
  </div>
);

const POS: React.FC<POSProps> = ({ products, refreshData }) => {
  const [cart, setCart] = useState<CartItem[]>([]);
  const [search, setSearch] = useState('');
  const [showScanner, setShowScanner] = useState(false);
  const [selectedItemId, setSelectedItemId] = useState<string | null>(null);
  const [showMobileCart, setShowMobileCart] = useState(false);
  const [showSuccessModal, setShowSuccessModal] = useState(false);
  const [input, setInput] = useState('');

  const videoRef = useRef<HTMLVideoElement>(null);

  useEffect(() => {
    if (showSuccessModal) {
      const timer = setTimeout(() => setShowSuccessModal(false), 2000);
      return () => clearTimeout(timer);
    }
  }, [showSuccessModal]);

  const addToCart = (product: Product) => {
    if (product.stock <= 0) return;
    setCart(prev => {
      const existingItem = prev.find(item => item.id === product.id);
      if (existingItem) {
        return prev.map(item =>
          item.id === product.id ? { ...item, quantity: Math.min(item.quantity + 1, product.stock) } : item
        );
      }
      const newItemId = product.id;
      setSelectedItemId(newItemId);
      setInput('1');
      return [...prev, { ...product, quantity: 1 }];
    });
    setSearch('');
  };

  const updateQuantity = (id: string, newQty: number) => {
    if (newQty < 0) return;
    setCart(prev =>
      prev.map(item => {
        if (item.id === id) {
          if (newQty === 0) return { ...item, quantity: 1 }; // Prevent quantity from being 0
          const product = products.find(p => p.id === id);
          const maxStock = product ? product.stock : item.quantity;
          return { ...item, quantity: Math.min(newQty, maxStock) };
        }
        return item;
      })
    );
  };

  const removeFromCart = (id: string) => {
    setCart(prev => prev.filter(item => item.id !== id));
    if (selectedItemId === id) setSelectedItemId(null);
    if (cart.length <= 1) setShowMobileCart(false);
  };

  useEffect(() => {
    if (selectedItemId) {
      const numValue = parseFloat(input);
      if (!isNaN(numValue)) {
        updateQuantity(selectedItemId, numValue);
      }
    }
  }, [input, selectedItemId]);
  
  const handleNumpadInput = (val: string) => setInput(prev => prev + val);
  const handleNumpadDelete = () => setInput(prev => prev.slice(0, -1));
  const handleNumpadClear = () => setInput('');

  const selectItem = (item: CartItem) => {
    setSelectedItemId(item.id);
    setInput(item.quantity.toString());
  }

  const total = cart.reduce((sum, item) => sum + (item.price * item.quantity), 0);

  const handlePayment = (method: 'cash' | 'card') => {
    if (cart.length === 0) return;
    const newSale: Sale = { id: Date.now().toString(), date: new Date().toISOString(), total, items: cart, paymentMethod: method };
    saveSale(newSale);
    generateReceipt(newSale);
    setCart([]);
    setSelectedItemId(null);
    setShowMobileCart(false);
    refreshData();
    setShowSuccessModal(true);
  };

  const generateReceipt = (sale: Sale) => {
    const doc = new jsPDF({ orientation: 'portrait', unit: 'mm', format: [80, 150] });
    doc.setFontSize(10);
    doc.text("QuickSale POS", 40, 10, { align: "center" });
    doc.text("--------------------------------", 40, 15, { align: "center" });
    let y = 20;
    sale.items.forEach(item => {
      doc.text(`${item.quantity}x ${item.name}`, 5, y);
      doc.text(`$${(item.price * item.quantity).toFixed(2)}`, 75, y, { align: 'right' });
      y += 5;
    });
    doc.text("--------------------------------", 40, y, { align: "center" });
    y += 5;
    doc.setFontSize(12);
    doc.text('TOTAL:', 5, y);
    doc.text(`$${sale.total.toFixed(2)}`, 75, y, { align: 'right' });
    doc.save(`recibo_${sale.id}.pdf`);
  };
  
  const simulateScan = () => {
    if (products.length > 0) {
      const randomProduct = products[Math.floor(Math.random() * products.length)];
      addToCart(randomProduct);
      setShowScanner(false);
    }
  };

  const filteredProducts = products.filter(p =>
    p.name.toLowerCase().includes(search.toLowerCase()) ||
    p.barcode.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="h-full flex flex-col md:flex-row overflow-hidden bg-white relative">
      {/* Product Grid & Search */}
      <div className="flex-1 flex flex-col p-4 md:p-6 overflow-hidden">
        <div className="flex gap-4 mb-4">
          <div className="relative flex-1">
            <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Buscar producto o escanear código..."
              className="w-full bg-slate-50 border border-slate-200 rounded-lg pl-10 pr-4 py-2.5 text-sm"
            />
          </div>
          <button onClick={() => setShowScanner(true)} className="p-2.5 bg-slate-50 border border-slate-200 rounded-lg text-slate-600 hover:bg-slate-100">
            <ScanBarcode size={20} />
          </button>
        </div>
        <div className="flex-1 overflow-y-auto -m-2 p-2">
          <div className="grid grid-cols-3 sm:grid-cols-3 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-3">
            {filteredProducts.map(p => (
              <button
                key={p.id}
                onClick={() => addToCart(p)}
                disabled={p.stock <= 0}
                className="bg-white rounded-lg border border-slate-200/80 p-2 text-center flex flex-col justify-between items-center active:scale-95 transition-transform disabled:opacity-40 disabled:cursor-not-allowed group"
              >
                <div className="w-full h-16 bg-slate-50 rounded-md mb-2 flex items-center justify-center relative overflow-hidden">
                  {p.imageUrl ? <img src={p.imageUrl} alt={p.name} className="w-full h-full object-cover" /> : <Package size={24} className="text-slate-300" />}
                  <div className="absolute inset-0 bg-black/40 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                    <Plus size={24} className="text-white"/>
                  </div>
                </div>
                <span className="font-semibold text-xs text-slate-700 leading-tight line-clamp-2">{p.name}</span>
                <span className="font-bold text-sm text-slate-900">${p.price.toFixed(2)}</span>
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Cart Section */}
      <div className={`fixed md:static bottom-0 left-0 right-0 md:w-[380px] lg:w-[420px] bg-slate-50/80 backdrop-blur-sm border-l border-slate-200 flex flex-col transition-transform duration-300 ease-in-out ${showMobileCart || cart.length === 0 ? 'translate-y-0' : 'translate-y-[calc(100%-150px)] md:translate-y-0'}`}>
        <div className="md:hidden p-3 bg-white/80 backdrop-blur-sm border-b border-t border-slate-200 text-center" onClick={() => setShowMobileCart(!showMobileCart)}>
          <ChevronUp className={`mx-auto transition-transform size-5 ${showMobileCart ? 'rotate-180' : ''}`} />
          <span className="font-semibold text-sm">Ver Carrito ({cart.length}) - Total: ${total.toFixed(2)}</span>
        </div>

        <div className="flex-1 flex flex-col overflow-hidden">
          <div className="p-4 flex justify-between items-center border-b border-slate-200">
            <h2 className="text-lg font-bold text-slate-800 flex items-center gap-2"><ShoppingCart size={20}/> Carrito</h2>
            {cart.length > 0 && <button onClick={() => setCart([])} className="text-xs text-slate-500 hover:text-red-500 font-semibold">Vaciar</button>}
          </div>

          <div className="flex-1 overflow-y-auto p-2 space-y-1.5">
            {cart.length === 0 ? (
              <p className="text-center text-slate-500 text-sm py-10">El carrito está vacío</p>
            ) : (
              cart.map(item => (
                <div
                  key={item.id}
                  onClick={() => selectItem(item)}
                  className={`flex items-center p-2 rounded-lg transition-all cursor-pointer ${selectedItemId === item.id ? 'bg-blue-100 ring-2 ring-blue-500' : 'hover:bg-white'}`}
                >
                  <div className="flex-1">
                    <p className="font-semibold text-sm text-slate-800 line-clamp-1">{item.name}</p>
                    <p className="text-xs text-slate-500">${item.price.toFixed(2)}</p>
                  </div>
                  <div className="flex items-center gap-2">
                    <button onClick={(e) => { e.stopPropagation(); updateQuantity(item.id, item.quantity - 1); }} className="p-1.5 bg-slate-200 rounded-md"><Minus size={14} /></button>
                    <span className="font-bold text-base w-6 text-center">{item.quantity}</span>
                    <button onClick={(e) => { e.stopPropagation(); updateQuantity(item.id, item.quantity + 1); }} className="p-1.5 bg-slate-200 rounded-md"><Plus size={14} /></button>
                  </div>
                  <button onClick={(e) => { e.stopPropagation(); removeFromCart(item.id); }} className="ml-2 text-rose-500/70 hover:text-rose-500 p-1"><Trash2 size={16} /></button>
                </div>
              ))
            )}
          </div>

          {cart.length > 0 && <div className="p-2 bg-slate-100/70 border-y border-slate-200">
            {selectedItemId && <Numpad onInput={handleNumpadInput} onDelete={handleNumpadDelete} onClear={handleNumpadClear} />}
          </div>}

          <div className="p-3 bg-white/80 backdrop-blur-sm border-t-2 border-slate-200 space-y-3">
            <div className="flex justify-between items-center text-xl font-bold text-slate-800">
              <span>TOTAL</span>
              <span>${total.toFixed(2)}</span>
            </div>
            <div className="grid grid-cols-2 gap-3">
              <button onClick={() => handlePayment('cash')} disabled={cart.length === 0} className="bg-slate-800 text-white py-3 rounded-lg text-sm font-bold flex items-center justify-center gap-2 disabled:bg-slate-400">
                <Banknote size={18}/> Efectivo
              </button>
              <button onClick={() => handlePayment('card')} disabled={cart.length === 0} className="bg-blue-600 text-white py-3 rounded-lg text-sm font-bold flex items-center justify-center gap-2 disabled:bg-blue-300">
                <CreditCard size={18}/> Tarjeta
              </button>
            </div>
          </div>
        </div>
      </div>

      {showScanner && (
        <div className="fixed inset-0 bg-black/80 z-50 flex flex-col items-center justify-center animate-in fade-in">
          <video ref={videoRef} autoPlay className="w-full max-w-md h-auto" />
          <button onClick={simulateScan} className="mt-4 bg-slate-700 text-white px-4 py-2 rounded-lg">Simular Escaneo</button>
          <button onClick={() => setShowScanner(false)} className="absolute top-4 right-4 p-2 bg-white/20 rounded-full text-white"><X size={24} /></button>
        </div>
      )}

      {showSuccessModal && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-sm z-[100] flex items-center justify-center animate-in fade-in">
          <div className="bg-white rounded-2xl p-8 text-center flex flex-col items-center gap-3 shadow-xl animate-in zoom-in-95">
            <div className="w-20 h-20 bg-emerald-100 text-emerald-500 rounded-full flex items-center justify-center">
              <CheckCircle size={48} strokeWidth={2} />
            </div>
            <h2 className="text-2xl font-bold text-slate-800">¡Venta Completada!</h2>
            <p className="text-slate-500 text-sm">El recibo se ha generado y guardado.</p>
          </div>
        </div>
      )}
    </div>
  );
};

export default POS;
