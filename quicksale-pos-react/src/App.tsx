import React, { useState, useEffect } from 'react';
import Sidebar from './components/Sidebar';
import Dashboard from './components/Dashboard';
import Inventory from './components/Inventory';
import POS from './components/POS';
import { getProducts, getSales } from './services/storageService';
import { Product, Sale } from './types';

const App: React.FC = () => {
  const [currentView, setCurrentView] = useState('pos');
  const [products, setProducts] = useState<Product[]>([]);
  const [sales, setSales] = useState<Sale[]>([]);

  const refreshData = () => {
    setProducts(getProducts());
    setSales(getSales());
  };

  useEffect(() => {
    refreshData();
  }, []);

  const renderView = () => {
    switch (currentView) {
      case 'dashboard':
        return <Dashboard sales={sales} />;
      case 'inventory':
        return <Inventory products={products} refreshProducts={refreshData} />;
      case 'pos':
        return <POS products={products} refreshData={refreshData} />;
      default:
        return <POS products={products} refreshData={refreshData} />;
    }
  };

  return (
    <div className="flex flex-col md:flex-row h-screen bg-[#f8fafc] overflow-hidden">
      <Sidebar currentView={currentView} onNavigate={setCurrentView} />
      <main className="flex-1 overflow-y-auto overflow-x-hidden no-scrollbar pb-20 md:pb-0 relative w-full">
        {renderView()}
      </main>
    </div>
  );
};

export default App;
