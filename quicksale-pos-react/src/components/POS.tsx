import React, { useState, useEffect, useRef } from 'react';
import { Product, CartItem, Sale } from '../types';
import { saveSale } from '../services/storageService';
import { Search, ShoppingCart, Trash2, Plus, Minus, CreditCard, Banknote, ScanBarcode, ArrowLeft, ChevronUp, X, CheckCircle, AlertTriangle } from 'lucide-react';
import { jsPDF } from 'jspdf';

interface POSProps {
  products: Product[];
  refreshData: () => void;
}

// Componente de Teclado Numérico Grande
const Numpad = ({ onNumber, onDelete, onClear }: { onNumber: (n: number) => void, onDelete: () => void, onClear: () => void }) => (
  <div className="grid grid-cols-3 gap-2 h-full">
    {[1, 2, 3, 4, 5, 6, 7, 8, 9].map(num => (
      <button key={num} onClick={() => onNumber(num)} className="bg-slate-100 hover:bg-slate-200 text-slate-800 font-bold text-2xl rounded-xl p-4 active:scale-95 transition-transform shadow-sm border-b-4 border-slate-200 active:border-b-0 active:mt-1">
        {num}
      </button>
    ))}
    <button onClick={onClear} className="bg-rose-100 text-rose-600 font-bold text-lg rounded-xl p-4 active:scale-95 transition-transform uppercase tracking-wide">C</button>
    <button onClick={() => onNumber(0)} className="bg-slate-100 hover:bg-slate-200 text-slate-800 font-bold text-2xl rounded-xl p-4 active:scale-95 transition-transform border-b-4 border-slate-200 active:border-b-0 active:mt-1">0</button>
    <button onClick={onDelete} className="bg-orange-100 text-orange-600 font-bold rounded-xl p-4 active:scale-95 transition-transform flex items-center justify-center">
      <ArrowLeft size={24} strokeWidth={3} />
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

  const videoRef = useRef<HTMLVideoElement>(null);

  // Cierra el modal de éxito automáticamente
  useEffect(() => {
    if (showSuccessModal) {
      const timer = setTimeout(() => setShowSuccessModal(false), 2500);
      return () => clearTimeout(timer);
    }
  }, [showSuccessModal]);

  const addToCart = (product: Product) => {
    if (product.stock <= 0) return;

    setCart(prev => {
      const existingItem = prev.find(item => item.id === product.id);
      if (existingItem) {
        return prev.map(item =>
          item.id === product.id
            ? { ...item, quantity: Math.min(item.quantity + 1, product.stock) }
            : item
        );
      }
      return [...prev, { ...product, quantity: 1 }];
    });
    setSearch('');
  };

  const updateQuantity = (id: string, newQty: number) => {
    if (newQty <= 0) {
      removeFromCart(id);
      return;
    }
    setCart(prev =>
      prev.map(item => {
        if (item.id === id) {
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

  const handleNumpadInput = (num: number) => {
    if (!selectedItemId) return;
    const item = cart.find(i => i.id === selectedItemId);
    if (!item) return;

    const newQty = parseInt(item.quantity.toString() + num.toString());
    updateQuantity(selectedItemId, newQty);
  };

  const handleNumpadDelete = () => {
    if (!selectedItemId) return;
    const item = cart.find(i => i.id === selectedItemId);
    if (!item) return;
    const qtyStr = item.quantity.toString();
    if (qtyStr.length <= 1) {
      updateQuantity(selectedItemId, 1);
    } else {
      updateQuantity(selectedItemId, parseInt(qtyStr.slice(0, -1)));
    }
  };

  const total = cart.reduce((sum, item) => sum + (item.price * item.quantity), 0);

  const handlePayment = async (method: 'cash' | 'card') => {
    if (cart.length === 0) return;

    const newSale: Sale = {
      id: Date.now().toString(),
      date: new Date().toISOString(),
      total,
      items: cart,
      paymentMethod: method,
    };

    saveSale(newSale);
    generateReceipt(newSale);
    setCart([]);
    setSelectedItemId(null);
    setShowMobileCart(false);
    refreshData();
    setShowSuccessModal(true);
  };

  const generateReceipt = (sale: Sale) => {
    // Generación silenciosa de PDF (idealmente imprimiría térmicamente)
    const doc = new jsPDF({
      orientation: 'portrait',
      unit: 'mm',
      format: [80, 150] // Formato ticket 80mm
    });
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

  // Camera logic
  useEffect(() => {
    if (showScanner && videoRef.current) {
      navigator.mediaDevices.getUserMedia({ video: { facingMode: 'environment' } })
        .then(stream => {
          if (videoRef.current) videoRef.current.srcObject = stream;
        })
        .catch(err => console.error(err));
    }
  }, [showScanner]);

  const simulateScan = () => {
    if (products.length > 0) {
      const randomProduct = products[Math.floor(Math.random() * products.length)];
      addToCart(randomProduct);
      setShowScanner(false);
    }
  };

  const filteredProducts = products.filter(p =>
    p.name.toLowerCase().includes(search.toLowerCase()) ||
    p.barcode.includes(search)
  );

  return (
    <div className="h-full flex flex-col md:flex-row overflow-hidden bg-slate-100 relative">
      {/* Product Grid & Search */}
      <div className="flex-1 flex flex-col p-4 md:p-6 overflow-hidden">
        <div className="flex gap-4 mb-6">
          <div className="relative flex-1">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" size={20} />
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Buscar producto o escanear código..."
              className="w-full bg-white border border-slate-200 rounded-xl pl-12 pr-4 py-4 text-lg"
            />
          </div>
          <button onClick={() => setShowScanner(true)} className="p-4 bg-white border border-slate-200 rounded-xl text-slate-600 hover:bg-slate-50">
            <ScanBarcode size={28} />
          </button>
        </div>
        <div className="flex-1 overflow-y-auto -m-2 p-2">
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-4">
            {filteredProducts.map(p => (
              <button
                key={p.id}
                onClick={() => addToCart(p)}
                disabled={p.stock <= 0}
                className="bg-white rounded-xl shadow-sm border border-slate-200 p-3 text-center flex flex-col justify-between items-center active:scale-95 transition-transform disabled:opacity-50"
              >
                <div className="w-full h-20 bg-slate-100 rounded-lg mb-2 flex items-center justify-center">
                  {p.imageUrl ? <img src={p.imageUrl} alt={p.name} className="w-full h-full object-cover rounded-lg" /> : <Package size={32} className="text-slate-400" />}
                </div>
                <span className="font-bold text-sm text-slate-800 leading-tight">{p.name}</span>
                <span className="font-black text-lg text-slate-900">${p.price.toFixed(2)}</span>
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Cart Section */}
      <div className={`fixed md:static bottom-0 left-0 right-0 md:w-[420px] lg:w-[480px] bg-white border-l border-slate-200 flex flex-col transition-transform duration-300 ease-in-out ${showMobileCart ? 'translate-y-0' : 'translate-y-full md:translate-y-0'}`}>
        {/* Mobile Cart Handle */}
        <div className="md:hidden p-4 bg-white border-b border-slate-200 text-center" onClick={() => setShowMobileCart(!showMobileCart)}>
          <ChevronUp className={`mx-auto transition-transform ${showMobileCart ? 'rotate-180' : ''}`} />
          <span className="font-bold text-lg">Ver Carrito ({cart.length}) - Total: ${total.toFixed(2)}</span>
        </div>

        <div className="flex-1 flex flex-col overflow-hidden">
          <div className="p-6 flex justify-between items-center border-b border-slate-200">
            <h2 className="text-2xl font-black text-slate-800 flex items-center gap-3"><ShoppingCart /> Carrito</h2>
            <button onClick={() => setCart([])} className="text-sm text-slate-500 hover:text-red-500">Vaciar</button>
          </div>

          <div className="flex-1 overflow-y-auto p-4 space-y-3">
            {cart.length === 0 ? (
              <p className="text-center text-slate-500 py-10">El carrito está vacío</p>
            ) : (
              cart.map(item => (
                <div
                  key={item.id}
                  onClick={() => setSelectedItemId(item.id)}
                  className={`flex items-center p-3 rounded-xl transition-all ${selectedItemId === item.id ? 'bg-blue-100 ring-2 ring-blue-500' : 'bg-slate-50'}`}
                >
                  <div className="flex-1">
                    <p className="font-bold text-slate-800">{item.name}</p>
                    <p className="text-sm text-slate-500">${item.price.toFixed(2)}</p>
                  </div>
                  <div className="flex items-center gap-3">
                    <button onClick={() => updateQuantity(item.id, item.quantity - 1)} className="p-2 bg-slate-200 rounded-full"><Minus size={16} /></button>
                    <span className="font-bold text-lg w-8 text-center">{item.quantity}</span>
                    <button onClick={() => updateQuantity(item.id, item.quantity + 1)} className="p-2 bg-slate-200 rounded-full"><Plus size={16} /></button>
                  </div>
                  <button onClick={() => removeFromCart(item.id)} className="ml-4 text-red-500"><Trash2 size={20} /></button>
                </div>
              ))
            )}
          </div>

          {/* Numpad for selected item */}
          {selectedItemId && (
            <div className="p-4 bg-slate-50 border-t border-slate-200">
              <h3 className="text-center font-bold mb-2">Cantidad para: {cart.find(i => i.id === selectedItemId)?.name}</h3>
              <Numpad
                onNumber={handleNumpadInput}
                onDelete={handleNumpadDelete}
                onClear={() => updateQuantity(selectedItemId, 1)}
              />
            </div>
          )}

          {/* Payment Section */}
          <div className="p-4 bg-white border-t-2 border-slate-200 space-y-4">
            <div className="flex justify-between items-center text-2xl font-black text-slate-800">
              <span>TOTAL</span>
              <span>${total.toFixed(2)}</span>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <button onClick={() => handlePayment('cash')} disabled={cart.length === 0} className="bg-emerald-500 text-white py-4 rounded-2xl text-lg font-bold flex items-center justify-center gap-2 disabled:bg-emerald-300">
                <Banknote /> Efectivo
              </button>
              <button onClick={() => handlePayment('card')} disabled={cart.length === 0} className="bg-blue-500 text-white py-4 rounded-2xl text-lg font-bold flex items-center justify-center gap-2 disabled:bg-blue-300">
                <CreditCard /> Tarjeta
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Scanner Modal */}
      {showScanner && (
        <div className="fixed inset-0 bg-black/80 z-50 flex flex-col items-center justify-center animate-in fade-in">
          <video ref={videoRef} autoPlay className="w-full max-w-md h-auto" />
          <button onClick={simulateScan} className="mt-4 bg-slate-700 text-white px-4 py-2 rounded-lg">Simular Escaneo</button>
          <button onClick={() => setShowScanner(false)} className="absolute top-4 right-4 p-2 bg-white/20 rounded-full text-white">
            <X size={24} />
          </button>
        </div>
      )}

      {/* Success Modal */}
      {showSuccessModal && (
        <div className="fixed inset-0 bg-black/50 z-[100] flex items-center justify-center animate-in fade-in">
          <div className="bg-white rounded-3xl p-8 text-center flex flex-col items-center gap-4 shadow-2xl animate-in zoom-in-95">
            <div className="w-24 h-24 bg-emerald-100 text-emerald-500 rounded-full flex items-center justify-center">
              <CheckCircle size={60} strokeWidth={1.5} />
            </div>
            <h2 className="text-3xl font-black text-slate-800">¡Venta Completada!</h2>
            <p className="text-slate-500">El recibo se ha generado.</p>
          </div>
        </div>
      )}
    </div>
  );
};

export default POS;
