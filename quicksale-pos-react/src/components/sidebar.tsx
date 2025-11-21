import React from 'react';
import { LayoutDashboard, ShoppingCart, Package, MessageSquare } from 'lucide-react';

interface SidebarProps {
  currentView: string;
  onNavigate: (view: string) => void;
}

const Sidebar: React.FC<SidebarProps> = ({ currentView, onNavigate }) => {
  const menuItems = [
    { id: 'pos', label: 'CAJA', icon: ShoppingCart },
    { id: 'inventory', label: 'ALMACÉN', icon: Package },
    { id: 'dashboard', label: 'REPORTES', icon: LayoutDashboard },
  ];

  return (
    <>
      {/* Desktop Sidebar - Professional Dark Theme */}
      <div className="hidden md:flex w-24 lg:w-72 bg-slate-900 border-r border-slate-800 h-screen flex-col sticky top-0 z-50">
        <div className="p-6 flex items-center justify-center lg:justify-start border-b border-slate-800">
          <div className="bg-emerald-500 text-white p-3 rounded-xl shadow-lg shadow-emerald-900/20">
            <ShoppingCart size={28} strokeWidth={2.5} />
          </div>
          <div className="hidden lg:block ml-4">
            <span className="text-2xl font-black text-white block tracking-tight">QuickSale</span>
            <span className="text-xs text-slate-400 font-medium tracking-widest uppercase">Punto de Venta</span>
          </div>
        </div>

        <nav className="flex-1 p-4 space-y-2">
          {menuItems.map(item => (
            <button
              key={item.id}
              onClick={() => onNavigate(item.id)}
              className={`w-full flex items-center justify-center lg:justify-start gap-4 p-4 rounded-xl font-bold text-lg transition-colors ${
                currentView === item.id
                  ? 'bg-emerald-500 text-white shadow-md'
                  : 'text-slate-400 hover:bg-slate-800 hover:text-white'
              }`}
            >
              <item.icon size={28} strokeWidth={2.5} />
              <span className="hidden lg:block">{item.label}</span>
            </button>
          ))}
        </nav>
      </div>

      {/* Mobile Bottom Bar */}
      <div className="md:hidden fixed bottom-0 left-0 right-0 bg-slate-900 border-t border-slate-800 flex justify-around pb-safe z-50">
        {menuItems.map(item => (
          <button
            key={item.id}
            onClick={() => onNavigate(item.id)}
            className={`flex flex-col items-center justify-center gap-1 p-3 flex-1 transition-colors ${
              currentView === item.id ? 'text-emerald-400' : 'text-slate-400'
            }`}
          >
            <item.icon size={24} />
            <span className="text-xs font-bold">{item.label}</span>
          </button>
        ))}
      </div>
    </>
  );
};

export default Sidebar;
